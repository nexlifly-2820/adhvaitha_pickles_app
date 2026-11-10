// pairing_backend.js — "The Art of Pairing" (home card + full couples page) — Node + Express + PostgreSQL
//   npm i express pg multer sharp
//   app.use(express.json());
//   app.use('/uploads', express.static('uploads'));
//   app.use('/api', auth, require('./pairing_backend'));     // auth sets req.user = { id, isAdmin } (GET works for guests)

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
let cache = null, cacheAt = 0;
const clear = () => { cache = null; };

const side = x => ({
  productId: String((x && x.productId) || ''), name: String((x && x.name) || ''), bio: String((x && x.bio) || ''),
  image: abs((x && x.image) || ''), tags: Array.isArray(x && x.tags) ? x.tags.slice(0, 2).map(String) : [],
});

router.get('/pairing', wrap(async (req, res) => {
  if (cache && Date.now() - cacheAt < 60_000) return res.json(cache);
  const { rows: [s] } = await pool.query('SELECT * FROM pairing_settings WHERE id=1');
  const { rows } = await pool.query('SELECT * FROM pairing_couples WHERE enabled ORDER BY sort, id');
  const couples = rows.map(r => ({
    id: String(r.id), name: r.name, tag: r.tag || '', mealIcon: r.meal_icon || '', mealName: r.meal_name || '', lovedText: r.loved_text || '', tip: r.tip || '',
    a: side(r.a), b: side(r.b),
    weights: (r.weights || []).filter(w => w && w.label && Number(w.price) > 0).map(w => ({
      label: String(w.label), price: Number(w.price), mrp: Number(w.mrp) || 0, aVariantId: String(w.aVariantId || ''), bVariantId: String(w.bVariantId || ''),
    })),
  })).filter(c => c.a.image && c.b.image && c.weights.length);
  const t = s || {};
  cache = {
    settings: { enabled: t.enabled !== false, eyebrow: t.eyebrow || 'CURATED COMBOS', title: t.title || 'The Art of', titleAccent: t.title_accent || 'Pairing',
      subtitle: t.subtitle || '', explainText: t.explain_text || '', matchText: t.match_text || 'Made for each other', buttonText: t.button_text || "Meet Amma's perfect couples", moreText: t.more_text || 'MORE PERFECT COUPLES' },
    couples,
  };
  cacheAt = Date.now();
  res.json(cache);
}));

// ---------------- ADMIN ----------------
const admin = (req, res, next) => (req.user?.isAdmin ? next() : res.status(403).json({ error: 'Admins only' }));

router.get('/admin/pairing/settings', admin, wrap(async (req, res) => res.json((await pool.query('SELECT * FROM pairing_settings WHERE id=1')).rows[0])));
router.put('/admin/pairing/settings', admin, wrap(async (req, res) => {
  const b = req.body;
  await pool.query(`UPDATE pairing_settings SET enabled=COALESCE($1,enabled), eyebrow=COALESCE($2,eyebrow), title=COALESCE($3,title), title_accent=COALESCE($4,title_accent),
    subtitle=COALESCE($5,subtitle), match_text=COALESCE($6,match_text), button_text=COALESCE($7,button_text), more_text=COALESCE($8,more_text), explain_text=COALESCE($9,explain_text) WHERE id=1`,
    [b.enabled ?? null, b.eyebrow ?? null, b.title ?? null, b.titleAccent ?? null, b.subtitle ?? null, b.matchText ?? null, b.buttonText ?? null, b.moreText ?? null, b.explainText ?? null]);
  clear();
  res.json({ ok: true });
}));

router.get('/admin/pairing/couples', admin, wrap(async (req, res) => res.json((await pool.query('SELECT * FROM pairing_couples ORDER BY sort, id')).rows)));

