# Admin Dashboard Backend Guide for Login & OTP Management

This guide provides the complete Node.js / Express backend code (`auth_backend.js`) to power the mobile app's login screen and your admin dashboard. It handles dynamic texts, OTP verification via email, and the moving wall of food photos.

---

## 1. Database Schema

Run these SQL queries in your PostgreSQL database to set up the necessary tables:

```sql
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT UNIQUE,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login_at TIMESTAMPTZ,
  is_admin BOOLEAN DEFAULT FALSE
);
CREATE UNIQUE INDEX IF NOT EXISTS users_email_lower ON users (LOWER(email));

CREATE TABLE IF NOT EXISTS login_otps (
  email TEXT PRIMARY KEY,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts INT DEFAULT 0,
  sent_count INT DEFAULT 1,
  window_start TIMESTAMPTZ DEFAULT NOW(),
  last_sent_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS login_settings (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  texts JSONB NOT NULL DEFAULT '{
    "taglineStart": "Great taste delivered at",
    "taglineAccent": "lowest rate",
    "subtitle": "Handmade in Andhra kitchens, packed with love",
    "buttonText": "Log in with email",
    "sheetTitle": "Welcome to our kitchen",
    "cardTitle": "Your kitchen details ✍️",
    "otpSheetTitle": "Almost there",
    "otpTitle": "Check your email ✉️",
    "welcomeTitle": "Namaskaram 🙏",
    "welcomeLine": "Your royal kitchen is ready",
    "welcomeBack": "Welcome back",
    "privacyUrl": "",
    "termsUrl": ""
  }',
  otp_length INT DEFAULT 6,
  resend_seconds INT DEFAULT 30,
  expiry_minutes INT DEFAULT 10,
  max_sends_per_hour INT DEFAULT 5,
  max_attempts INT DEFAULT 5,
  mail_subject TEXT DEFAULT 'Your AmbhuJakshi login code: {code}',
  mail_body TEXT DEFAULT 'Namaskaram {name},\n\nYour login code is {code}. It is valid for {minutes} minutes.\n\n— AmbhuJakshi kitchen'
);
INSERT INTO login_settings (id) VALUES (1) ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS login_wall (
  id SERIAL PRIMARY KEY,
  url TEXT NOT NULL,
  sort INT DEFAULT 0
);
```

---

## 2. Backend Router (`auth_backend.js`)

Save this file as `auth_backend.js` in your Node.js server project:

