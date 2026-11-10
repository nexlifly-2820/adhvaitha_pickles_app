// combo_box_backend.js — "Amma's Combo Box" v2: home section + 40+ jars with categories (Node + Express + PostgreSQL)
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
const money = n => Math.round(n * 100) / 100;
const norm = s => String(s || '').toLowerCase().replace(/\s+/g, '');
const HEX = /^#[0-9a-fA-F]{6}$/;

let cache = null, cacheAt = 0;
const clear = () => { cache = null; };

async function getSettings() {
  const { rows: [s] } = await pool.query('SELECT * FROM combo_settings WHERE id=1');
  const t = s || {};
  return {
    enabled: t.enabled !== false, eyebrow: t.eyebrow || 'BUILD YOUR BOX', titleStart: t.title_start ?? "Amma's",
    titleAccent: t.title_accent ?? 'Combo Box', jars: t.jars || 4, boxLabel: t.box_label ?? "Amma's Combo",
    lidText: t.lid_text ?? 'Made with love,\npacked by Amma', tagText: t.tag_text ?? 'For you, with love 💛',
    sizes: Array.isArray(t.sizes) && t.sizes.length ? t.sizes : ['250 g', '500 g', '1 kg'],
    tiers: (Array.isArray(t.tiers) ? t.tiers : []).map(x => ({ jars: Number(x.jars), percent: Number(x.percent) }))
      .filter(x => x.jars > 0 && x.percent > 0).sort((a, b) => a.jars - b.jars),
    categories: Array.isArray(t.categories) && t.categories.length ? t.categories : ['Pickles', 'Podis', 'Snacks', 'Sweets'],
    homeLine: t.home_line ?? 'pick any 4 jars, Amma packs them', homeTitle: t.home_title ?? 'Fill the box,',
    homeAccent: t.home_accent ?? 'save more', homeButton: t.home_button ?? 'Start building your box',
  };
}

const percentFor = (tiers, n) => tiers.reduce((p, t) => (n >= t.jars ? t.percent : p), 0);

async function comboProducts(sizes, onlyEnabled) {
  const { rows } = await pool.query(
    `SELECT c.*, p.name, p.image_url, p.is_active FROM combo_products c JOIN products p ON p.id = c.product_id
      ${onlyEnabled ? 'WHERE c.enabled AND p.is_active IS NOT FALSE' : ''} ORDER BY c.sort, c.id`);
  if (!rows.length) return [];
  const { rows: vs } = await pool.query(
    'SELECT id, product_id, label, price, mrp, in_stock, stock_qty FROM product_variants WHERE product_id = ANY($1)',
    [rows.map(r => r.product_id)]);
  return rows.map(r => {
    const prices = {};
    for (const size of sizes) {
      const v = vs.find(x => x.product_id === r.product_id && norm(x.label) === norm(size));
      if (v) prices[size] = { variantId: String(v.id), price: Number(v.price), mrp: Number(v.mrp || v.price),
        inStock: v.in_stock !== false && (v.stock_qty == null || v.stock_qty > 0) };
    }
    return { id: String(r.id), productId: String(r.product_id), name: r.name, image: abs(r.image || r.image_url),
      category: r.category || '', color1: r.color1, color2: r.color2, enabled: r.enabled, rawImage: r.image || '', prices };
  });
}

router.get('/combo-box', wrap(async (req, res) => {
  if (cache && Date.now() - cacheAt < 60_000) return res.json(cache);
  const s = await getSettings();
  const products = (await comboProducts(s.sizes, true)).filter(p => Object.keys(p.prices).length);
  const sizes = s.sizes.filter(z => products.filter(p => p.prices[z]).length >= s.jars);
  cache = { settings: { ...s, sizes }, products: products.map(({ enabled, rawImage, color1, color2, ...p }) => p) };
  cacheAt = Date.now();
  res.json(cache);
}));

router.post('/combo-box/cart', wrap(async (req, res) => {
  const uid = req.user?.id;
  if (!uid) return res.status(401).json({ error: 'Please log in to add the box' });
  const s = await getSettings();
  if (!s.enabled) throw bad('Combo boxes are not available right now');
  const size = String(req.body.size || '');
  const ids = Array.isArray(req.body.productIds) ? req.body.productIds.map(String) : [];
  if (!s.sizes.includes(size)) throw bad('Please choose a box size');
  if (ids.length !== s.jars) throw bad(`Pick ${s.jars} jars to fill the box`);
  if (new Set(ids).size !== ids.length) throw bad('Each jar can be picked once');
  const products = await comboProducts([size], true);
  const variants = ids.map(pid => {
    const p = products.find(x => x.productId === pid);
    const v = p?.prices[size];
    if (!p || !v) throw bad('One of the jars is not available in this size');
    if (!v.inStock) throw bad(`${p.name} (${size}) is out of stock — please swap it`);
    return { productId: Number(pid), variantId: Number(v.variantId) };
  });
  const percent = percentFor(s.tiers, ids.length);
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    for (const v of variants) {
      await client.query(
        `INSERT INTO cart_items (user_id, product_id, variant_id, qty) VALUES ($1,$2,$3,1)
         ON CONFLICT (user_id, product_id, variant_id) DO UPDATE SET qty = LEAST(cart_items.qty + 1, 20)`,
        [uid, v.productId, v.variantId]);
    }
    await client.query('INSERT INTO cart_combos (user_id, size, variant_ids, percent) VALUES ($1,$2,$3,$4)',
      [uid, size, variants.map(v => v.variantId), percent]);
    await client.query('COMMIT');
  } catch (e) { await client.query('ROLLBACK'); throw e; } finally { client.release(); }
  res.json({ ok: true, percent });
}));

