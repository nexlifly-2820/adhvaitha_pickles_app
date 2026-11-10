# Admin Dashboard Backend Guide for Pickles Showcase Section

This guide provides the complete Node.js / Express backend code (`pickle_showcase_backend.js`) and database schema for managing the home screen **Pickles Showcase** section from your admin dashboard.

---

## 1. Database Schema

Run these SQL queries in your PostgreSQL database to set up the necessary tables and default items:

```sql
CREATE TABLE IF NOT EXISTS showcase_sections (
  key TEXT PRIMARY KEY,
  enabled BOOLEAN DEFAULT TRUE,
  eyebrow TEXT DEFAULT 'PICKLES · HAND-MIXED',
  view_all_text TEXT DEFAULT 'View all →'
);
INSERT INTO showcase_sections (key) VALUES ('pickles') ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS showcase_items (
  id SERIAL PRIMARY KEY,
  section_key TEXT NOT NULL REFERENCES showcase_sections(key) ON DELETE CASCADE,
  product_id TEXT DEFAULT '',          -- linked product ID (Add to cart / open product)
  name TEXT NOT NULL,                  -- e.g. Avakaya
  badge TEXT DEFAULT '',               -- e.g. BESTSELLER
  description TEXT DEFAULT '',         -- e.g. Raw mango, Guntur chilli, mustard & gingelly oil
  cure_text TEXT DEFAULT '',           -- e.g. ☀️ 21 days sun-cured
  thumb TEXT DEFAULT '',               -- round photo URL
  shots JSONB DEFAULT '[]',            -- [{ "image": "/uploads/x.jpg", "caption": "Rich in gingelly oil", "ms": 2100 }]
  variants JSONB DEFAULT '[]',         -- [{ "id": "", "label": "250 g", "price": 249, "mrp": 299 }]
  enabled BOOLEAN DEFAULT TRUE,
  sort INT DEFAULT 0
);

INSERT INTO showcase_items (section_key, name, badge, description, cure_text, variants, sort) VALUES
 ('pickles', 'Avakaya', 'BESTSELLER', 'Raw mango, Guntur chilli, mustard & gingelly oil', '☀️ 21 days sun-cured', '[{"label":"250 g","price":249,"mrp":299},{"label":"500 g","price":459,"mrp":549},{"label":"1 kg","price":879,"mrp":1049}]', 1),
 ('pickles', 'Nimmakaya', 'TANGY CLASSIC', 'Juicy lemons, chilli & fenugreek, aged till soft', '☀️ 30 days aged', '[{"label":"250 g","price":199,"mrp":239},{"label":"500 g","price":369,"mrp":439},{"label":"1 kg","price":699,"mrp":839}]', 2)
ON CONFLICT DO NOTHING;
```

---

## 2. Backend Router (`pickle_showcase_backend.js`)

Save this file as `pickle_showcase_backend.js` in your Node.js server project:

