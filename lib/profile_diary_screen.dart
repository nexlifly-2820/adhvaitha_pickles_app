// profile_diary_screen.dart — AmbhuJakshi Profile ("Royal Kitchen Diary", matches profile_diary.mp4)
// Diary cover swings open → inside page (photo, name, phone, member since, address, handwritten signature),
// Orders / Wishlist counters, 4 colourful account tiles, Help & Support list, Legal & App list, Logout, footer.
// Data: profile_backend.js → GET /api/profile/me
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1
//
// Usage (as the Profile tab):
//   ProfileDiaryScreen(
//     apiBase: 'https://your-api.com/api',
//     headers: {'Authorization': 'Bearer $token'},
//     logoAsset: 'assets/logo_full.png',
//     onOpen: (key) { switch (key) {            // keys: edit_profile, addresses, coupons, payments, contact, faq,
//       case 'edit_profile': Navigator.pushNamed(context, '/edit-profile'); break;   // story, privacy, terms, refund,
//       // ...                                                                       // orders, wishlist, settings
//     }},
//     onCheckUpdate: () => checkForUpdate(),     // e.g. in_app_update / open store
//     onLogout: () => auth.logout(),
//     onDeleteAccount: () => auth.deleteAccountFlow(),
//   )

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

const _maroon = Color(0xFF6A1220), _ink = Color(0xFF2A1A12), _bg = Color(0xFFFBF6EF), _faint = Color(0xFFA88B68), _muted = Color(0xFF9A8670);

class ProfileDiaryScreen extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final String logoAsset;
  final ValueChanged<String>? onOpen;
  final VoidCallback? onCheckUpdate, onLogout, onDeleteAccount;
  const ProfileDiaryScreen({super.key, required this.apiBase, this.headers, this.logoAsset = 'assets/logo_full.png',
      this.onOpen, this.onCheckUpdate, this.onLogout, this.onDeleteAccount});
  @override
  State<ProfileDiaryScreen> createState() => _ProfileDiaryScreenState();
}

