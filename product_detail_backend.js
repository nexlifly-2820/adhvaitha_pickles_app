// product_detail_backend.js — data for the product page (Node + Express + PostgreSQL)
//   npm i express pg multer sharp
//   app.use(express.json());
//   app.use('/api', auth, require('./product_detail_backend'));
//   app.use('/uploads', express.static('uploads'));
//
// APP
//   GET  /api/products/:id/detail          everything the page shows (also counts a view for "royal guests viewed today")
// ADMIN
//   PUT  /api/admin/products/:id/detail    texts & sections (see fields below)
//   POST /api/admin/products/:id/photos    multipart "photo" + caption → gallery photo; oil-glint spots are found automatically
//   PUT  /api/admin/products/:id/photos/:photoId   { caption, sort }      DELETE same path
//
// TABLES (run once)
/*
ALTER TABLE products ADD COLUMN IF NOT EXISTS category_label TEXT DEFAULT '';     -- PICKLES SPECIAL
ALTER TABLE products ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
ALTER TABLE products ADD COLUMN IF NOT EXISTS highlight TEXT DEFAULT '';          -- words shown in red inside the description
ALTER TABLE products ADD COLUMN IF NOT EXISTS features JSONB DEFAULT '["✅ Zero preservatives","☀️ Sun-dried","🏺 Traditional recipe"]';
ALTER TABLE products ADD COLUMN IF NOT EXISTS spice INT DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS video_url TEXT DEFAULT '';
ALTER TABLE products ADD COLUMN IF NOT EXISTS ingredients JSONB DEFAULT '[]';     -- [{"name":"Fresh ginger","image":"https://…png"}]
ALTER TABLE products ADD COLUMN IF NOT EXISTS journey JSONB DEFAULT '[
  {"icon":"📍","label":"Origin","title":"Guntur farms","text":"Sourced from the finest farms"},
  {"icon":"☀️","label":"Process","title":"Handmade & sun-dried","text":"Mixed with traditional spices"},
  {"icon":"🍳","label":"Prepared in","title":"Artisanal kitchen","text":"Small batches, care & hygiene"},
  {"icon":"🫙","label":"Storage","title":"Glass jars","text":"Food-grade, airtight"},
  {"icon":"⏳","label":"Shelf life","title":"12 months","text":"From packing date"}]';
ALTER TABLE products ADD COLUMN IF NOT EXISTS artisan JSONB;                      -- {"name","since","quote","photo"}
ALTER TABLE products ADD COLUMN IF NOT EXISTS recipes JSONB DEFAULT '[]';         -- [{"title","subtitle","image"}]
ALTER TABLE products ADD COLUMN IF NOT EXISTS brand_line TEXT DEFAULT 'Bringing Andhra''s authentic flavours to your home.';

CREATE TABLE IF NOT EXISTS product_photos (
  id SERIAL PRIMARY KEY, product_id INT NOT NULL, url TEXT NOT NULL, caption TEXT DEFAULT '',
  glints JSONB DEFAULT '[]', sort INT DEFAULT 0);
CREATE TABLE IF NOT EXISTS product_views (product_id INT, day DATE DEFAULT CURRENT_DATE, n INT DEFAULT 0, PRIMARY KEY (product_id, day));
*/
// Uses: products(id, name, category, rating, image_url, sold_count), product_variants(id, product_id, label, price, mrp, is_default, in_stock, sort),
//       product_reviews(product_id, stars, text, display_name, status, created_at) from reviews_backend.js, users(id, name).

const express = require('express');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');
const sharp = require('sharp');
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const router = express.Router();
const wrap = fn => (req, res, next) => fn(req, res).catch(next);
const PUBLIC = process.env.PUBLIC_URL || '';
const SPICE = ['', 'Mild', 'Medium', 'Hot', 'Hot', 'Fiery'];

