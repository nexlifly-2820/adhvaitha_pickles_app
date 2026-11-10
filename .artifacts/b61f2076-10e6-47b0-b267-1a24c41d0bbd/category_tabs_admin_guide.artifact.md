# Glass Category Tabs — Admin Dashboard Integration

Here are the backend router script (`category_tabs_backend.js`) and admin management panel (`admin_category_tabs.html`) to manage your home category tabs (`All`, `Pickles`, `Snacks`, `Sweets`, `Podis`, `Combos`) from your admin dashboard (`https://admin.adhvaithafoods.in`).

## 1. Database Table (PostgreSQL)

Run this SQL query once on your database:

```sql
CREATE TABLE IF NOT EXISTS category_tabs (
  id SERIAL PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,          -- all, pickles, snacks ...
  label TEXT NOT NULL,                -- shown under the circle
  image TEXT DEFAULT '',              -- dish photo (transparent PNG)
  badge TEXT DEFAULT '',              -- e.g. NEW (empty = none)
  enabled BOOLEAN DEFAULT TRUE,
  sort INT DEFAULT 0
);

INSERT INTO category_tabs (slug,label,sort) VALUES
 ('all','All',1),('pickles','Pickles',2),('snacks','Snacks',3),('sweets','Sweets',4),('podis','Podis',5),('combos','Combos',6)
ON CONFLICT (slug) DO NOTHING;

UPDATE category_tabs SET badge='NEW' WHERE slug='snacks' AND badge='';
```

---

## 2. Backend Router (`category_tabs_backend.js`)

```javascript
// category_tabs_backend.js — home category tabs (Node + Express + PostgreSQL)
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
```

---

## 3. Admin Panel HTML (`admin_category_tabs.html`)