class _ProfileDiaryScreenState extends State<ProfileDiaryScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _me;
  // 0-1.2s cover opens, 1.2-2.4 rows appear, 2.4-4 signature writes, tiles pop after
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 4600));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await http.get(Uri.parse('${widget.apiBase}/profile/me'), headers: widget.headers);
      if (!mounted) return;
      setState(() => _me = jsonDecode(r.body));
      _intro.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() => _me = {});
    }
  }

  Future<void> _toggleNotif(bool v) async {
    setState(() => _me!['notificationsOn'] = v);
    await http.put(Uri.parse('${widget.apiBase}/profile/me'),
        headers: {...?widget.headers, 'Content-Type': 'application/json'}, body: jsonEncode({'notificationsOn': v}));
  }

  @override
  void dispose() { _intro.dispose(); super.dispose(); }

  Animation<double> _iv(double a, double b, [Curve c = Curves.easeOutCubic]) => CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: c));

  @override
  Widget build(BuildContext context) {
    final me = _me;
    if (me == null) return const ColoredBox(color: _bg, child: Center(child: CircularProgressIndicator(color: _maroon)));
    return ColoredBox(
      color: _bg,
      child: RefreshIndicator(
        color: _maroon,
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 120), children: [
          Row(children: [
            Text('My Profile', style: GoogleFonts.rozhaOne(fontSize: 24, color: _maroon)),
            const Spacer(),
            _sq(const Icon(Icons.settings_rounded, size: 19, color: _ink), () => widget.onOpen?.call('settings')),
          ]),
          const SizedBox(height: 12),
          _Diary(me: me, intro: _intro, logoAsset: widget.logoAsset, onEdit: () => widget.onOpen?.call('edit_profile')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _stat('Orders', me['ordersCount'] ?? 0, Icons.inventory_2_rounded, const [Color(0xFFFF6B8A), Color(0xFFC2185B)], 'orders')),
            const SizedBox(width: 12),
            Expanded(child: _stat('Wishlist', me['wishlistCount'] ?? 0, Icons.favorite_rounded, const [Color(0xFF34C9B5), Color(0xFF1E7A46)], 'wishlist')),
          ]),
          _head('MY ACCOUNT'),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.42,
            children: [
              _tile(0, '👤', 'Edit Profile', 'Name, phone, email', const [Color(0xFFFF7A59), Color(0xFFE8486B)], 'edit_profile'),
              _tile(1, '📍', 'Saved Addresses', 'Manage delivery', const [Color(0xFF2BB3A3), Color(0xFF1B7F8C)], 'addresses'),
              _tile(2, '🎁', 'Coupons & Offers', 'View & apply offers', const [Color(0xFFF7B733), Color(0xFFE07B12)], 'coupons'),
              _tile(3, '💳', 'Payment Methods', 'UPI, cards & wallets', const [Color(0xFF8B5CF6), Color(0xFF5B2FD0)], 'payments'),
            ],
          ),
          _head('HELP & SUPPORT'),
          _list([
            _item('💬', 'Contact Us', 'Get in touch with our team', const [Color(0xFF34C9B5), Color(0xFF1E7A46)], () => widget.onOpen?.call('contact')),
            _item('❓', 'Help Center (FAQ)', 'Answers to common questions', const [Color(0xFF4FA3F7), Color(0xFF1E4F8F)], () => widget.onOpen?.call('faq')),
            _item('📜', 'Our Story', 'Know more about our journey', const [Color(0xFFF7B733), Color(0xFFE07B12)], () => widget.onOpen?.call('story')),
            _item('🔔', 'Notifications', 'Offers & order updates', const [Color(0xFFFF6B8A), Color(0xFFC2185B)], null,
                trailing: Switch.adaptive(value: me['notificationsOn'] ?? true, activeColor: const Color(0xFF1E7A46), onChanged: _toggleNotif)),
          ]),
          _head('LEGAL & APP'),
          _list([
            _item('🛡️', 'Privacy Policy', 'How we protect your data', const [Color(0xFFA47BFF), Color(0xFF5B2FD0)], () => widget.onOpen?.call('privacy')),
            _item('📄', 'Terms of Service', 'Terms of using the app', const [Color(0xFFB89A78), Color(0xFF7A5A44)], () => widget.onOpen?.call('terms')),
            _item('↩️', 'Refund & Returns', 'Cancellation & refund policy', const [Color(0xFF34C9B5), Color(0xFF1B7F8C)], () => widget.onOpen?.call('refund')),
            _item('⬆️', 'Check for Updates', 'Ensure you have the latest version', const [Color(0xFF4FA3F7), Color(0xFF1E4F8F)], widget.onCheckUpdate),
            _item('🗑️', 'Delete Account', 'Permanently remove your data', const [Color(0xFFFF6B6B), Color(0xFFC62828)], _confirmDelete, danger: true),
          ]),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _confirmLogout,
            child: Container(
              height: 54, alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFFFF5F6), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF2C4CB), width: 1.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFC62828)),
                const SizedBox(width: 8),
                Text('Logout', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFC62828))),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Center(child: Text(me['footerLine'] ?? 'Made with love in Andhra 🌶️', style: GoogleFonts.kalam(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF8A7660)))),
          const SizedBox(height: 6),
          Center(child: Text('CRAFTED BY', style: GoogleFonts.poppins(fontSize: 9.5, letterSpacing: 2, color: const Color(0xFFB8A58A)))),
          Center(child: Text('NEXLIFY', style: GoogleFonts.rozhaOne(fontSize: 14, letterSpacing: 4, color: const Color(0xFF9E1424)))),
          if ((me['appVersion'] ?? '').toString().isNotEmpty)
            Center(child: Text('v${me['appVersion']}', style: GoogleFonts.poppins(fontSize: 9.5, color: const Color(0xFFC9B4A0)))),
        ]),
      ),
    );
  }

  Widget _sq(Widget c, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 38, height: 38, alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 10, offset: const Offset(0, 4), spreadRadius: -6)]), child: c));

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 24, 0, 12),
        child: Row(children: [
          Text(t, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: const Color(0xFF9A7B58))),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1.5, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFEAD9BF), Colors.transparent])))),
        ]),
      );

  Widget _pop(double start, Widget child) => AnimatedBuilder(
        animation: _intro,
        builder: (_, c) {
          final v = _iv(start, math.min(1, start + .13), Curves.easeOutBack).value;
          return Opacity(opacity: v.clamp(0, 1), child: Transform.scale(scale: .6 + .4 * v, child: c));
        },
        child: child,
      );

  Widget _stat(String label, int n, IconData icon, List<Color> g, String key) => _pop(.28, GestureDetector(
        onTap: () => widget.onOpen?.call(key),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: LinearGradient(colors: g, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: g.last.withOpacity(.6), blurRadius: 20, offset: const Offset(0, 12), spreadRadius: -14)]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: n.toDouble()), duration: const Duration(milliseconds: 1300), curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text('${v.round()}', style: GoogleFonts.rozhaOne(fontSize: 30, height: 1, color: Colors.white)),
              ),
              Text(label, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
            const Spacer(),
            Icon(icon, color: Colors.white.withOpacity(.9), size: 20),
          ]),
        ),
      ));

  Widget _tile(int i, String emoji, String title, String sub, List<Color> g, String key) => _pop(.62 + i * .06, _Pressable(
        onTap: () => widget.onOpen?.call(key),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(gradient: LinearGradient(colors: g, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: g.last.withOpacity(.55), blurRadius: 22, offset: const Offset(0, 14), spreadRadius: -16)]),
          child: Stack(children: [
            Positioned(right: -26, top: -26, child: Container(width: 90, height: 90, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.16)))),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 42, height: 42, alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.95), borderRadius: BorderRadius.circular(14)),
                    child: Text(emoji, style: const TextStyle(fontSize: 21))),
                const Spacer(),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(.9))),
              ]),
            ),
          ]),
        ),
      ));

  Widget _list(List<Widget> items) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF501E00).withOpacity(.12), blurRadius: 26, offset: const Offset(0, 14), spreadRadius: -16)]),
        child: Column(children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1) const Divider(height: 1, color: Color(0xFFF3EADB)),
          ],
        ]),
      );

  Widget _item(String emoji, String title, String sub, List<Color> g, VoidCallback? onTap, {Widget? trailing, bool danger = false}) => InkWell(
        onTap: onTap == null ? null : () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            Container(width: 40, height: 40, alignment: Alignment.center,
                decoration: BoxDecoration(gradient: LinearGradient(colors: g, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(13)),
                child: Text(emoji, style: const TextStyle(fontSize: 18))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: danger ? const Color(0xFFC62828) : _ink)),
              Text(sub, style: GoogleFonts.poppins(fontSize: 11, color: _muted)),
            ])),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFFC9B4A0)),
          ]),
        ),
      );

  Future<bool> _ask(String title, String msg, String yes) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(title, style: GoogleFonts.rozhaOne(fontSize: 22, color: _maroon)),
          content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: GoogleFonts.poppins(color: _muted))),
            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(yes, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFFC62828)))),
          ],
        ),
      ) ??
      false;

  Future<void> _confirmLogout() async {
    if (await _ask('Logout?', 'You can log back in anytime with your phone number.', 'Logout')) widget.onLogout?.call();
  }

  Future<void> _confirmDelete() async {
    if (await _ask('Delete account?', 'Your profile, addresses and wishlist will be permanently removed. This cannot be undone.', 'Delete')) {
      widget.onDeleteAccount?.call();
    }
  }
}