function cleanSide(x) {
  x = x || {};
  if (!String(x.name || '').trim()) throw bad('Both products need a name');
  if (String(x.name).length > 16) throw bad('Product name max 16 letters');
  if (String(x.bio || '').length > 45) throw bad('Bio max 45 letters');
  return JSON.stringify({ productId: String(x.productId || ''), name: String(x.name).trim(), bio: String(x.bio || ''), image: String(x.image || ''),
    tags: (Array.isArray(x.tags) ? x.tags : []).map(t => String(t).trim().toUpperCase().slice(0, 10)).filter(Boolean).slice(0, 2) });
}
function check(b) {
  const out = {};
  if (b.name != null) { if (!String(b.name).trim() || String(b.name).length > 26) throw bad('Couple name is required, max 26 letters'); out.name = String(b.name).trim(); }
  if (b.tag != null) out.tag = String(b.tag).toUpperCase().slice(0, 14);
  if (b.mealIcon != null) out.meal_icon = String(b.mealIcon).slice(0, 4);
  if (b.mealName != null) out.meal_name = String(b.mealName).toUpperCase().slice(0, 12);
  if (b.lovedText != null) out.loved_text = String(b.lovedText).slice(0, 32);
  if (b.tip != null) out.tip = String(b.tip).slice(0, 52);
  if (b.a != null) out.a = cleanSide(b.a);
  if (b.b != null) out.b = cleanSide(b.b);
  if (b.weights != null) {
    if (!Array.isArray(b.weights) || !b.weights.length || b.weights.length > 3) throw bad('Add 1 to 3 weights');
    out.weights = JSON.stringify(b.weights.map(w => {
      if (!String(w.label || '').trim() || !(Number(w.price) > 0)) throw bad('Every weight needs a label (e.g. 250 g each) and a price');
      return { label: String(w.label).trim().slice(0, 12), price: Number(w.price), mrp: Number(w.mrp) || 0, aVariantId: String(w.aVariantId || ''), bVariantId: String(w.bVariantId || '') };
    }));
  }
  if (b.enabled != null) out.enabled = !!b.enabled;
  return out;
}
router.post('/admin/pairing/couples', admin, wrap(async (req, res) => {
  const b = req.body;
  if (!b.name) throw bad('Couple name is required');
  const o = check({ a: { name: 'Product 1' }, b: { name: 'Product 2' }, weights: [{ label: '250 g each', price: 299, mrp: 0 }], ...b });
  const keys = Object.keys(o);
  const { rows: [r] } = await pool.query(
    `INSERT INTO pairing_couples (${keys.concat('sort')}) VALUES (${keys.map((_, i) => `$${i + 1}`).concat('(SELECT COALESCE(MAX(sort),0)+1 FROM pairing_couples)')}) RETURNING *`,
    keys.map(k => o[k]));
  clear();
  res.json(r);
}));
router.put('/admin/pairing/couples/:id', admin, wrap(async (req, res) => {
  const o = check(req.body);
  const keys = Object.keys(o);
  if (!keys.length) throw bad('Nothing to update');
  const { rowCount } = await pool.query(`UPDATE pairing_couples SET ${keys.map((k, i) => `${k}=$${i + 1}`)} WHERE id=$${keys.length + 1}`, [...keys.map(k => o[k]), req.params.id]);
  if (!rowCount) return res.status(404).json({ error: 'Not found' });
  clear();
  res.json({ ok: true });
}));
router.delete('/admin/pairing/couples/:id', admin, wrap(async (req, res) => {
  await pool.query('DELETE FROM pairing_couples WHERE id=$1', [req.params.id]);
  clear();
  res.json({ ok: true });
}));
router.put('/admin/pairing/order', admin, wrap(async (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  for (let i = 0; i < ids.length; i++) await pool.query('UPDATE pairing_couples SET sort=$1 WHERE id=$2', [i + 1, ids[i]]);
  clear();
  res.json({ ok: true });
}));

fs.mkdirSync('uploads', { recursive: true });
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_, f, cb) => cb(null, /^image\/(png|jpe?g|webp)$/.test(f.mimetype)) });
router.post('/admin/pairing/upload', admin, upload.single('image'), wrap(async (req, res) => {
  if (!req.file) throw bad('Send a PNG/JPG/WebP photo in the "image" field');
  const buf = await sharp(req.file.buffer).rotate().resize(600, 600, { fit: 'inside', withoutEnlargement: true }).png().toBuffer();
  const name = `pair_${crypto.randomBytes(8).toString('hex')}.png`;
  fs.writeFileSync(path.join('uploads', name), buf);
  res.json({ ok: true, path: `/uploads/${name}`, url: abs(`/uploads/${name}`) });
}));

module.exports = router;
