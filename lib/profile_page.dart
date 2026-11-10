// profile_screen.dart — Profile page (matches profile_professional.mp4)
// Data: profile_backend.js → GET /api/profile/me   (texts, membership, feature blocks are managed in admin_profile.html)

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

const Color _bg = Color(0xFFFBF6EF);
const Color _ink = Color(0xFF2A1A14);
const Color _muted = Color(0xFF8A7464);
const Color _faint = Color(0xFF9A8878);
const Color _line = Color(0xFFEADFD2);
const Color _maroon = Color(0xFF7A1426);
const Color _rose = Color(0xFFA0506A);

class _Fav {
  final String id, name, image;
  final int times;
  _Fav(this.id, this.name, this.image, this.times);
}

class _Block {
  final bool maroon;
  final String label, title, button, action, image;
  _Block(this.maroon, this.label, this.title, this.button, this.action, this.image);
}

class ProfilePage extends ProfileScreen {
  const ProfilePage({
    super.key,
    super.apiBase = 'https://admin.adhvaithafoods.in/api',
    super.headers,
    super.onOpen,
    super.onLogout,
    super.onDeleted,
  });
}

class ProfileScreen extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final ValueChanged<String>? onOpen;
  final VoidCallback? onLogout, onDeleted;
  const ProfileScreen({super.key, required this.apiBase, this.headers, this.onOpen, this.onLogout, this.onDeleted});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  String _name = '', _phone = '', _address = '', _since = '', _avatar = '', _greeting = 'Namaskaram', _footer = '', _version = '';
  int _orders = 0, _wish = 0;
  bool _notif = true, _memOn = false;
  String _memTitle = '', _tier = '', _nextTier = '';
  int _points = 0, _nextPoints = 0;
  List<_Fav> _favs = <_Fav>[];
  List<_Block> _blocks = <_Block>[];
  late AnimationController _intro; // reveal + count-up + progress
  late AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 4500))..repeat();
    _load();
  }

  @override
  void dispose() {
    _intro.dispose();
    _shine.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final fallbackJson = <String, dynamic>{
      "name": "Hemanth Silva",
      "phone": "+91 98765 43210",
      "defaultAddress": "HSR Layout, Bengaluru",
      "memberSince": "2024",
      "avatarUrl": "",
      "greeting": "Namaskaram 👋",
      "footerLine": "Taste Tradition Every Day",
      "appVersion": "2.0.4",
      "ordersCount": 18,
      "wishlistCount": 12,
      "notificationsOn": true,
      "membership": {
        "enabled": true,
        "title": "Royal Kitchen Club",
        "tier": "Gold",
        "nextTier": "Platinum",
        "points": 1450,
        "nextPoints": 2000
      },
      "favourites": [
        {"productId": "avakaya", "name": "Bellam Avakaya", "image": "assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg", "times": 5},
        {"productId": "karam_podi", "name": "Idli Karam Podi", "image": "assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg", "times": 4},
        {"productId": "murukku", "name": "Kara Murukku", "image": "assets/images/karam_janthukalu_murukku_strings_snack.jpg", "times": 3}
      ],
      "blocks": [
        {"kind": "maroon", "label": "ROYAL KITCHEN", "title": "Traditional Andhra Pickles & Podis", "button": "Explore Shop", "action": "shop", "image": "assets/images/avakaya_pickle.png"},
        {"kind": "gold", "label": "AMMA'S COMBO", "title": "Build Your Kraft Box & Save Big", "button": "Build Box", "action": "combo", "image": "assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg"}
      ]
    };

    void parseAndApply(Map<String, dynamic> j) {
      final Map<String, dynamic> m = (j['membership'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      int n(dynamic v) => (v is num) ? v.toInt() : (int.tryParse('$v') ?? 0);
      if (mounted) {
        setState(() {
          _name = '${j['name'] ?? ''}';
          _phone = '${j['phone'] ?? ''}';
          _address = '${j['defaultAddress'] ?? ''}';
          _since = '${j['memberSince'] ?? ''}';
          _avatar = '${j['avatarUrl'] ?? ''}';
          _greeting = '${j['greeting'] ?? 'Namaskaram'}';
          _footer = '${j['footerLine'] ?? ''}';
          _version = '${j['appVersion'] ?? ''}';
          _orders = n(j['ordersCount']);
          _wish = n(j['wishlistCount']);
          _notif = j['notificationsOn'] != false;
          _memOn = m['enabled'] == true;
          _memTitle = '${m['title'] ?? ''}';
          _tier = '${m['tier'] ?? ''}';
          _nextTier = '${m['nextTier'] ?? ''}';
          _points = n(m['points']);
          _nextPoints = n(m['nextPoints']);
          _favs = ((j['favourites'] as List?) ?? <dynamic>[]).map((dynamic e) {
            final Map<String, dynamic> x = e as Map<String, dynamic>;
            return _Fav('${x['productId']}', '${x['name'] ?? ''}', '${x['image'] ?? ''}', n(x['times']));
          }).toList();
          _blocks = ((j['blocks'] as List?) ?? <dynamic>[]).map((dynamic e) {
            final Map<String, dynamic> x = e as Map<String, dynamic>;
            return _Block(x['kind'] == 'maroon', '${x['label'] ?? ''}', '${x['title'] ?? ''}', '${x['button'] ?? 'Open'}', '${x['action'] ?? ''}', '${x['image'] ?? ''}');
          }).toList();
          _loading = false;
        });
        _intro.forward(from: 0);
      }
    }

    parseAndApply(fallbackJson);

    try {
      final http.Response r = await http.get(Uri.parse('${widget.apiBase}/profile/me'), headers: widget.headers).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (r.statusCode == 200 && !r.body.trim().startsWith('<!DOCTYPE') && !r.body.trim().startsWith('<html')) {
        final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
        parseAndApply(j);
      }
    } catch (_) {}
  }

  void _open(String k) {
    HapticFeedback.selectionClick();
    widget.onOpen?.call(k);
  }

  Future<void> _toggleNotif() async {
    final bool v = !_notif;
    setState(() => _notif = v);
    try {
      final http.Response r = await http.put(Uri.parse('${widget.apiBase}/profile/me'),
          headers: <String, String>{'Content-Type': 'application/json', ...?widget.headers}, body: jsonEncode(<String, dynamic>{'notificationsOn': v}));
      if (!mounted) return;
      if (r.statusCode != 200) setState(() => _notif = !v);
    } catch (_) {
      if (mounted) setState(() => _notif = !v);
    }
  }

  Future<void> _logout() async {
    final bool? ok = await _confirm('Log out?', 'You can log back in anytime with your phone number.', 'Log out');
    if (ok == true) widget.onLogout?.call();
  }

  Future<void> _delete() async {
    final bool? ok = await _confirm('Delete account?', 'Your profile, addresses and wishlist will be removed permanently. This cannot be undone.', 'Delete');
    if (ok != true) return;
    try {
      final http.Response r = await http.delete(Uri.parse('${widget.apiBase}/profile/me'), headers: widget.headers);
      if (!mounted) return;
      if (r.statusCode == 200) {
        widget.onDeleted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete the account. Please try again.')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No internet connection.')));
    }
  }

  Future<bool?> _confirm(String title, String body, String yes) => showDialog<bool>(
        context: context,
        builder: (BuildContext c) => AlertDialog(
          backgroundColor: _bg,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          title: Text(title, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700, color: _ink)),
          content: Text(body, style: GoogleFonts.poppins(fontSize: 13, color: _muted)),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text('Cancel', style: GoogleFonts.poppins(color: _muted))),
            TextButton(onPressed: () => Navigator.pop(c, true), child: Text(yes, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: _maroon))),
          ],
        ),
      );

  Widget _rv(int i, Widget child) {
    return AnimatedBuilder(
      animation: _intro,
      builder: (BuildContext c, Widget? ch) {
        final double t = ((_intro.value * 1800 - i * 90) / 600).clamp(0.0, 1.0);
        final double e = Curves.easeOutCubic.transform(t);
        return Opacity(opacity: e, child: Transform.translate(offset: Offset(0, 14 * (1 - e)), child: ch));
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _maroon))
            : _error != null
                ? Center(child: GestureDetector(onTap: _load, child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: _ink)))))
                : RefreshIndicator(
                    color: _maroon,
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(28, 14, 28, 40),
                      children: _content(),
                    ),
                  ),
      ),
    );
  }

  List<Widget> _content() {
    int i = 0;
    final List<Widget> w = <Widget>[
      _rv(i++, Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
        _iconBtn(Icons.arrow_back_rounded, () => Navigator.maybePop(context)),
        _iconBtn(Icons.settings_outlined, () => _open('settings')),
      ])),
      const SizedBox(height: 26),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            _rv(i++, Text(_greeting, style: GoogleFonts.playfairDisplay(fontSize: 22, color: _rose))),
            const SizedBox(height: 4),
            _rv(i++, Text(_name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 29, height: 1.1, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: _ink))),
            const SizedBox(height: 10),
            _rv(i++, Text(<String>[_phone, _address, if (_since.isNotEmpty) 'member since $_since'].where((String s) => s.isNotEmpty).join('\n'),
                style: GoogleFonts.poppins(fontSize: 13.5, height: 1.75, color: _muted))),
            const SizedBox(height: 14),
            _rv(
                i++,
                GestureDetector(
                  onTap: () => _open('edit'),
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFD9B9A8)))),
                    child: Text('edit profile  →', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: _maroon)),
                  ),
                )),
          ]),
        ),
        const SizedBox(width: 12),
        Padding(padding: const EdgeInsets.only(top: 18), child: _rv(i++, _avatarW())),
      ]),
      if (_memOn) ...<Widget>[const SizedBox(height: 26), _rv(i++, _memberCard())],
      const SizedBox(height: 22),
      _rv(i++, _stats()),
    ];
    if (_favs.isNotEmpty) {
      w.addAll(<Widget>[
        const SizedBox(height: 32),
        _rv(i++, _cap('YOUR FAVOURITES')),
        _rv(
            i++,
            SizedBox(
              height: 142,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _favs.length,
                separatorBuilder: (BuildContext c, int k) => const SizedBox(width: 12),
                itemBuilder: (BuildContext c, int k) => _favCard(_favs[k]),
              ),
            )),
      ]);
    }
    if (_blocks.isNotEmpty) {
      w.addAll(<Widget>[
        const SizedBox(height: 30),
        _rv(i++, _cap('YOUR KITCHEN')),
        _rv(
            i++,
            SizedBox(
              height: 290,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _blocks.length,
                separatorBuilder: (BuildContext c, int k) => const SizedBox(width: 12),
                itemBuilder: (BuildContext c, int k) => _blockW(_blocks[k]),
              ),
            )),
      ]);
    }
    w.addAll(<Widget>[
      const SizedBox(height: 34),
      _rv(i++, _cap('ACCOUNT')),
      _rv(
          i++,
          _list(<Widget>[
            _row(Icons.credit_card_outlined, 'Payment methods', 'UPI, cards & wallets', () => _open('payments')),
            _row(Icons.notifications_none_rounded, 'Notifications', 'offers & order updates', _toggleNotif, trailing: _tag(_notif ? 'ON' : 'OFF', _notif)),
            _row(Icons.chat_bubble_outline_rounded, 'Contact us', 'we reply within a few hours', () => _open('contact')),
            _row(Icons.help_outline_rounded, 'Help centre', 'answers to common questions', () => _open('help')),
            _row(Icons.menu_book_outlined, 'Our story', 'three generations of pickles', () => _open('story')),
          ])),
      const SizedBox(height: 30),
      _rv(i++, _cap('LEGAL')),
      _rv(
          i++,
          _list(<Widget>[
            _row(Icons.shield_outlined, 'Privacy policy', '', () => _open('privacy')),
            _row(Icons.description_outlined, 'Terms of service', '', () => _open('terms')),
            _row(Icons.replay_rounded, 'Refunds & returns', '', () => _open('refunds')),
            _row(Icons.delete_outline_rounded, 'Delete account', '', _delete, danger: true),
          ])),
      const SizedBox(height: 30),
      _rv(
          i++,
          GestureDetector(
            onTap: _logout,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD9C6B4))),
              child: Text('LOG OUT', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 2, color: _maroon)),
            ),
          )),
      const SizedBox(height: 28),
      Center(
        child: Column(children: <Widget>[
          Text(_footer.toLowerCase(), style: GoogleFonts.poppins(fontSize: 11, letterSpacing: 2, color: const Color(0xFFB4A08E))),
          const SizedBox(height: 4),
          Text('AMBHUJAKSHI${_version.isEmpty ? '' : ' · v$_version'}', style: GoogleFonts.poppins(fontSize: 11, letterSpacing: 2, color: _muted)),
        ]),
      ),
    ]);
    return w;
  }

  Widget _iconBtn(IconData i, VoidCallback onTap) =>
      GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: Padding(padding: const EdgeInsets.all(4), child: Icon(i, size: 23, color: _ink)));

  Widget _avatarW() {
    final String letter = _name.isEmpty ? 'A' : _name.trim()[0].toUpperCase();
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: _bg, boxShadow: <BoxShadow>[BoxShadow(color: Color(0xFFE5D3BF), spreadRadius: 7), BoxShadow(color: _bg, spreadRadius: 6)]),
      child: ClipOval(
        child: _avatar.isNotEmpty
            ? Image.network(_avatar, fit: BoxFit.cover, errorBuilder: (BuildContext c, Object e, StackTrace? s) => _letter(letter))
            : _letter(letter),
      ),
    );
  }

  Widget _letter(String l) => Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFFE9B949), Color(0xFFB8862F)])),
        child: Text(l, style: GoogleFonts.playfairDisplay(fontSize: 32, color: const Color(0xFF3A2208))),
      );

  Widget _memberCard() {
    final double prog = _nextPoints > 0 ? (_points / _nextPoints).clamp(0.0, 1.0) : 1.0;
    return GestureDetector(
      onTap: () => _open('membership'),
      child: Container(
        height: 178,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          gradient: RadialGradient(center: Alignment.topRight, radius: 1.4, colors: <Color>[Color(0xFF9E2438), Color(0xFF6E1426), Color(0xFF4A0C18)], stops: <double>[0.0, 0.45, 1.0]),
          boxShadow: <BoxShadow>[BoxShadow(color: Color(0xB36E1426), blurRadius: 30, offset: Offset(0, 18), spreadRadius: -18)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(children: <Widget>[
            const Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _shine,
                builder: (BuildContext c, Widget? ch) {
                  final double t = (_shine.value / 0.55).clamp(0.0, 1.0);
                  return FractionalTranslation(translation: Offset(-1.2 + 2.6 * t, 0), child: ch);
                },
                child: Transform(
                  transform: Matrix4.skewX(-0.35),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(width: 70, decoration: const BoxDecoration(gradient: LinearGradient(colors: <Color>[Color(0x00FFECBE), Color(0x40FFECBE), Color(0x00FFECBE)]))),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Row(children: <Widget>[
                  Expanded(child: Text(_memTitle.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 3, color: const Color(0xFFE9C46A)))),
                  Container(
                    width: 34,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFFF6D78A), Color(0xFFB8862F)]),
                      border: Border.all(color: const Color(0x66FFFFFF)),
                    ),
                  ),
                ]),
                Text('$_tier Member', style: GoogleFonts.playfairDisplay(fontSize: 24, color: const Color(0xFFFFF3DC))),
                const Spacer(),
                Row(children: <Widget>[
                  Expanded(child: Text(_nextPoints > 0 ? '${_fmt(_points)} / ${_fmt(_nextPoints)} pts' : '${_fmt(_points)} pts', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFE8C9B6)))),
                  Text(_nextTier.isNotEmpty ? '${_fmt(math.max(0, _nextPoints - _points))} pts to $_nextTier' : 'Top tier reached ✨',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFFFF3DC))),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: Stack(children: <Widget>[
                      Container(color: const Color(0x26FFFFFF)),
                      AnimatedBuilder(
                        animation: _intro,
                        builder: (BuildContext c, Widget? ch) => FractionallySizedBox(
                          widthFactor: prog * Curves.easeOutCubic.transform(((_intro.value - 0.25) / 0.75).clamp(0.0, 1.0)),
                          child: ch,
                        ),
                        child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: <Color>[Color(0xFFE9C46A), Color(0xFFFFF0C2)]))),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _fmt(int v) {
    final String s = v.toString();
    if (s.length <= 3) return s;
    final String last = s.substring(s.length - 3);
    String rest = s.substring(0, s.length - 3);
    final List<String> parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last';
  }

  Widget _stats() {
    Widget cell(String l, int v, bool left) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(border: left ? null : const Border(left: BorderSide(color: _line))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(l, style: GoogleFonts.poppins(fontSize: 11, letterSpacing: 0.4, color: _faint)),
              const SizedBox(height: 4),
              AnimatedBuilder(
                animation: _intro,
                builder: (BuildContext c, Widget? ch) {
                  final double t = Curves.easeOutCubic.transform(((_intro.value - 0.2) / 0.5).clamp(0.0, 1.0));
                  return Text('${(v * t).round()}', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600, color: _ink));
                },
              ),
            ]),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line)),
      child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[cell('orders placed', _orders, true), cell('in wishlist', _wish, false)])),
    );
  }

  Widget _cap(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(t, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 4, color: const Color(0xFF9A8270))),
      );

  Widget _img(String url, double w) {
    final Widget err = SizedBox(width: w, height: w * 0.75);
    if (url.isEmpty) return err;
    return Image.network(url, width: w, fit: BoxFit.contain, errorBuilder: (BuildContext c, Object e, StackTrace? s) => err);
  }

  Widget _favCard(_Fav f) => GestureDetector(
        onTap: () => _open('product:${f.id}'),
        child: SizedBox(
          width: 104,
          child: Column(children: <Widget>[
            Container(
              width: 104,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEFE4D6))),
              child: _img(f.image, 84),
            ),
            const SizedBox(height: 8),
            Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: _ink)),
            Text('ordered ${f.times}×', style: GoogleFonts.poppins(fontSize: 10.5, color: _faint)),
          ]),
        ),
      );

  Widget _blockW(_Block b) {
    final Color bg = b.maroon ? const Color(0xFF6E1A2A) : const Color(0xFFE2B547);
    final Color fg = b.maroon ? Colors.white : const Color(0xFF1A1205);
    final Color lab = b.maroon ? const Color(0xFFE8B7A0) : const Color(0xFF5A4512);
    return GestureDetector(
      onTap: () => _open(b.action),
      child: Container(
        width: 250,
        color: bg,
        child: Stack(clipBehavior: Clip.hardEdge, children: <Widget>[
          if (b.image.isNotEmpty) Positioned(right: -34, bottom: 58, width: 140, child: _img(b.image, 140)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(b.label, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: lab)),
              const SizedBox(height: 10),
              SizedBox(width: 200, child: Text(b.title, maxLines: 4, style: GoogleFonts.playfairDisplay(fontSize: 23, height: 1.18, color: fg))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: b.maroon ? Colors.white : const Color(0xFF141414),
                child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Text(b.button, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: b.maroon ? const Color(0xFF141414) : Colors.white)),
                  const SizedBox(width: 14),
                  Icon(Icons.arrow_forward_rounded, size: 16, color: b.maroon ? const Color(0xFF141414) : Colors.white),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _list(List<Widget> rows) => Container(decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))), child: Column(children: rows));

  Widget _row(IconData icon, String title, String sub, VoidCallback onTap, {Widget? trailing, bool danger = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0E6DA)))),
        child: Row(children: <Widget>[
          Icon(icon, size: 21, color: danger ? const Color(0xFFC0392B) : const Color(0xFF7A5A48)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(title, style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w500, color: danger ? const Color(0xFFC0392B) : _ink)),
              if (sub.isNotEmpty) Text(sub, style: GoogleFonts.poppins(fontSize: 12, color: _faint)),
            ]),
          ),
          trailing ?? const Text('›', style: TextStyle(fontSize: 20, color: Color(0xFFC4B2A2))),
        ]),
      ),
    );
  }

  Widget _tag(String t, bool on) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: on ? const Color(0xFFFBEDEA) : Colors.white, border: Border.all(color: on ? const Color(0xFFE2C2B8) : _line)),
        child: Text(t, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 1, color: on ? _maroon : _faint)),
      );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    for (double x = 6; x < size.width; x += 12) {
      final double a = ((x / size.width) - 0.4).clamp(0.0, 0.6) / 0.6;
      if (a <= 0) continue;
      final Paint p = Paint()..color = Color.fromRGBO(242, 196, 107, 0.13 * a);
      for (double y = 6; y < size.height; y += 12) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
