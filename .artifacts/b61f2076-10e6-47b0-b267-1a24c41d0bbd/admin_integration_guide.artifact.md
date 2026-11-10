# Ambhujakshi Specials (Lotus Eye) — Admin Dashboard Integration

Here are the exact backend router script (`specials_backend.js`) and admin management panel (`admin_specials.html`) for your admin dashboard (`https://admin.adhvaithafoods.in`).

## 1. Backend Router (`specials_backend.js`)

Add this route handler to your Express backend (Node.js + PostgreSQL):

```javascript
// specials_backend.js — "Ambhujakshi Specials" (home tiles + Lotus Eye page) — Node + Express + PostgreSQL
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
const ICONS = ['recipe', 'leaf', 'jar', 'sun', 'fire', 'hand', 'ghee', 'heart', 'star', 'truck'];
let cache = null, cacheAt = 0;
const clear = () => { cache = null; };

router.get('/specials', wrap(async (req, res) => {
  if (cache && Date.now() - cacheAt < 60_000) return res.json(cache);
  const { rows: [s] } = await pool.query('SELECT * FROM specials_settings WHERE id=1');
  const { rows } = await pool.query('SELECT * FROM specials WHERE enabled ORDER BY sort, id');
  const items = rows.map(r => ({
    id: String(r.id), productId: r.product_id || '', name: r.name, story: r.story || '', image: abs(r.image),
    features: (r.features || []).filter(f => f && f.text).slice(0, 3).map(f => ({ icon: ICONS.includes(f.icon) ? f.icon : 'star', text: String(f.text) })),
    variants: (r.variants || []).filter(v => v && v.label && Number(v.price) > 0)
      .map(v => ({ id: String(v.id || ''), label: String(v.label), price: Number(v.price), mrp: Number(v.mrp) || 0 })),
    defaultVariant: r.default_variant || 0,
  })).filter(i => i.image && i.variants.length);
  const t = s || {};
  cache = {
    settings: { enabled: t.enabled !== false, title: t.title || 'AMBHUJAKSHI', subtitle: t.subtitle || 'SPECIALS',
      tagline: t.tagline || 'Seen through the Lotus Eye', tagText: t.tag_text || "AMMA'S SPECIAL", moreText: t.more_text || 'MORE SPECIALS',
      showIntro: t.show_intro !== false },
    items,
  };
  cacheAt = Date.now();
  res.json(cache);
}));

// ---------------- ADMIN ----------------
const admin = (req, res, next) => (req.user?.isAdmin ? next() : res.status(403).json({ error: 'Admins only' }));

router.get('/admin/specials/settings', admin, wrap(async (req, res) =>
  res.json((await pool.query('SELECT * FROM specials_settings WHERE id=1')).rows[0])));
router.put('/admin/specials/settings', admin, wrap(async (req, res) => {
  const b = req.body;
  await pool.query(`UPDATE specials_settings SET enabled=COALESCE($1,enabled), title=COALESCE($2,title), subtitle=COALESCE($3,subtitle),
    tagline=COALESCE($4,tagline), tag_text=COALESCE($5,tag_text), more_text=COALESCE($6,more_text), show_intro=COALESCE($7,show_intro) WHERE id=1`,
    [b.enabled ?? null, b.title ?? null, b.subtitle ?? null, b.tagline ?? null, b.tagText ?? null, b.moreText ?? null, b.showIntro ?? null]);
  clear();
  res.json({ ok: true });
}));

router.get('/admin/specials', admin, wrap(async (req, res) =>
  res.json((await pool.query('SELECT * FROM specials ORDER BY sort, id')).rows)));

const MAP = { productId: 'product_id', name: 'name', story: 'story', image: 'image', features: 'features', variants: 'variants', defaultVariant: 'default_variant', enabled: 'enabled' };
function check(b) {
  if (b.name != null && (!String(b.name).trim() || String(b.name).length > 18)) throw bad('Name is required, max 18 letters');
  if (b.story != null && String(b.story).length > 80) throw bad('Story max 80 letters (one line in the app)');
  if (b.features != null) {
    if (!Array.isArray(b.features) || b.features.length > 3) throw bad('Up to 3 features');
    b.features = JSON.stringify(b.features.map(f => ({ icon: ICONS.includes(f.icon) ? f.icon : 'star', text: String(f.text || '').slice(0, 28) })).filter(f => f.text));
  }
  if (b.variants != null) {
    if (!Array.isArray(b.variants) || !b.variants.length || b.variants.length > 3) throw bad('Add 1 to 3 weights');
    b.variants = JSON.stringify(b.variants.map(v => {
      if (!String(v.label || '').trim() || !(Number(v.price) > 0)) throw bad('Every weight needs a label (e.g. 250 g) and a price');
      return { id: String(v.id || ''), label: String(v.label).trim().slice(0, 8), price: Number(v.price), mrp: Number(v.mrp) || 0 };
    }));
  }
  if (b.defaultVariant != null) b.defaultVariant = Math.max(0, Math.min(2, parseInt(b.defaultVariant, 10) || 0));
}

router.post('/admin/specials', admin, wrap(async (req, res) => {
  const b = req.body;
  if (!b.name) throw bad('Name is required');
  check(b);
  const keys = Object.keys(MAP).filter(k => k in b);
  const { rows: [r] } = await pool.query(
    `INSERT INTO specials (${keys.map(k => MAP[k]).concat('sort')}) VALUES (${keys.map((_, i) => `$${i + 1}`).concat('(SELECT COALESCE(MAX(sort),0)+1 FROM specials)')}) RETURNING *`,
    keys.map(k => b[k]));
  clear();
  res.json(r);
}));
router.put('/admin/specials/:id', admin, wrap(async (req, res) => {
  const b = req.body; check(b);
  const keys = Object.keys(MAP).filter(k => k in b);
  if (!keys.length) throw bad('Nothing to update');
  const { rowCount } = await pool.query(`UPDATE specials SET ${keys.map((k, i) => `${MAP[k]}=$${i + 1}`)} WHERE id=$${keys.length + 1}`, [...keys.map(k => b[k]), req.params.id]);
  if (!rowCount) return res.status(404).json({ error: 'Not found' });
  clear();
  res.json({ ok: true });
}));
router.delete('/admin/specials/:id', admin, wrap(async (req, res) => {
  await pool.query('DELETE FROM specials WHERE id=$1', [req.params.id]);
  clear();
  res.json({ ok: true });
}));
router.put('/admin/specials-order', admin, wrap(async (req, res) => {
  const ids = Array.isArray(req.body.ids) ? req.body.ids : [];
  for (let i = 0; i < ids.length; i++) await pool.query('UPDATE specials SET sort=$1 WHERE id=$2', [i + 1, ids[i]]);
  clear();
  res.json({ ok: true });
}));

fs.mkdirSync('uploads', { recursive: true });
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_, f, cb) => cb(null, /^image\/(png|jpe?g|webp)$/.test(f.mimetype)) });
router.post('/admin/specials-upload', admin, upload.single('image'), wrap(async (req, res) => {
  if (!req.file) throw bad('Send a PNG/JPG/WebP photo in the "image" field');
  const buf = await sharp(req.file.buffer).rotate().resize(800, 800, { fit: 'inside', withoutEnlargement: true }).png().toBuffer();
  const name = `special_${crypto.randomBytes(8).toString('hex')}.png`;
  fs.writeFileSync(path.join('uploads', name), buf);
  res.json({ ok: true, path: `/uploads/${name}`, url: abs(`/uploads/${name}`) });
}));

module.exports = router;
```

