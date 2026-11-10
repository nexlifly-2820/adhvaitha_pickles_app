// categories_backend.js — data for the 3D "lazy susan" category section (Node + Express + PostgreSQL)
//   npm i express pg
//   app.use(express.json());
//   app.use('/api', auth, require('./categories_backend'));      // auth sets req.user = { isAdmin } (GET works for guests)
//
// IMPORTANT for the 3D view: the bowl photos are loaded as WebGL textures, so the image server must send
//   Access-Control-Allow-Origin: *   e.g.  app.use('/uploads', (req,res,next)=>{res.set('Access-Control-Allow-Origin','*');next()}, express.static('uploads'))
//   (S3 / Cloudinary / Firebase: enable CORS for GET on the bucket.)  Use transparent PNG bowl cut-outs.
//
// APP:    GET /api/shop/categories
// ADMIN:  GET/PUT /api/admin/shop-categories/settings
//         GET/POST /api/admin/shop-categories        PUT/DELETE /api/admin/shop-categories/:id
//
// TABLES (run once)
/*
CREATE TABLE IF NOT EXISTS shop_category_settings (
  id INT PRIMARY KEY DEFAULT 1,
  enabled BOOLEAN DEFAULT TRUE,
  eyebrow TEXT DEFAULT 'SHOP BY CATEGORY',
  title_start TEXT DEFAULT 'Spin Amma''s',
  title_accent TEXT DEFAULT 'lazy susan',
  hint TEXT DEFAULT '👆 Tap a bowl, a name or swipe to choose',
  show_products BOOLEAN DEFAULT TRUE,
  products_per_category INT DEFAULT 6
);
INSERT INTO shop_category_settings (id) VALUES (1) ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS shop_categories (
  id SERIAL PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,          -- must match products.category (e.g. 'pickle')
  name TEXT NOT NULL,                 -- Pickles
  label TEXT DEFAULT '',              -- BESTSELLERS
  subtitle TEXT DEFAULT '',           -- Sun-cured in jaadis
  image TEXT NOT NULL,                -- transparent bowl PNG (https, CORS enabled)
  color1 TEXT DEFAULT '#E8432B', color2 TEXT DEFAULT '#9E1424', color3 TEXT DEFAULT '#4A0A0E',  -- light, main, dark
  enabled BOOLEAN DEFAULT TRUE,
  sort INT DEFAULT 0
);
INSERT INTO shop_categories (slug,name,label,subtitle,image,color1,color2,color3,sort) VALUES
 ('pickle','Pickles','BESTSELLERS','Sun-cured in jaadis','','#E8432B','#9E1424','#4A0A0E',1),
 ('podi','Podis','MADE DAILY','Stone-ground fresh every week','','#3FA34D','#1D6B33','#0A2E16',2),
 ('snack','Snacks','CRISPY','Crunchy, tea-time ready','','#F59E2B','#C2410C','#5A1E04',3),
 ('sweet','Sweets','FESTIVE','Pure ghee & jaggery','','#E0579A','#9D174D','#4A0A26',4),
 ('vadiyalu','Vadiyalu','FRY & ENJOY','Sun-dried on the terrace','','#8B5CF6','#5B21B6','#26104F',5),
 ('masala','Masalas','AROMATIC','Whole spices, slow-roasted','','#B7791F','#7A4512','#3A1E06',6)
ON CONFLICT DO NOTHING;      -- then set each "image" from the admin dashboard
*/
// Uses products(id, name, short_name, category, image_url, price, is_active, sort / sales_count)

const express = require('express');
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const router = express.Router();
const wrap = fn => (req, res, next) => fn(req, res).catch(next);
const HEX = /^#[0-9a-f]{6}$/i;
let cache = null, cacheAt = 0;
const clear = () => { cache = null; };