Save this file as `admin_category_tabs.html` in your admin static files directory:

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Category Tabs · Admin</title>
<style>
*{box-sizing:border-box}body{margin:0;font-family:system-ui,sans-serif;background:#FFF7F2;color:#2A1A14}
header{background:linear-gradient(90deg,#8E0D0A,#C81E12);color:#fff;padding:14px 20px;display:flex;gap:10px;align-items:center;flex-wrap:wrap}
header h1{font-size:18px;margin:0;flex:1}header input{padding:7px;border:0;border-radius:7px;width:230px}
main{max-width:900px;margin:auto;padding:16px}.card{background:#fff;border:1px solid #F0E0D6;border-radius:14px;padding:16px;margin-bottom:14px}
input,select{width:100%;padding:7px;border:1px solid #E5D3C8;border-radius:8px;font:inherit}
button{background:#B5170F;color:#fff;border:0;border-radius:8px;padding:7px 12px;font-weight:700;cursor:pointer}button.g{background:#F3E6DE;color:#2A1A14}button.d{background:#7A1010}
table{width:100%;border-collapse:collapse;font-size:13px}td,th{padding:7px 5px;border-bottom:1px solid #F3E6DE;text-align:left;vertical-align:middle}
th{font-size:11px;color:#9A7F70;text-transform:uppercase}
.pv{width:56px;height:56px;border-radius:50%;background:radial-gradient(circle at 50% 30%,#E0381E,#8E0D0A);display:grid;place-items:center}.pv img{width:50px}
.off td{opacity:.5}.row{display:flex;gap:8px;flex-wrap:wrap;align-items:flex-end}.row>div{flex:1;min-width:120px}label{font-size:12px;font-weight:600;color:#7A6656}
#t{position:fixed;bottom:20px;left:50%;transform:translateX(-50%);background:#2A1A14;color:#fff;padding:9px 16px;border-radius:9px;display:none}
</style>
</head>
<body>
<header><h1>Home Category Tabs</h1><input id="api" placeholder="API base e.g. https://your-api.com/api"><input id="tok" placeholder="Admin token"><button onclick="conn()">Connect</button></header>
<main>
<div class="card"><p style="margin:0 0 10px;font-size:13px;color:#7A6656">Upload a transparent PNG dish photo for each tab. The <b>All</b> tab shows the first 4 other tabs' photos automatically. The <b>slug</b> is what your app uses to filter (all, pickles, snacks…).</p>
<table id="list"></table></div>
<div class="card"><b>Add a tab</b><div class="row" style="margin-top:8px">
 <div><label for="nl">Name</label><input id="nl" placeholder="Dry Fruits"></div><div><label for="ns">Slug</label><input id="ns" placeholder="dry-fruits"></div>
 <div><label for="nb">Badge</label><input id="nb" placeholder="NEW (optional)"></div><div style="flex:0 0 90px"><button onclick="add()">+ Add</button></div></div></div>
</main><div id="t"></div>
<script>
const $=id=>document.getElementById(id);let API=localStorage.API||'',TOK=localStorage.TOKEN||'',L=[];$('api').value=API;$('tok').value=TOK;
const toast=m=>{const t=$('t');t.textContent=m;t.style.display='block';clearTimeout(t._h);t._h=setTimeout(()=>t.style.display='none',2400)};
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
function conn(){API=$('api').value.trim().replace(/\/$/,'');TOK=$('tok').value.trim();localStorage.API=API;localStorage.TOKEN=TOK;load()}
async function call(m,u,b){const f=b instanceof FormData;const r=await fetch(API+u,{method:m,headers:f?{Authorization:'Bearer '+TOK}:{Authorization:'Bearer '+TOK,'Content-Type':'application/json'},body:f?b:b&&JSON.stringify(b)});const j=await r.json().catch(()=>({}));if(!r.ok){toast(j.error||'Error '+r.status);throw new Error(j.error)}return j}
async function load(){if(!API)return;try{L=await call('GET','/admin/category-tabs');draw()}catch(e){}}
function draw(){$('list').innerHTML='<tr><th>Order</th><th>Photo</th><th>Name</th><th>Slug</th><th>Badge</th><th>Show</th><th></th></tr>'+L.map((x,i)=>`<tr class="${x.enabled?'':'off'}">
 <td><button class="g" onclick="mv(${i},-1)">↑</button> <button class="g" onclick="mv(${i},1)">↓</button></td>
 <td><div class="pv">${x.url?`<img src="${esc(x.url)}">`:''}</div>${x.slug==='all'?'<small>auto</small>':`<input type="file" accept="image/png,image/jpeg,image/webp" style="width:140px" onchange="up(${i},this)">`}</td>
 <td><input value="${esc(x.label)}" onchange="sv(${i},{label:this.value})"></td>
 <td><input value="${esc(x.slug)}" onchange="sv(${i},{slug:this.value})"></td>
 <td><input value="${esc(x.badge)}" placeholder="—" style="width:70px" onchange="sv(${i},{badge:this.value})"></td>
 <td><input type="checkbox" style="width:auto" ${x.enabled?'checked':''} onchange="sv(${i},{enabled:this.checked})"></td>
 <td><button class="d" onclick="del(${i})">Delete</button></td></tr>`).join('')}
async function sv(i,b){try{await call('PUT','/admin/category-tabs/'+L[i].id,b);toast('Saved');load()}catch(e){}}
async function up(i,el){if(!el.files[0])return;const f=new FormData();f.append('image',el.files[0]);try{const r=await call('POST','/admin/category-tabs/upload',f);await sv(i,{image:r.path})}catch(e){}}
async function add(){try{await call('POST','/admin/category-tabs',{label:$('nl').value,slug:$('ns').value||$('nl').value,badge:$('nb').value});$('nl').value=$('ns').value=$('nb').value='';load()}catch(e){}}
async function del(i){if(!confirm('Delete '+L[i].label+'?'))return;try{await call('DELETE','/admin/category-tabs/'+L[i].id);load()}catch(e){}}
async function mv(i,d){const j=i+d;if(j<0||j>=L.length)return;[L[i],L[j]]=[L[j],L[i]];try{await call('PUT','/admin/category-tabs/order',{ids:L.map(x=>x.id)});draw()}catch(e){}}
load();
</script>
</body>
</html>
```
