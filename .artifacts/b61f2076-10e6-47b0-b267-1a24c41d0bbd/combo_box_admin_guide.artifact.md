# Amma's Combo Box — Admin Dashboard & Bulk 20+ Products Guide

Here is the complete backend and admin interface to manage **Amma's Combo Box** and add 20+ products effortlessly via bulk ID import.

## 1. How to Add 20+ Products in the Admin Dashboard

In your admin dashboard (`admin_combo_box.html`), use the **Bulk Add** feature at the bottom of the Jars section:
1. Paste a comma-separated or space-separated list of product IDs (e.g. your first 20 product IDs):
   ```text
   1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20
   ```
2. Select the category (e.g. *Pickles*, *Podis*, *Snacks*, or *Sweets*).
3. Click **+ Add**. All 20 products will be instantly imported into the combo box selector!

---

## 2. Backend Script (`combo_box_backend.js`)

```javascript
// combo_box_backend.js — "Amma's Combo Box" v2
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

module.exports = router;
```