const ago = d => {
  const days = Math.floor((Date.now() - new Date(d)) / 864e5);
  return days < 1 ? 'today' : days < 7 ? `${days} day${days > 1 ? 's' : ''} ago` : days < 30 ? `${Math.floor(days / 7)} week${days >= 14 ? 's' : ''} ago` : `${Math.floor(days / 30)} mo ago`;
};
const sold = n => (n >= 1000 ? `${Math.floor(n / 1000)}K+ sold` : n > 0 ? `${n} sold` : '');

router.get('/products/:id/detail', wrap(async (req, res) => {
  const id = req.params.id;
  const { rows: [p] } = await pool.query('SELECT * FROM products WHERE id=$1', [id]);
  if (!p) return res.status(404).json({ error: 'Product not found' });
  const [{ rows: photos }, { rows: variants }, { rows: [views] }, { rows: dist }, { rows: reviews }] = await Promise.all([
    pool.query('SELECT url, caption, glints FROM product_photos WHERE product_id=$1 ORDER BY sort, id', [id]),
    pool.query('SELECT id, label, price, mrp, is_default FROM product_variants WHERE product_id=$1 AND COALESCE(in_stock,TRUE) ORDER BY sort, price', [id]),
    pool.query(`INSERT INTO product_views (product_id, day, n) VALUES ($1, CURRENT_DATE, 1)
                ON CONFLICT (product_id, day) DO UPDATE SET n = product_views.n + 1 RETURNING n`, [id]),
    pool.query(`SELECT stars, COUNT(*)::int c FROM product_reviews WHERE product_id=$1 AND status='approved' GROUP BY stars`, [id]).catch(() => ({ rows: [] })),
    pool.query(`SELECT r.stars, r.text, COALESCE(r.display_name, split_part(u.name,' ',1)) AS name, r.created_at
                  FROM product_reviews r JOIN users u ON u.id=r.user_id
                 WHERE r.product_id=$1 AND r.status='approved' ORDER BY r.featured DESC, r.created_at DESC LIMIT 3`, [id]).catch(() => ({ rows: [] })),
  ]);
  const total = dist.reduce((a, d) => a + d.c, 0);
  const avg = total ? dist.reduce((a, d) => a + d.stars * d.c, 0) / total : Number(p.rating || 0);
  const bars = [5, 4, 3, 2, 1].map(s => (total ? (dist.find(d => d.stars === s)?.c || 0) / total : 0));
  res.json({
    id: String(p.id), name: p.name, categoryLabel: p.category_label || p.category || '',
    rating: Math.round(avg * 10) / 10, reviewCount: total, soldText: sold(p.sold_count || 0),
    spice: p.spice || 0, spiceLabel: SPICE[p.spice || 0],
    viewersToday: views.n >= 3 ? views.n : 0,
    photos: photos.length ? photos : [{ url: p.image_url, caption: '', glints: [] }],
    videoUrl: p.video_url || '',
    variants: variants.map(v => ({ id: String(v.id), label: v.label, price: Number(v.price), mrp: Number(v.mrp || v.price) })),
    defaultVariantId: String((variants.find(v => v.is_default) || variants[0] || {}).id || ''),
    description: p.description, highlight: p.highlight, features: p.features || [],
    ingredients: p.ingredients || [], journey: p.journey || [], artisan: p.artisan, recipes: p.recipes || [],
    ratingBars: bars,
    reviews: reviews.map(r => ({ name: r.name, stars: r.stars, text: r.text, ago: ago(r.created_at) })),
    brandLine: p.brand_line, logo: process.env.LOGO_URL || '',
  });
}));

// ---------------- ADMIN ----------------
const admin = (req, res, next) => (req.user?.isAdmin ? next() : res.status(403).json({ error: 'Admins only' }));