router.get('/shop/categories', wrap(async (_, res) => {
  if (cache && Date.now() - cacheAt < 60_000) return res.json(cache);
  const { rows: [s] } = await pool.query('SELECT * FROM shop_category_settings WHERE id=1');
  const { rows: cats } = await pool.query(
    `SELECT c.*, (SELECT COUNT(*) FROM products p WHERE LOWER(p.category)=c.slug AND COALESCE(p.is_active,TRUE))::int AS count
       FROM shop_categories c WHERE c.enabled AND c.image <> '' ORDER BY c.sort, c.id`);
  const out = [];
  for (const c of cats) {
    let products = [];
    if (s.show_products) {
      const { rows } = await pool.query(
        `SELECT id, COALESCE(short_name,name) AS name, image_url, price FROM products
          WHERE LOWER(category)=$1 AND COALESCE(is_active,TRUE) ORDER BY COALESCE(sales_count,0) DESC, id LIMIT $2`, [c.slug, s.products_per_category]);
      products = rows.map(p => ({ id: String(p.id), name: p.name, image: p.image_url || '', price: Number(p.price) }));
    }
    out.push({ id: String(c.id), slug: c.slug, name: c.name, label: c.label, subtitle: c.subtitle, image: c.image,
      color1: c.color1, color2: c.color2, color3: c.color3, count: c.count, products });
  }
  cache = { settings: { enabled: s.enabled, eyebrow: s.eyebrow, titleStart: s.title_start, titleAccent: s.title_accent, hint: s.hint, products: s.show_products },
    categories: out };
  cacheAt = Date.now();
  res.json(cache);
}));

// ---------------- ADMIN ----------------
const admin = (req, res, next) => (req.user?.isAdmin ? next() : res.status(403).json({ error: 'Admins only' }));

router.get('/admin/shop-categories/settings', admin, wrap(async (_, res) => res.json((await pool.query('SELECT * FROM shop_category_settings WHERE id=1')).rows[0])));
router.put('/admin/shop-categories/settings', admin, wrap(async (req, res) => {
  const b = req.body;
  const map = { enabled: 'enabled', eyebrow: 'eyebrow', titleStart: 'title_start', titleAccent: 'title_accent', hint: 'hint',
    showProducts: 'show_products', productsPerCategory: 'products_per_category' };
  if (b.productsPerCategory != null) b.productsPerCategory = Math.min(10, Math.max(1, +b.productsPerCategory));
  const keys = Object.keys(map).filter(k => k in b);
  if (!keys.length) return res.status(400).json({ error: 'nothing to update' });
  await pool.query(`UPDATE shop_category_settings SET ${keys.map((k, i) => `${map[k]}=$${i + 1}`)} WHERE id=1`, keys.map(k => b[k]));
  clear();
  res.json({ ok: true });
}));

router.get('/admin/shop-categories', admin, wrap(async (_, res) => res.json((await pool.query('SELECT * FROM shop_categories ORDER BY sort, id')).rows)));

const MAP = { slug: 'slug', name: 'name', label: 'label', subtitle: 'subtitle', image: 'image', color1: 'color1', color2: 'color2', color3: 'color3', enabled: 'enabled', sort: 'sort' };
function check(b) {
  for (const k of ['color1', 'color2', 'color3']) if (b[k] && !HEX.test(b[k])) throw Object.assign(new Error(`${k} must be like #E8432B`), { status: 400 });
  if (b.slug) b.slug = String(b.slug).toLowerCase().trim();
  if (b.name && b.name.length > 14) throw Object.assign(new Error('name max 14 letters (it shows on a small tag)'), { status: 400 });
}

router.post('/admin/shop-categories', admin, wrap(async (req, res) => {
  const b = req.body; check(b);
  if (!b.slug || !b.name || !b.image) return res.status(400).json({ error: 'slug, name and image are required' });
  const keys = Object.keys(MAP).filter(k => k in b);
  const { rows: [r] } = await pool.query(`INSERT INTO shop_categories (${keys.map(k => MAP[k])}) VALUES (${keys.map((_, i) => `$${i + 1}`)}) RETURNING *`, keys.map(k => b[k]));
  clear();
  res.json(r);
}));

router.put('/admin/shop-categories/:id', admin, wrap(async (req, res) => {
  const b = req.body; check(b);
  const keys = Object.keys(MAP).filter(k => k in b);
  if (!keys.length) return res.status(400).json({ error: 'nothing to update' });
  const { rowCount } = await pool.query(`UPDATE shop_categories SET ${keys.map((k, i) => `${MAP[k]}=$${i + 1}`)} WHERE id=$${keys.length + 1}`, [...keys.map(k => b[k]), req.params.id]);
  if (!rowCount) return res.status(404).json({ error: 'Not found' });
  clear();
  res.json({ ok: true });
}));

router.delete('/admin/shop-categories/:id', admin, wrap(async (req, res) => {
  await pool.query('DELETE FROM shop_categories WHERE id=$1', [req.params.id]);
  clear();
  res.json({ ok: true });
}));

router.use((e, req, res, next) => {
  if (e.status === 400) return res.status(400).json({ error: e.message });
  console.error(e);
  res.status(500).json({ error: 'Something went wrong' });
});
module.exports = router;