// ───────────────────────────── the diary (cover + inside page) ─────────────────────────────
class _Diary extends StatelessWidget {
  final Map<String, dynamic> me;
  final AnimationController intro;
  final String logoAsset;
  final VoidCallback onEdit;
  const _Diary({required this.me, required this.intro, required this.logoAsset, required this.onEdit});

  Animation<double> _iv(double a, double b, [Curve c = Curves.easeOutCubic]) => CurvedAnimation(parent: intro, curve: Interval(a, b, curve: c));

  @override
  Widget build(BuildContext context) {
    final open = _iv(0.05, 0.30, Curves.easeInOutCubic);
    return AnimatedBuilder(
      animation: intro,
      builder: (_, __) {
        final angle = open.value * math.pi * .92; // up to ~165°
        return Stack(children: [
          _page(),
          if (angle < math.pi / 2)
            Positioned.fill(
              child: Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()..setEntry(3, 2, .0011)..rotateY(-angle),
                child: _cover(),
              ),
            ),
        ]);
      },
    );
  }

  Widget _cover() => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20), right: Radius.circular(26)),
          gradient: const RadialGradient(center: Alignment(0, -.4), radius: 1.1, colors: [Color(0xFFA3172B), Color(0xFF5A0818)]),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 30, offset: const Offset(0, 20), spreadRadius: -16)],
        ),
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFD9A441), width: 1.5)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 90, height: 90, padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD9A441), width: 3)),
                child: ClipOval(child: Image.asset(logoAsset, fit: BoxFit.contain))),
            const SizedBox(height: 12),
            Text((me['diaryTitle'] ?? 'ROYAL KITCHEN\nDIARY').toString().toUpperCase(), textAlign: TextAlign.center,
                style: GoogleFonts.rozhaOne(fontSize: 26, height: 1.1, letterSpacing: 2, color: const Color(0xFFFFD27A),
                    shadows: const [Shadow(color: Color(0xFF3A0612), offset: Offset(0, 2))])),
            const SizedBox(height: 8),
            Text('AMBHUJAKSHI', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 5, color: const Color(0xFFFFD27A))),
          ]),
        ),
      );

  Widget _fade(double a, Widget c) {
    final v = _iv(a, a + .1).value;
    return Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: c));
  }

  Widget _field(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: _faint)),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF3A0612))),
      ]);

  Widget _page() {
    final name = (me['name'] ?? '').toString();
    final avatar = (me['avatarUrl'] ?? '').toString();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(20), right: Radius.circular(26)),
        gradient: const RadialGradient(center: Alignment(0, -1), radius: 1.3, colors: [Color(0xFFFFF8E8), Color(0xFFF6E7C8)]),
        border: const Border(left: BorderSide(color: Color(0xFFE9D3A8), width: 6)),
        boxShadow: [BoxShadow(color: const Color(0xFF5A1E00).withOpacity(.5), blurRadius: 34, offset: const Offset(0, 20), spreadRadius: -20)],
      ),
      child: CustomPaint(
        painter: _LinesPainter(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 64, height: 76, padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  gradient: const SweepGradient(colors: [Color(0xFFFFD27A), Color(0xFFE8486B), Color(0xFF8B5CF6), Color(0xFF2BB3A3), Color(0xFFFFD27A)])),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: avatar.isNotEmpty
                    ? Image.network(avatar, fit: BoxFit.cover)
                    : Container(color: const Color(0xFFFFF4DC), alignment: Alignment.center,
                        child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: GoogleFonts.rozhaOne(fontSize: 32, color: const Color(0xFF9E1424)))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MY KITCHEN DIARY · NO. ${me['memberNo'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: _faint)),
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.rozhaOne(fontSize: 24, height: 1.15, color: const Color(0xFF3A0612))),
              Text('Namaskaram 🙏', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7A5A44))),
            ])),
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors: [Color(0xFFFFE3A0), Color(0xFFE09A2C)])),
                child: Text('✎ Edit', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF3A2400))),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          CustomPaint(size: const Size(double.infinity, 2), painter: _DashH()),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _fade(.30, _field('PHONE', me['phone'] ?? '—'))),
            Expanded(child: _fade(.36, _field('MEMBER SINCE', me['memberSince'] ?? '—'))),
          ]),
          const SizedBox(height: 10),
          _fade(.42, _field('DELIVERY ADDRESS', (me['defaultAddress'] ?? '').toString().isEmpty ? 'Add your delivery address' : me['defaultAddress'])),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            ClipRect(child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: _iv(.52, .85, Curves.easeInOut).value, // handwriting reveal
              child: Text(name, style: GoogleFonts.kalam(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF1E4F8F))),
            )),
            const Spacer(),
            Text('with love from Ambhujakshi kitchen', style: GoogleFonts.poppins(fontSize: 9, fontStyle: FontStyle.italic, color: _faint)),
          ]),
        ]),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Pressable({required this.child, required this.onTap});
  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) { setState(() => _down = false); HapticFeedback.lightImpact(); widget.onTap(); },
        child: AnimatedScale(scale: _down ? .94 : 1, duration: const Duration(milliseconds: 150), child: widget.child),
      );
}

class _LinesPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFF966E3C).withOpacity(.06)..strokeWidth = 1;
    for (double y = 22; y < s.height; y += 22) { c.drawLine(Offset(0, y), Offset(s.width, y), p); }
    c.drawCircle(Offset(s.width + 20, s.height + 30), 110, Paint()..style = PaintingStyle.stroke..strokeWidth = 18..color = const Color(0xFF9E1424).withOpacity(.05));
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _DashH extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFDCC59E)..strokeWidth = 1.5;
    for (double x = 0; x < s.width; x += 8) { c.drawLine(Offset(x, 1), Offset(math.min(x + 4, s.width), 1), p); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