router.put('/admin/products/:id/detail', admin, wrap(async (req, res) => {
  const b = req.body;
  const map = { categoryLabel: 'category_label', description: 'description', highlight: 'highlight', features: 'features', spice: 'spice',
    videoUrl: 'video_url', ingredients: 'ingredients', journey: 'journey', artisan: 'artisan', recipes: 'recipes', brandLine: 'brand_line' };
  for (const k of ['features', 'ingredients', 'journey', 'artisan', 'recipes']) if (k in b) b[k] = JSON.stringify(b[k]);
  if (b.spice != null) b.spice = Math.max(0, Math.min(5, Math.round(+b.spice)));
  const keys = Object.keys(map).filter(k => k in b);
  if (!keys.length) return res.status(400).json({ error: 'nothing to update' });
  const { rowCount } = await pool.query(`UPDATE products SET ${keys.map((k, i) => `${map[k]}=$${i + 1}`)} WHERE id=$${keys.length + 1}`, [...keys.map(k => b[k]), req.params.id]);
  if (!rowCount) return res.status(404).json({ error: 'Product not found' });
  res.json({ ok: true });
}));

fs.mkdirSync('uploads', { recursive: true });
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 12 * 1024 * 1024 },
  fileFilter: (_, f, cb) => cb(null, /^image\/(jpeg|png|webp)$/.test(f.mimetype)) });

// finds the brightest small spots (oil reflections) so the app can twinkle them
async function findGlints(buf) {
  const { data, info } = await sharp(buf).resize(120, 80, { fit: 'fill' }).greyscale().raw().toBuffer({ resolveWithObject: true });
  const px = Array.from(data), pts = [];
  for (let n = 0; n < 9; n++) {
    let best = 0, bi = 0;
    for (let i = 0; i < px.length; i++) if (px[i] > best) { best = px[i]; bi = i; }
    const x = bi % info.width, y = Math.floor(bi / info.width);
    if (x > 4 && x < 116 && y > 3 && y < 77) pts.push([+(x / 120).toFixed(3), +(y / 80).toFixed(3)]);
    for (let yy = Math.max(0, y - 8); yy < Math.min(80, y + 8); yy++) for (let xx = Math.max(0, x - 8); xx < Math.min(120, x + 8); xx++) px[yy * 120 + xx] = 0;
  }
  return pts;
}

router.post('/admin/products/:id/photos', admin, upload.single('photo'), wrap(async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'Send the image in the "photo" field' });
  const buf = await sharp(req.file.buffer).rotate().resize({ width: 1200, withoutEnlargement: true }).jpeg({ quality: 85, mozjpeg: true }).toBuffer();
  const name = `pd_${crypto.randomBytes(8).toString('hex')}.jpg`;
  fs.writeFileSync(path.join('uploads', name), buf);
  const glints = await findGlints(buf);
  const { rows: [r] } = await pool.query(
    `INSERT INTO product_photos (product_id, url, caption, glints, sort)
     VALUES ($1,$2,$3,$4,COALESCE((SELECT MAX(sort)+1 FROM product_photos WHERE product_id=$1),0)) RETURNING *`,
    [req.params.id, `${PUBLIC}/uploads/${name}`, String(req.body.caption || '').slice(0, 40), JSON.stringify(glints)]);
  res.json(r);
}));

router.put('/admin/products/:id/photos/:photoId', admin, wrap(async (req, res) => {
  const b = req.body, sets = [], vals = [];
  if (b.caption != null) { vals.push(String(b.caption).slice(0, 40)); sets.push(`caption=$${vals.length}`); }
  if (b.sort != null) { vals.push(+b.sort); sets.push(`sort=$${vals.length}`); }
  if (!sets.length) return res.status(400).json({ error: 'nothing to update' });
  vals.push(req.params.photoId, req.params.id);
  await pool.query(`UPDATE product_photos SET ${sets.join(', ')} WHERE id=$${vals.length - 1} AND product_id=$${vals.length}`, vals);
  res.json({ ok: true });
}));

router.delete('/admin/products/:id/photos/:photoId', admin, wrap(async (req, res) => {
  await pool.query('DELETE FROM product_photos WHERE id=$1 AND product_id=$2', [req.params.photoId, req.params.id]);
  res.json({ ok: true });
}));

router.use((e, req, res, next) => {
  if (e instanceof multer.MulterError) return res.status(400).json({ error: e.message });
  console.error(e);
  res.status(500).json({ error: 'Something went wrong' });
});
module.exports = router;