```javascript
// pickle_showcase_backend.js — data for the home "Pickles showcase" section (Node + Express + PostgreSQL)
const express = require('express');
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const multer = require('multer');
const sharp = require('sharp');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const router = express.Router();
const wrap = fn => (req, res, next) => fn(req, res).catch(next);
const PUBLIC = (process.env.PUBLIC_URL || '').replace(/\/$/, '');
const abs = u => (!u ? '' : /^https?:\/\//.test(u) ? u : PUBLIC + (u.startsWith('/') ? u : '/' + u));
const bad = msg => Object.assign(new Error(msg), { status: 400 });
const cache = new Map();
const clear = () => cache.clear();

router.get('/showcase/:key', wrap(async (req, res) => {
  const key = req.params.key;
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < 60_000) return res.json(hit.data);
  const { rows: [s] } = await pool.query('SELECT * FROM showcase_sections WHERE key=$1', [key]);
  if (!s) return res.status(404).json({ error: 'Unknown section' });
  const { rows } = await pool.query('SELECT * FROM showcase_items WHERE section_key=$1 AND enabled ORDER BY sort, id', [key]);
  const items = rows
    .map(r => ({
      id: String(r.id), productId: r.product_id || '', name: r.name, badge: r.badge, description: r.description, cureText: r.cure_text,
      thumb: abs(r.thumb),
      shots: (r.shots || []).filter(x => x && x.image).map(x => ({ image: abs(x.image), caption: x.caption || '', ms: Number(x.ms) || 2100 })),
      variants: (r.variants || []).filter(v => v && v.label).map(v => ({ id: v.id || '', label: v.label, price: Number(v.price) || 0, mrp: Number(v.mrp) || 0 })),
    }))
    .filter(i => i.shots.length && i.variants.length);
  const data = { settings: { enabled: s.enabled, eyebrow: s.eyebrow, viewAllText: s.view_all_text }, items };
  cache.set(key, { at: Date.now(), data });
  res.json(data);
}));

// ---------------- ADMIN ----------------
const admin = (req, res, next) => (req.user?.isAdmin ? next() : res.status(403).json({ error: 'Admins only' }));

router.get('/admin/showcase/:key/settings', admin, wrap(async (req, res) => {
  await pool.query('INSERT INTO showcase_sections (key) VALUES ($1) ON CONFLICT DO NOTHING', [req.params.key]);
  res.json((await pool.query('SELECT * FROM showcase_sections WHERE key=$1', [req.params.key])).rows[0]);
}));
router.put('/admin/showcase/:key/settings', admin, wrap(async (req, res) => {
  const b = req.body;
  await pool.query(
    `INSERT INTO showcase_sections (key, enabled, eyebrow, view_all_text) VALUES ($1, COALESCE($2,TRUE), COALESCE($3,'PICKLES · HAND-MIXED'), COALESCE($4,'View all →'))
     ON CONFLICT (key) DO UPDATE SET enabled=COALESCE($2,showcase_sections.enabled), eyebrow=COALESCE($3,showcase_sections.eyebrow), view_all_text=COALESCE($4,showcase_sections.view_all_text)`,
    [req.params.key, b.enabled ?? null, b.eyebrow ?? null, b.viewAllText ?? null]);
  clear();
  res.json({ ok: true });
}));

router.get('/admin/showcase/:key/items', admin, wrap(async (req, res) =>
  res.json((await pool.query('SELECT * FROM showcase_items WHERE section_key=$1 ORDER BY sort, id', [req.params.key])).rows)));

const MAP = { productId: 'product_id', name: 'name', badge: 'badge', description: 'description', cureText: 'cure_text', thumb: 'thumb', shots: 'shots', variants: 'variants', enabled: 'enabled', sort: 'sort' };
function check(b) {
  if (b.name != null && (!String(b.name).trim() || String(b.name).length > 16)) throw bad('Name is required, max 16 letters');
  if (b.badge != null && String(b.badge).length > 22) throw bad('Badge max 22 letters');
  if (b.description != null && String(b.description).length > 70) throw bad('Description max 70 letters (2 lines)');
  if (b.cureText != null && String(b.cureText).length > 30) throw bad('Cure tag max 30 letters');
  if (b.shots != null) {
    if (!Array.isArray(b.shots) || b.shots.length > 6) throw bad('Up to 6 photos per pickle');
    b.shots = b.shots.map(x => ({ image: String(x.image || ''), caption: String(x.caption || '').slice(0, 32), ms: Math.min(5000, Math.max(1200, Number(x.ms) || 2100)) }));
    b.shots = JSON.stringify(b.shots);
  }
  if (b.variants != null) {
    if (!Array.isArray(b.variants) || !b.variants.length || b.variants.length > 4) throw bad('Add 1 to 4 weights');
    b.variants = b.variants.map(v => {
      const price = Number(v.price), mrp = Number(v.mrp) || 0;
      if (!String(v.label || '').trim() || !(price > 0)) throw bad('Every weight needs a label (e.g. 250 g) and a price');
      return { id: String(v.id || ''), label: String(v.label).trim().slice(0, 8), price, mrp };
    });
    b.variants = JSON.stringify(b.variants);
  }
}

router.post('/admin/showcase/:key/items', admin, wrap(async (req, res) => {
  const b = req.body;
  if (!b.name) throw bad('Name is required');
  if (!b.variants) b.variants = [{ label: '250 g', price: 199, mrp: 0 }];
  check(b);
  const keys = Object.keys(MAP).filter(k => k in b);
  const { rows: [r] } = await pool.query(
    `INSERT INTO showcase_items (section_key, ${keys.map(k => MAP[k])}) VALUES ($1, ${keys.map((_, i) => `$${i + 2}`)}) RETURNING *`,
    [req.params.key, ...keys.map(k => b[k])]);
  clear();
  res.json(r);
}));

router.put('/admin/showcase-items/:id', admin, wrap(async (req, res) => {
  const b = req.body; check(b);
  const keys = Object.keys(MAP).filter(k => k in b);
  if (!keys.length) throw bad('nothing to update');
  const { rowCount } = await pool.query(`UPDATE showcase_items SET ${keys.map((k, i) => `${MAP[k]}=$${i + 1}`)} WHERE id=$${keys.length + 1}`, [...keys.map(k => b[k]), req.params.id]);
  if (!rowCount) return res.status(404).json({ error: 'Not found' });
  clear();
  res.json({ ok: true });
}));

router.delete('/admin/showcase-items/:id', admin, wrap(async (req, res) => {
  await pool.query('DELETE FROM showcase_items WHERE id=$1', [req.params.id]);
  clear();
  res.json({ ok: true });
}));

router.put('/admin/showcase/:key/order', admin, wrap(async (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  for (let i = 0; i < ids.length; i++) await pool.query('UPDATE showcase_items SET sort=$1 WHERE id=$2 AND section_key=$3', [i + 1, ids[i], req.params.key]);
  clear();
  res.json({ ok: true });
}));

fs.mkdirSync('uploads', { recursive: true });
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_, f, cb) => cb(null, /^image\/(png|jpe?g|webp)$/.test(f.mimetype)) });
router.post('/admin/showcase-upload', admin, upload.single('image'), wrap(async (req, res) => {
  if (!req.file) throw bad('Send a JPG/PNG/WebP photo in the "image" field');
  const thumb = req.query.kind === 'thumb';
  const img = sharp(req.file.buffer).rotate();
  const buf = thumb
    ? await img.resize(320, 320, { fit: 'cover' }).jpeg({ quality: 85 }).toBuffer()
    : await img.resize(1080, 830, { fit: 'cover', withoutEnlargement: true }).jpeg({ quality: 84 }).toBuffer();
  const name = `sc_${crypto.randomBytes(8).toString('hex')}.jpg`;
  fs.writeFileSync(path.join('uploads', name), buf);
  res.json({ ok: true, path: `/uploads/${name}`, url: abs(`/uploads/${name}`) });
}));

router.use((e, req, res, next) => {
  if (e instanceof multer.MulterError) return res.status(400).json({ error: e.message });
  if (e.status === 400) return res.status(400).json({ error: e.message });
  console.error(e);
  res.status(500).json({ error: 'Something went wrong' });
});
module.exports = router;
```