## 2. Admin Panel HTML (`admin_specials.html`)

You can save this file as `admin_specials.html` in your admin dashboard static files:

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Ambhujakshi Specials · Admin</title>
<style>
body{font-family:system-ui,sans-serif;background:#f7efe9;margin:0;color:#2a0a10}
header{background:linear-gradient(90deg,#4E0F24,#7A1E3A);color:#F6DA9A;padding:14px 20px;font-weight:700;letter-spacing:1px}
main{max-width:920px;margin:auto;padding:16px}
.card{background:#fff;border-radius:14px;padding:16px;margin-bottom:14px;box-shadow:0 2px 8px rgba(0,0,0,.06)}
label{display:block;font-size:12px;font-weight:600;color:#7a5a50;margin:8px 0 3px}
input,select{width:100%;box-sizing:border-box;padding:8px;border:1px solid #e3d3cc;border-radius:8px;font:inherit}
.row{display:flex;gap:10px;flex-wrap:wrap}.row>*{flex:1;min-width:140px}
button{background:#7A1E3A;color:#fff;border:0;border-radius:9px;padding:8px 14px;font-weight:700;cursor:pointer}
button.ghost{background:#f3e6e1;color:#2a0a10}button.del{background:#b3261e}
.bowl{width:90px;height:76px;object-fit:contain;background:radial-gradient(#7A1E36,#3A0A18);border-radius:12px}
.v{display:grid;grid-template-columns:1fr 1fr 1fr 1fr auto;gap:6px;margin-bottom:6px}
.f{display:grid;grid-template-columns:140px 1fr;gap:6px;margin-bottom:6px}
small{color:#9a7f76}.head{display:flex;justify-content:space-between;align-items:center}
</style>
</head>
<body>
<header>AMBHUJAKSHI SPECIALS · Lotus Eye</header>
<main>
 <div class="card"><b>Texts</b>
  <div class="row"><div><label for="title">Title</label><input id="title"></div><div><label for="subtitle">Subtitle</label><input id="subtitle"></div><div><label for="tagline">Tagline</label><input id="tagline"></div></div>
  <div class="row"><div><label for="tagText">Gold tag above the name</label><input id="tagText"></div><div><label for="moreText">"More specials" heading</label><input id="moreText"></div>
   <div><label for="showIntro">Show intro screen</label><select id="showIntro"><option value="true">Yes</option><option value="false">No</option></select></div>
   <div><label for="enabled">Show in app</label><select id="enabled"><option value="true">Yes</option><option value="false">No</option></select></div></div>
  <p><button onclick="saveSettings()">Save texts</button></p>
 </div>
 <div class="head"><b>Specials (shown in this order)</b><button onclick="addItem()">+ Add special</button></div>
 <div id="list" style="margin-top:10px"></div>
</main>
<script>
const API = localStorage.API || prompt('API base (e.g. https://your-api.com/api)'); localStorage.API = API;
const TOKEN = localStorage.TOKEN || prompt('Admin token'); localStorage.TOKEN = TOKEN;
const ICONS = [['recipe','Recipe bowl'],['leaf','Leaf'],['jar','Jar'],['sun','Sun'],['fire','Flame'],['hand','Hand-made'],['ghee','Ghee / oil drop'],['heart','Heart'],['star','Star'],['truck','Delivery']];
async function call(method, url, body) {
  const isForm = body instanceof FormData;
  const r = await fetch(API + url, { method, headers: isForm ? { Authorization: 'Bearer ' + TOKEN } : { Authorization: 'Bearer ' + TOKEN, 'Content-Type': 'application/json' }, body: isForm ? body : body && JSON.stringify(body) });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) { alert(j.error || 'Error ' + r.status); throw new Error(j.error); }
  return j;
}
const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const img = u => !u ? '' : /^https?:/.test(u) ? u : API.replace(/\/api\/?$/, '') + u;
let items = [];
async function load() {
  const s = await call('GET', '/admin/specials/settings');
  title.value = s.title; subtitle.value = s.subtitle; tagline.value = s.tagline; tagText.value = s.tag_text; moreText.value = s.more_text;
  showIntro.value = String(s.show_intro); enabled.value = String(s.enabled);
  items = await call('GET', '/admin/specials'); render();
}
async function saveSettings() {
  await call('PUT', '/admin/specials/settings', { title: title.value, subtitle: subtitle.value, tagline: tagline.value, tagText: tagText.value, moreText: moreText.value, showIntro: showIntro.value === 'true', enabled: enabled.value === 'true' });
  alert('Saved — the app updates within a minute');
}
function render() {
  list.innerHTML = items.map((it, i) => `<div class="card">
   <div class="head"><b>${i + 1}. ${esc(it.name)}</b><span><button class="ghost" onclick="move(${i},-1)">↑</button> <button class="ghost" onclick="move(${i},1)">↓</button>
    <label style="display:inline"><input type="checkbox" ${it.enabled ? 'checked' : ''} onchange="items[${i}].enabled=this.checked" style="width:auto"> Show</label></span></div>
   <div class="row">
    <div style="flex:0 0 110px"><label>Bowl photo</label><img class="bowl" src="${esc(img(it.image))}"><input type="file" accept="image/*" onchange="up(${i},this)"><small>transparent PNG, bowl seen from the front</small></div>
    <div><label>Name (max 18)</label><input value="${esc(it.name)}" oninput="items[${i}].name=this.value">
     <label>Product ID (for Add to cart)</label><input value="${esc(it.product_id)}" oninput="items[${i}].product_id=this.value"></div>
    <div><label>Story line (max 80)</label><input value="${esc(it.story)}" oninput="items[${i}].story=this.value"></div>
   </div>
   <label>Features (up to 3)</label>
   ${[0, 1, 2].map(k => { const f = (it.features || [])[k] || { icon: '', text: '' }; return `<div class="f"><select onchange="setF(${i},${k},'icon',this.value)"><option value="">— none —</option>${ICONS.map(o => `<option value="${o[0]}" ${o[0] === f.icon ? 'selected' : ''}>${o[1]}</option>`).join('')}</select><input placeholder="e.g. No Preservatives" value="${esc(f.text)}" oninput="setF(${i},${k},'text',this.value)"></div>` }).join('')}
   <label>Weights (up to 3) <small>— variant ID = your product variant id for the cart</small></label>
   ${(it.variants || []).map((v, k) => `<div class="v"><input placeholder="250 g" value="${esc(v.label)}" oninput="items[${i}].variants[${k}].label=this.value">
     <input type="number" placeholder="Price" value="${v.price}" oninput="items[${i}].variants[${k}].price=+this.value">
     <input type="number" placeholder="MRP (for % OFF)" value="${v.mrp || ''}" oninput="items[${i}].variants[${k}].mrp=+this.value">
     <input placeholder="Variant ID" value="${esc(v.id || '')}" oninput="items[${i}].variants[${k}].id=this.value">
     <button class="del" onclick="items[${i}].variants.splice(${k},1);render()">✕</button></div>`).join('')}
   ${(it.variants || []).length < 3 ? `<button class="ghost" onclick="(items[${i}].variants=items[${i}].variants||[]).push({label:'',price:0,mrp:0,id:''});render()">+ Weight</button>` : ''}
   <label>Selected first</label><select onchange="items[${i}].default_variant=+this.value">${(it.variants || []).map((v, k) => `<option value="${k}" ${k === it.default_variant ? 'selected' : ''}>${esc(v.label || 'weight ' + (k + 1))}</option>`).join('')}</select>
   <p class="row" style="justify-content:flex-end"><button onclick="save(${i})">Save special</button> <button class="del" style="flex:0" onclick="del(${i})">Delete</button></p>
  </div>`).join('');
}
function setF(i, k, key, val) { const fs = items[i].features = items[i].features || []; fs[k] = fs[k] || { icon: '', text: '' }; fs[k][key] = val; }
async function up(i, el) { const f = new FormData(); f.append('image', el.files[0]); const r = await call('POST', '/admin/specials-upload', f); items[i].image = r.path; render(); }
async function save(i) {
  const it = items[i];
  await call('PUT', `/admin/specials/${it.id}`, { name: it.name, productId: it.product_id, story: it.story, image: it.image, enabled: it.enabled,
    features: (it.features || []).filter(f => f && f.text && f.icon), variants: it.variants || [], defaultVariant: it.default_variant || 0 });
  alert('Saved — the app updates within a minute');
}
async function del(i) { if (!confirm('Delete ' + items[i].name + '?')) return; await call('DELETE', `/admin/specials/${items[i].id}`); load(); }
async function addItem() { const name = prompt('Special name'); if (!name) return; await call('POST', '/admin/specials', { name }); load(); }
async function move(i, d) { const j = i + d; if (j < 0 || j >= items.length) return; [items[i], items[j]] = [items[j], items[i]]; await call('PUT', '/admin/specials-order', { ids: items.map(x => x.id) }); render(); }
load();
</script>
</body>
</html>
```
