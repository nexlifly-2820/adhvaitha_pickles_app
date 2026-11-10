// profile_backend.js — data for the Profile ("Royal Kitchen Diary") screen (Node + Express + PostgreSQL)
//   npm i express pg
//   app.use(express.json());
//   app.use('/api', auth, require('./profile_backend'));     // auth must set req.user = { id, isAdmin }
//
// APP
//   GET    /api/profile/me        name, phone, memberNo, memberSince, avatarUrl, defaultAddress, ordersCount, wishlistCount,
//                                  notificationsOn, diaryTitle, footerLine, appVersion
//   PUT    /api/profile/me        { name?, email?, avatarUrl?, notificationsOn? }
//   GET    /api/app/version       { latest, minSupported, storeUrl }  → for "Check for Updates"
//   DELETE /api/profile/me        deletes the account (anonymises personal data, keeps order history for accounts)
// ADMIN (dashboard)
//   GET/PUT /api/admin/profile-settings   { diaryTitle, footerLine, latestVersion, minVersion, storeUrl }
//
// TABLES (run once)
/*
ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT '';
ALTER TABLE users ADD COLUMN IF NOT EXISTS notifications_on BOOLEAN DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE TABLE IF NOT EXISTS profile_settings (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  diary_title TEXT DEFAULT 'Royal Kitchen Diary',
  footer_line TEXT DEFAULT 'Made with love in Andhra 🌶️',
  latest_version TEXT DEFAULT '1.0.0', min_version TEXT DEFAULT '1.0.0', store_url TEXT DEFAULT '');
INSERT INTO profile_settings (id) VALUES (1) ON CONFLICT DO NOTHING;
*/
// Uses: users(id, name, phone, email, created_at), addresses(user_id, line1, area, city, is_default),
//       orders(user_id), wishlist(user_id, product_id)

const express = require('express');
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const router = express.Router();
const wrap = fn => (req, res, next) => fn(req, res).catch(next);
const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

let cache = null, cacheAt = 0;
async function settings() {
  if (cache && Date.now() - cacheAt < 60000) return cache;
  const { rows: [s] } = await pool.query('SELECT * FROM profile_settings WHERE id=1');
  cache = s || {}; cacheAt = Date.now();
  return cache;
}

router.get('/profile/me', wrap(async (req, res) => {
  const uid = req.user.id;
  const [{ rows: [u] }, { rows: [addr] }, { rows: [o] }, { rows: [w] }, s] = await Promise.all([
    pool.query('SELECT id, name, phone, email, avatar_url, notifications_on, created_at FROM users WHERE id=$1 AND deleted_at IS NULL', [uid]),
    pool.query(`SELECT concat_ws(', ', line1, area, city) AS a FROM addresses WHERE user_id=$1 ORDER BY is_default DESC, id DESC LIMIT 1`, [uid]).catch(() => ({ rows: [] })),
    pool.query('SELECT COUNT(*)::int n FROM orders WHERE user_id=$1', [uid]).catch(() => ({ rows: [{ n: 0 }] })),
    pool.query('SELECT COUNT(*)::int n FROM wishlist WHERE user_id=$1', [uid]).catch(() => ({ rows: [{ n: 0 }] })),
    settings(),
  ]);
  if (!u) return res.status(404).json({ error: 'Account not found' });
  const d = new Date(u.created_at);
  res.json({
    name: u.name || 'Guest',
    phone: u.phone || '',
    email: u.email || '',
    memberNo: `AJ${String(u.id).padStart(4, '0')}`,
    memberSince: `${MONTHS[d.getMonth()]} ${d.getFullYear()}`,
    avatarUrl: u.avatar_url || '',
    defaultAddress: addr?.a || '',
    ordersCount: o.n,
    wishlistCount: w.n,
    notificationsOn: u.notifications_on !== false,
    diaryTitle: s.diary_title,
    footerLine: s.footer_line,
    appVersion: s.latest_version,
  });
}));

