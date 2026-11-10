// category_tabs_backend.js — home category tabs (Node + Express + PostgreSQL)
//   npm i express pg multer sharp
//   app.use('/uploads', express.static('uploads'));
//   app.use('/api', auth, require('./category_tabs_backend'));   // auth sets req.user = { id, isAdmin } (GET works for guests)

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

router.get('/category-tabs', wrap(async (req, res) => {
  if (cache && Date.now() - cacheAt < 60_000) return res.json(cache);
  const { rows } = await pool.query('SELECT * FROM category_tabs WHERE enabled ORDER BY sort, id');
  const others = rows.filter(r => r.slug !== 'all' && r.image).slice(0, 4).map(r => abs(r.image));
  cache = { tabs: rows.map(r => ({ id: String(r.id), slug: r.slug, label: r.label, image: abs(r.image), badge: r.badge || '', allImages: r.slug === 'all' ? others : [] })) };
  cacheAt = Date.now();
  res.json(cache);
}));

const admin = (req, res, next) => (req.user?.isAdmin ? next() : res.status(403).json({ error: 'Admins only' }));
function check(b, isNew) {
  const o = {};
  if (b.label != null) { const l = String(b.label).trim(); if (!l || l.length > 14) throw bad('Name is required, max 14 letters'); o.label = l; }
  if (b.slug != null) { const s = String(b.slug).trim().toLowerCase().replace(/[^a-z0-9-]/g, '-'); if (!s) throw bad('Slug is required'); o.slug = s; }
  if (b.image != null) o.image = String(b.image);
  if (b.badge != null) o.badge = String(b.badge).trim().slice(0, 6);
  if (b.enabled != null) o.enabled = !!b.enabled;
  if (isNew && (!o.label || !o.slug)) throw bad('Name and slug are required');
  return o;
}
router.get('/admin/category-tabs', admin, wrap(async (req, res) => {
  const { rows } = await pool.query('SELECT * FROM category_tabs ORDER BY sort, id');
  res.json(rows.map(r => ({ ...r, url: abs(r.image) })));
}));
router.post('/admin/category-tabs', admin, wrap(async (req, res) => {
  const o = check(req.body, true), k = Object.keys(o);
  try {
    const { rows: [r] } = await pool.query(`INSERT INTO category_tabs (${k.concat('sort')}) VALUES (${k.map((_, i) => '$' + (i + 1)).concat('(SELECT COALESCE(MAX(sort),0)+1 FROM category_tabs)')}) RETURNING *`, k.map(x => o[x]));
    clear(); res.json(r);
  } catch (e) { if (e.code === '23505') throw bad('This slug already exists'); throw e; }
}));
router.put('/admin/category-tabs/:id', admin, wrap(async (req, res) => {
  const o = check(req.body, false), k = Object.keys(o);
  if (!k.length) throw bad('Nothing to update');
  try { await pool.query(`UPDATE category_tabs SET ${k.map((x, i) => `${x}=$${i + 1}`)} WHERE id=$${k.length + 1}`, [...k.map(x => o[x]), req.params.id]); }
  catch (e) { if (e.code === '23505') throw bad('This slug already exists'); throw e; }
  clear(); res.json({ ok: true });
}));
router.delete('/admin/category-tabs/:id', admin, wrap(async (req, res) => {
  await pool.query('DELETE FROM category_tabs WHERE id=$1', [req.params.id]); clear(); res.json({ ok: true });
}));
router.put('/admin/category-tabs/order', admin, wrap(async (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  for (let i = 0; i < ids.length; i++) await pool.query('UPDATE category_tabs SET sort=$1 WHERE id=$2', [i + 1, ids[i]]);
  clear(); res.json({ ok: true });
}));
fs.mkdirSync('uploads', { recursive: true });
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 6 * 1024 * 1024 }, fileFilter: (_, f, cb) => cb(null, /^image\/(png|jpe?g|webp)$/.test(f.mimetype)) });
router.post('/admin/category-tabs/upload', admin, upload.single('image'), wrap(async (req, res) => {
  if (!req.file) throw bad('Send a PNG/JPG/WebP in the "image" field');
  const buf = await sharp(req.file.buffer).rotate().resize(300, 300, { fit: 'inside', withoutEnlargement: true }).png().toBuffer();
  const name = `cat_${crypto.randomBytes(8).toString('hex')}.png`;
  fs.writeFileSync(path.join('uploads', name), buf);
  res.json({ ok: true, path: `/uploads/${name}`, url: abs(`/uploads/${name}`) });
}));

module.exports = router;