```javascript
// auth_backend.js — email-OTP login & admin manager
const express = require('express');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const multer = require('multer');
const sharp = require('sharp');
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const router = express.Router();
const wrap = fn => (req, res, next) => fn(req, res).catch(next);
const PUBLIC = (process.env.PUBLIC_URL || '').replace(/\/$/, '');
const abs = u => (!u ? '' : /^https?:\/\//.test(u) ? u : PUBLIC + (u.startsWith('/') ? u : '/' + u));
const EMAIL = /^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$/;
const TEXT_KEYS = ['taglineStart', 'taglineAccent', 'subtitle', 'buttonText', 'sheetTitle', 'cardTitle', 'otpSheetTitle',
  'otpTitle', 'welcomeTitle', 'welcomeLine', 'welcomeBack', 'privacyUrl', 'termsUrl'];

const mailer = nodemailer.createTransport({
  host: process.env.SMTP_HOST, port: +(process.env.SMTP_PORT || 587), secure: +(process.env.SMTP_PORT || 587) === 465,
  auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
});

let cache = null, cacheAt = 0;
async function settings() {
  if (cache && Date.now() - cacheAt < 60000) return cache;
  const [{ rows: [s] }, { rows: wall }] = await Promise.all([
    pool.query('SELECT * FROM login_settings WHERE id=1'),
    pool.query('SELECT id, url FROM login_wall ORDER BY sort, id'),
  ]);
  cache = { ...s, wall };
  cacheAt = Date.now();
  return cache;
}
const clear = () => { cache = null; };
const hash = (email, code) => crypto.createHmac('sha256', process.env.OTP_SECRET || 'change-me').update(`${email}:${code}`).digest('hex');
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// ---------------- PUBLIC APP ENDPOINTS ----------------
router.get('/auth/login-config', wrap(async (_, res) => {
  const s = await settings();
  res.json({
    texts: { ...s.texts, otpLength: s.otp_length, resendSeconds: s.resend_seconds },
    wall: s.wall.map(w => abs(w.url)),
  });
}));

router.post('/auth/send-otp', wrap(async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const name = String(req.body.name || '').trim().slice(0, 40);
  if (!EMAIL.test(email)) return res.status(400).json({ error: 'Please check your email ✏️' });
  const s = await settings();

  const code = String(crypto.randomInt(0, 10 ** s.otp_length)).padStart(s.otp_length, '0');
  await pool.query(
    `INSERT INTO login_otps (email, code_hash, expires_at, attempts, sent_count, window_start, last_sent_at)
     VALUES ($1,$2,NOW() + ($3 || ' minutes')::interval,0,1,NOW(),NOW())
     ON CONFLICT (email) DO UPDATE SET code_hash=EXCLUDED.code_hash, expires_at=EXCLUDED.expires_at, attempts=0, last_sent_at=NOW()`,
    [email, hash(email, code), String(s.expiry_minutes)]);

  const fill = t => t.replace(/\{code\}/g, code).replace(/\{name\}/g, name || 'there').replace(/\{minutes\}/g, s.expiry_minutes);
  const body = fill(s.mail_body);
  await mailer.sendMail({
    from: process.env.MAIL_FROM, to: email, subject: fill(s.mail_subject), text: body,
    html: `<div style="font-family:Arial,sans-serif;max-width:460px;margin:auto;padding:24px;background:#FFF8EE;border-radius:16px;color:#2A1A12">
      <h2 style="color:#6A1220;margin:0 0 12px">AmbhuJakshi</h2>
      <p style="white-space:pre-line;font-size:14px;line-height:1.5">${esc(body).replace(code, `<b>${code}</b>`)}</p>
      <div style="font-size:30px;letter-spacing:10px;font-weight:bold;color:#9E1424;background:#fff;border:1px dashed #E2CFB0;border-radius:12px;padding:14px;text-align:center">${code}</div>
    </div>`,
  });
  res.json({ ok: true, resendIn: s.resend_seconds });
}));

router.post('/auth/verify-otp', wrap(async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const code = String(req.body.code || '').trim();
  const name = String(req.body.name || '').trim().slice(0, 40);
  const s = await settings();
  const { rows: [o] } = await pool.query('SELECT * FROM login_otps WHERE email=$1', [email]);
  if (!o || new Date(o.expires_at) < new Date()) return res.status(400).json({ error: 'Please request a new code' });
  const ok = code.length === s.otp_length && crypto.timingSafeEqual(Buffer.from(hash(email, code)), Buffer.from(o.code_hash));
  if (!ok) {
    await pool.query('UPDATE login_otps SET attempts = attempts + 1 WHERE email=$1', [email]);
    return res.status(400).json({ error: 'Wrong code, please try again ✏️' });
  }
  await pool.query('DELETE FROM login_otps WHERE email=$1', [email]);

  let { rows: [u] } = await pool.query('SELECT * FROM users WHERE LOWER(email)=$1', [email]);
  if (!u) {
    ({ rows: [u] } = await pool.query('INSERT INTO users (name, email, last_login_at) VALUES ($1,$2,NOW()) RETURNING *', [name || email.split('@')[0], email]));
  } else {
    ({ rows: [u] } = await pool.query(`UPDATE users SET last_login_at=NOW(), name=COALESCE(NULLIF(name,''), $2) WHERE id=$1 RETURNING *`, [u.id, name || null]));
  }
  const token = jwt.sign({ id: u.id, isAdmin: !!u.is_admin }, process.env.JWT_SECRET, { expiresIn: '90d' });
  res.json({ token, user: { id: String(u.id), name: u.name, email: u.email } });
}));

// ---------------- ADMIN ENDPOINTS ----------------
function requireUser(req, res, next) {
  const t = (req.headers.authorization || '').replace(/^Bearer /, '');
  try { req.user = jwt.verify(t, process.env.JWT_SECRET); next(); } catch { res.status(401).json({ error: 'Please log in again' }); }
}
const admin = (req, res, next) => {
  if (!req.user) return requireUser(req, res, () => (req.user?.isAdmin ? next() : res.status(403).json({ error: 'Admins only' })));
  return req.user.isAdmin ? next() : res.status(403).json({ error: 'Admins only' });
};

router.get('/admin/login-settings', admin, wrap(async (_, res) => {
  clear();
  res.json(await settings());
}));

router.put('/admin/login-settings', admin, wrap(async (req, res) => {
  const b = req.body, s = await settings();
  const texts = { ...s.texts };
  for (const k of TEXT_KEYS) if (b.texts && k in b.texts) texts[k] = String(b.texts[k]).slice(0, 120);
  await pool.query('UPDATE login_settings SET texts=$1 WHERE id=1', [JSON.stringify(texts)]);
  clear();
  res.json({ ok: true });
}));

router.get('/admin/login-wall', admin, wrap(async (_, res) => {
  const { rows } = await pool.query('SELECT id, url, sort FROM login_wall ORDER BY sort, id');
  res.json(rows.map(r => ({ ...r, url: abs(r.url) })));
}));

fs.mkdirSync('uploads', { recursive: true });
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 12 * 1024 * 1024 } });

router.post('/admin/login-wall', admin, upload.single('photo'), wrap(async (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No photo uploaded' });
  const name = `wall_${crypto.randomBytes(8).toString('hex')}.jpg`;
  fs.writeFileSync(path.join('uploads', name), req.file.buffer);
  const { rows: [r] } = await pool.query(
    `INSERT INTO login_wall (url, sort) VALUES ($1, COALESCE((SELECT MAX(sort)+1 FROM login_wall),0)) RETURNING id, url, sort`, [`/uploads/${name}`]);
  clear();
  res.json({ ...r, url: abs(r.url) });
}));

router.delete('/admin/login-wall/:id', admin, wrap(async (req, res) => {
  await pool.query('DELETE FROM login_wall WHERE id=$1', [req.params.id]);
  clear();
  res.json({ ok: true });
}));

module.exports = router;
```

---

## 3. Integration in your Node.js Server

In your main server file (e.g., `server.js` or `app.js`):

```javascript
const express = require('express');
const app = express();

app.use(express.json());
app.use('/uploads', express.static('uploads'));
app.use('/api', require('./auth_backend'));

app.listen(3000, () => console.log('Server running on port 3000'));
```