router.put('/profile/me', wrap(async (req, res) => {
  const b = req.body, sets = [], vals = [];
  if (b.name != null) {
    const n = String(b.name).trim();
    if (n.length < 2 || n.length > 40) return res.status(400).json({ error: 'Name should be 2–40 letters' });
    vals.push(n); sets.push(`name=$${vals.length}`);
  }
  if (b.email != null) {
    const e = String(b.email).trim().toLowerCase();
    if (e && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e)) return res.status(400).json({ error: 'Enter a valid email' });
    vals.push(e); sets.push(`email=$${vals.length}`);
  }
  if (b.avatarUrl != null) {
    const a = String(b.avatarUrl);
    if (a && !/^https?:\/\//.test(a)) return res.status(400).json({ error: 'Invalid photo URL' });
    vals.push(a); sets.push(`avatar_url=$${vals.length}`);
  }
  if (b.notificationsOn != null) { vals.push(!!b.notificationsOn); sets.push(`notifications_on=$${vals.length}`); }
  if (!sets.length) return res.status(400).json({ error: 'Nothing to update' });
  vals.push(req.user.id);
  await pool.query(`UPDATE users SET ${sets.join(', ')} WHERE id=$${vals.length}`, vals);
  res.json({ ok: true });
}));

router.get('/app/version', wrap(async (req, res) => {
  const s = await settings();
  res.json({ latest: s.latest_version, minSupported: s.min_version, storeUrl: s.store_url });
}));

router.delete('/profile/me', wrap(async (req, res) => {
  const uid = req.user.id;
  const c = await pool.connect();
  try {
    await c.query('BEGIN');
    await c.query('DELETE FROM wishlist WHERE user_id=$1', [uid]).catch(() => {});
    await c.query('DELETE FROM addresses WHERE user_id=$1', [uid]).catch(() => {});
    await c.query(`UPDATE users SET name='Deleted user', phone=NULL, email=NULL, avatar_url='', notifications_on=FALSE, deleted_at=NOW() WHERE id=$1`, [uid]);
    await c.query('COMMIT');
  } catch (e) { await c.query('ROLLBACK'); throw e; } finally { c.release(); }
  res.json({ ok: true });
}));

// ---------------- ADMIN ----------------
const admin = (req, res, next) => (req.user?.isAdmin ? next() : res.status(403).json({ error: 'Admins only' }));
const VER = /^\d+\.\d+\.\d+$/;

router.get('/admin/profile-settings', admin, wrap(async (req, res) => {
  const s = await settings();
  res.json({ diaryTitle: s.diary_title, footerLine: s.footer_line, latestVersion: s.latest_version, minVersion: s.min_version, storeUrl: s.store_url });
}));

router.put('/admin/profile-settings', admin, wrap(async (req, res) => {
  const b = req.body;
  if (b.latestVersion && !VER.test(b.latestVersion)) return res.status(400).json({ error: 'latestVersion must look like 2.4.0' });
  if (b.minVersion && !VER.test(b.minVersion)) return res.status(400).json({ error: 'minVersion must look like 2.0.0' });
  if (b.diaryTitle != null && (String(b.diaryTitle).length < 3 || String(b.diaryTitle).length > 30)) return res.status(400).json({ error: 'Title should be 3–30 characters' });
  await pool.query(`UPDATE profile_settings SET
      diary_title=COALESCE($1, diary_title), footer_line=COALESCE($2, footer_line),
      latest_version=COALESCE($3, latest_version), min_version=COALESCE($4, min_version), store_url=COALESCE($5, store_url) WHERE id=1`,
    [b.diaryTitle ?? null, b.footerLine ?? null, b.latestVersion ?? null, b.minVersion ?? null, b.storeUrl ?? null]);
  cache = null;
  res.json({ ok: true });
}));

router.use((e, req, res, next) => { console.error(e); res.status(500).json({ error: 'Something went wrong' }); });
module.exports = router;