async function comboDiscount(uid, cartList) {
  const { rows } = await pool.query('SELECT * FROM cart_combos WHERE user_id=$1 ORDER BY id', [uid]);
  if (!rows.length) return { amount: 0, boxes: [] };
  const left = {};
  for (const i of cartList) left[i.variantId] = (left[i.variantId] || 0) + i.qty;
  const price = {};
  for (const i of cartList) price[i.variantId] = i.price;
  let amount = 0; const boxes = []; const stale = [];
  for (const r of rows) {
    const vids = r.variant_ids.map(String);
    if (vids.every(v => (left[v] || 0) > 0)) {
      vids.forEach(v => { left[v] -= 1; });
      const sum = vids.reduce((a, v) => a + (price[v] || 0), 0);
      const off = money(sum * Number(r.percent) / 100);
      amount += off;
      boxes.push({ id: r.id, size: r.size, jars: vids.length, percent: Number(r.percent), amount: off });
    } else stale.push(r.id);
  }
  if (stale.length) await pool.query('DELETE FROM cart_combos WHERE id = ANY($1)', [stale]);
  return { amount: money(amount), boxes };
}

const admin = (req, res, next) => (req.user?.isAdmin ? next() : res.status(403).json({ error: 'Admins only' }));

router.get('/admin/combo-box/settings', admin, wrap(async (req, res) => res.json(await getSettings())));
router.put('/admin/combo-box/settings', admin, wrap(async (req, res) => {
  const b = req.body;
  const jars = b.jars == null ? null : parseInt(b.jars, 10);
  if (jars != null && !(jars >= 2 && jars <= 4)) throw bad('Jars per box must be 2 to 4');
  let sizes = null, tiers = null, categories = null;
  if (b.categories != null) {
    categories = (Array.isArray(b.categories) ? b.categories : String(b.categories).split(',')).map(x => String(x).trim()).filter(Boolean);
  }
  if (b.sizes != null) {
    sizes = (Array.isArray(b.sizes) ? b.sizes : String(b.sizes).split(',')).map(x => String(x).trim()).filter(Boolean);
  }
  if (b.tiers != null) {
    tiers = (Array.isArray(b.tiers) ? b.tiers : []).map(t => ({ jars: parseInt(t.jars, 10), percent: Number(t.percent) }));
  }
  await pool.query(
    `UPDATE combo_settings SET enabled=COALESCE($1,enabled), eyebrow=COALESCE($2,eyebrow), title_start=COALESCE($3,title_start),
       title_accent=COALESCE($4,title_accent), jars=COALESCE($5,jars), box_label=COALESCE($6,box_label), lid_text=COALESCE($7,lid_text),
       tag_text=COALESCE($8,tag_text), sizes=COALESCE($9,sizes), tiers=COALESCE($10,tiers), categories=COALESCE($11,categories),
       home_line=COALESCE($12,home_line), home_title=COALESCE($13,home_title), home_accent=COALESCE($14,home_accent), home_button=COALESCE($15,home_button) WHERE id=1`,
    [b.enabled ?? null, b.eyebrow ?? null, b.titleStart ?? null, b.titleAccent ?? null, jars, b.boxLabel ?? null, b.lidText ?? null,
      b.tagText ?? null, sizes && JSON.stringify(sizes), tiers && JSON.stringify(tiers), categories && JSON.stringify(categories),
      b.homeLine ?? null, b.homeTitle ?? null, b.homeAccent ?? null, b.homeButton ?? null]);
  clear();
  res.json({ ok: true });
}));

router.get('/admin/combo-box/products', admin, wrap(async (req, res) => {
  const s = await getSettings();
  res.json(await comboProducts(s.sizes, false));
}));

router.post('/admin/combo-box/products/bulk', admin, wrap(async (req, res) => {
  const ids = (Array.isArray(req.body.productIds) ? req.body.productIds : String(req.body.productIds || '').split(/[\s,]+/))
    .map(x => parseInt(x, 10)).filter(Boolean);
  if (!ids.length) throw bad('Enter product IDs');
  const category = String(req.body.category || '').slice(0, 30);
  const { rows: found } = await pool.query('SELECT id FROM products WHERE id = ANY($1)', [ids]);
  const ok = found.map(r => r.id);
  let added = 0;
  for (const pid of ids.filter(i => ok.includes(i))) {
    const { rowCount } = await pool.query(
      `INSERT INTO combo_products (product_id, category, sort) VALUES ($1,$2,(SELECT COALESCE(MAX(sort),0)+1 FROM combo_products))
       ON CONFLICT (product_id) DO NOTHING`, [pid, category]);
    added += rowCount;
  }
  clear();
  res.json({ ok: true, added, notFound: ids.filter(i => !ok.includes(i)) });
}));
router.delete('/admin/combo-box/products/:id', admin, wrap(async (req, res) => {
  await pool.query('DELETE FROM combo_products WHERE id=$1', [req.params.id]);
  clear();
  res.json({ ok: true });
}));

fs.mkdirSync('uploads', { recursive: true });
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 } });
router.post('/admin/combo-box/upload', admin, upload.single('image'), wrap(async (req, res) => {
  if (!req.file) throw bad('Send an image');
  const buf = await sharp(req.file.buffer).rotate().resize(480, 480, { fit: 'inside', withoutEnlargement: true }).png().toBuffer();
  const name = `combo_${crypto.randomBytes(8).toString('hex')}.png`;
  fs.writeFileSync(path.join('uploads', name), buf);
  res.json({ ok: true, path: `/uploads/${name}`, url: abs(`/uploads/${name}`) });
}));

module.exports = router;
module.exports.comboDiscount = comboDiscount;
