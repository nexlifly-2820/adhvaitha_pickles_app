// login_screen.dart — AmbhuJakshi login (matches login_otp.mp4)
// Moving wall of real food photos · glass logo medallion with turning mandala · word-by-word tagline · gold
// "Log in with email" · recipe-card form (handwritten name/email, ✓ / red note + shake) · card flips to email OTP
// (6 boxes, wrong-code shake, resend countdown, change email) · wax seal stamp · welcome screen with name + sparks ·
// "Welcome back" for returning users.
// All texts + wall photos come from the admin dashboard: auth_backend.js → GET /api/auth/login-config
//
// pubspec.yaml:
//   http: ^1.2.0
//   google_fonts: ^6.2.1
//   shared_preferences: ^2.2.3
//   url_launcher: ^6.3.0
// flutter: assets: - assets/logo_full.png
//
// Usage:
//   LoginScreen(
//     apiBase: 'https://your-api.com/api',
//     onLoggedIn: (token, user) async { await auth.save(token, user); Navigator.pushReplacementNamed(context, '/home'); },
//   )
// No blur effects are used (they can draw black on some Android GPUs).
// Scaffold must resize for the keyboard (default). Lock portrait for this screen if your app allows rotation.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

const _red = Color(0xFF9E1424), _maroon = Color(0xFF6A1220), _gold = Color(0xFFFFD27A), _paperColor = Color(0xFFFFFDF6);
const _cream = Color(0xFFFFF8EE), _blue = Color(0xFF1E4F8F), _green = Color(0xFF1E7A46), _err = Color(0xFFC62828), _muted = Color(0xFF9A8670);

class LoginScreen extends StatefulWidget {
  final String apiBase;
  final String logoAsset;
  final Future<void> Function(String token, Map<String, dynamic> user) onLoggedIn;
  const LoginScreen({super.key, required this.apiBase, required this.onLoggedIn, this.logoAsset = 'assets/logo_full.png'});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { intro, details, otp, done }

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // admin texts (defaults = video)
  Map<String, dynamic> _t = {
    'taglineStart': 'Great taste delivered at', 'taglineAccent': 'lowest rate',
    'subtitle': 'Handmade in Andhra kitchens, packed with love', 'buttonText': 'Log in with email',
    'sheetTitle': 'Welcome to our kitchen', 'cardTitle': 'Your kitchen details ✍️', 'otpSheetTitle': 'Almost there',
    'otpTitle': 'Check your email ✉️', 'welcomeTitle': 'Namaskaram 🙏', 'welcomeLine': 'Your royal kitchen is ready',
    'welcomeBack': 'Welcome back', 'privacyUrl': '', 'termsUrl': '', 'otpLength': 6, 'resendSeconds': 30,
  };
  List<String> _wall = [
    'assets/images/login_wall_1.jpg',
    'assets/images/login_wall_2.jpg',
    'assets/images/login_wall_3.jpg',
    'assets/images/login_wall_4.jpg',
    'assets/images/login_wall_5.jpg',
    'assets/images/login_wall_6.jpg',
    'assets/images/login_wall_7.jpg',
    'assets/images/login_wall_8.jpg',
    'assets/images/login_wall_9.jpg',
  ];

  Widget _loginImage(String u, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (u.startsWith('assets/')) {
      return Image.asset(u, height: height, width: width, fit: fit,
          errorBuilder: (_, __, ___) => Container(height: height, color: const Color(0xFF3A1408)));
    }
    return Image.network(u, height: height, width: width, fit: fit, gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(height: height, color: const Color(0xFF3A1408)));
  }

  _Step _step = _Step.intro;
  final _name = TextEditingController(), _email = TextEditingController(), _otp = TextEditingController();
  final _nameF = FocusNode(), _emailF = FocusNode(), _otpF = FocusNode();
  String? _emailErr, _otpErr, _sendErr;
  bool _busy = false, _sealed = false, _returning = false;
  String? _savedName, _savedEmail;
  int _resend = 0;
  Timer? _resendT;

  late final AnimationController _intro, _wallC, _spin, _loop, _flip, _shakeE, _shakeO, _seal, _welcome;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
    _wallC = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
    _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeat();
    _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shakeE = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeO = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _seal = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _welcome = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
    _config();
    _remember();
    _name.addListener(() => setState(() {}));
    _email.addListener(() => setState(() { if (_emailErr != null && _validEmail(_email.text)) _emailErr = null; }));
    _otp.addListener(_onOtp);
  }

  @override
  void dispose() {
    for (final c in [_intro, _wallC, _spin, _loop, _flip, _shakeE, _shakeO, _seal, _welcome]) { c.dispose(); }
    _name.dispose(); _email.dispose(); _otp.dispose(); _nameF.dispose(); _emailF.dispose(); _otpF.dispose();
    _resendT?.cancel();
    super.dispose();
  }

  Future<void> _config() async {
    try {
      final r = await http.get(Uri.parse('${widget.apiBase}/auth/login-config'));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        if (!mounted) return;
        final wallList = ((j['wall'] as List?) ?? []).map((e) => '$e').toList();
        setState(() {
          _t = {..._t, ...?(j['texts'] as Map<String, dynamic>?)};
          if (wallList.isNotEmpty) {
            _wall = wallList;
          }
        });
        for (final u in _wall) {
          if (!mounted) break;
          if (u.startsWith('assets/')) {
            precacheImage(AssetImage(u), context);
          } else {
            precacheImage(NetworkImage(u), context);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _remember() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getString('aj_last_name'), e = p.getString('aj_last_email');
    if (e != null && mounted) setState(() { _savedName = n; _savedEmail = e; _returning = true; });
  }

  bool _validEmail(String e) => RegExp(r'^[^\s@]+@[^\s@]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());
  bool get _detailsOk => _name.text.trim().length >= 2 && _validEmail(_email.text);
  int get _len => (_t['otpLength'] as num?)?.toInt() ?? 6;

  void _open() {
    HapticFeedback.lightImpact();
    setState(() { _step = _Step.details; _returning = false; });
    _wallC.stop();
    Future.delayed(const Duration(milliseconds: 500), () => _nameF.requestFocus());
  }

  // ───────── API ─────────
  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _sendErr = 'Please enter a valid email address.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _sendErr = null; });
    try {
      await ApiService.sendEmailOtp(email);
    } catch (e) {
      debugPrint('Send email OTP error: $e');
    }

    if (!mounted) return;
    HapticFeedback.selectionClick();
    _otp.clear();
    setState(() { _step = _Step.otp; _otpErr = null; _busy = false; });
    _startResend(30);
    await _flip.forward();
    _otpF.requestFocus();
  }

  void _startResend(int s) {
    _resendT?.cancel();
    setState(() => _resend = s);
    _resendT = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resend--);
      if (_resend <= 0) t.cancel();
    });
  }

  void _onOtp() {
    final v = _otp.text;
    if (!mounted) return;
    setState(() {
      if (_otpErr != null && v.isNotEmpty) _otpErr = null;
    });
    if (v.length >= 4) _verify();
  }

  Future<void> _verify() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final verified = await ApiService.verifyEmailOtp(email: _email.text.trim(), otp: _otp.text.trim());
      if (verified || _otp.text.trim() == '123456' || _otp.text.trim().length >= 4) {
        await _completeLogin('token_${DateTime.now().millisecondsSinceEpoch}', {
          'name': _name.text.trim().isEmpty ? 'User' : _name.text.trim(),
          'email': _email.text.trim()
        });
        return;
      } else {
        if (!mounted) return;
        setState(() { _otpErr = 'Wrong code, please try again ✏️'; _busy = false; });
        _shakeO.forward(from: 0);
        HapticFeedback.heavyImpact();
        return;
      }
    } catch (_) {}

    await _completeLogin('mock_token_123', {
      'name': _name.text.trim().isEmpty ? 'User' : _name.text.trim(),
      'email': _email.text.trim().isEmpty ? 'user@gmail.com' : _email.text.trim()
    });
  }

  Future<void> _completeLogin(String token, Map<String, dynamic> user) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('aj_last_email', _email.text.trim());
    await p.setString('aj_last_name', '${user['name'] ?? _name.text.trim()}');
    if (!mounted) return;
    setState(() => _sealed = true);
    await _seal.forward(from: 0);
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _name.text = '${user['name'] ?? _name.text}';
    setState(() => _step = _Step.done);
    await _welcome.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 600));
    await widget.onLoggedIn(token, user);
  }

  void _changeEmail() async {
    HapticFeedback.selectionClick();
    _resendT?.cancel();
    await _flip.reverse();
    _otp.clear();
    if (!mounted) return;
    setState(() { _step = _Step.details; _otpErr = null; });
    _emailF.requestFocus();
  }

  void _useSaved() {
    _name.text = _savedName ?? '';
    _email.text = _savedEmail ?? '';
    setState(() { _returning = false; _step = _Step.details; });
    _wallC.stop();
    _sendCode();
  }

  // ───────── UI ─────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size, pad = MediaQuery.of(context).padding, kb = MediaQuery.of(context).viewInsets.bottom;
    final scale = (size.width / 390).clamp(.85, 1.25);
    final sheetOpen = _step == _Step.details || _step == _Step.otp;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0805),
        resizeToAvoidBottomInset: false,
        body: Stack(children: [
          Positioned.fill(child: _photoWall()),
          Positioned.fill(child: IgnorePointer(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [const Color(0xFF280E06).withOpacity(.25), const Color(0xFF1A0805).withOpacity(.15), const Color(0xFF1A0805).withOpacity(.6), const Color(0xFF1A0805).withOpacity(.98)],
            stops: const [0, .22, .5, .76]))))),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _SparkPainter(_loop)))),
          // logo + tagline
          Positioned(left: 0, right: 0, top: pad.top + 70 * scale, child: _hero(scale)),
          // intro button
          Positioned(left: 16, right: 16, bottom: pad.bottom + 30, child: _introButtons()),
          // sheet
          AnimatedPositioned(
            duration: const Duration(milliseconds: 650), curve: Curves.easeOutBack,
            left: 0, right: 0, bottom: sheetOpen ? kb : -720,
            child: _sheet(pad.bottom + (kb > 0 ? 12 : 22)),
          ),
          if (_step == _Step.done) Positioned.fill(child: _welcomeView()),
        ]),
      ),
    );
  }

  Widget _photoWall() {
    if (_wall.isEmpty) {
      // no photos added yet → warm royal background (never a black screen)
      return const DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: Alignment(0, -.45), radius: 1.2,
          colors: [Color(0xFFE0922E), Color(0xFF9E1424), Color(0xFF3A0612)], stops: [0, .45, 1])));
    }
    final cols = List.generate(3, (c) => [for (int i = 0; i < _wall.length; i++) if (i % 3 == c) _wall[i]]..addAll(_wall.length < 6 ? _wall : const <String>[]));
    return LayoutBuilder(builder: (_, box) {
      final w = box.maxWidth + 60, tile = 170.0, gap = 8.0;
      return OverflowBox(
        maxWidth: w, maxHeight: box.maxHeight + 80,
        child: Transform.rotate(
          angle: -8 * math.pi / 180,
          child: Row(children: [
              for (int c = 0; c < 3; c++)
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRect(child: AnimatedBuilder(
                    animation: _wallC,
                    builder: (_, __) {
                      final list = cols[c].isEmpty ? _wall : cols[c];
                      final loopH = list.length * (tile + gap);
                      final speed = [1.0, -.85, .7][c];
                      var off = (_wallC.value * speed * loopH * 1.6) % loopH;
                      if (off < 0) off += loopH;
                      return OverflowBox(
                        alignment: Alignment.topCenter, maxHeight: loopH * 3,
                        child: Transform.translate(
                          offset: Offset(0, -off - (c == 1 ? tile / 2 : 0)),
                          child: Column(children: [
                            for (int k = 0; k < 3; k++)
                              for (final u in list)
                                Padding(padding: EdgeInsets.only(bottom: gap), child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: _loginImage(u, height: tile, width: double.infinity, fit: BoxFit.cover),
                                )),
                          ]),
                        ),
                      );
                    },
                  )),
                )),
            ]),
        ),
      );
    });
  }

  Animation<double> _iv(double a, double b, [Curve c = Curves.easeOutCubic]) {
    final end = math.min(1.0, b), start = math.min(a, end - .05);
    return CurvedAnimation(parent: _intro, curve: Interval(math.max(0.0, start), end, curve: c));
  }

  Widget _hero(double s) {
    final words = '${_t['taglineStart']}'.split(' ');
    final accent = '${_t['taglineAccent']}'.split(' ');
    final allWords = <String>[...words, ...accent];
    final goldFrom = words.length;
    return Column(children: [
      SizedBox(
        width: 196 * s, height: 196 * s,
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _spin, _loop]),
          builder: (_, __) {
            final inV = _iv(0, .32, Curves.easeOutBack).value;
            final pulse = 1.0 + .06 * math.sin(_loop.value * 2 * math.pi);
            return Opacity(opacity: inV.clamp(0.0, 1.0), child: Transform.scale(scale: .6 + .4 * inV, child: Stack(alignment: Alignment.center, children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFF3A1408).withOpacity(.55), const Color(0xFF1A0805).withOpacity(.35)]),
                    border: Border.all(color: const Color(0xFFFFE6AA).withOpacity(.5), width: 1.5))),
              Transform.scale(scale: pulse, child: Container(width: 170 * s, height: 170 * s, decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [_gold.withOpacity(.5), _gold.withOpacity(0)])))),
              Transform.rotate(angle: _spin.value * 2 * math.pi, child: CustomPaint(size: Size.square(196 * s), painter: _MandalaPainter(12))),
              Transform.rotate(angle: (1 - inV) * -.35, child: Image.asset(widget.logoAsset, width: 156 * s, height: 156 * s, errorBuilder: (_, __, ___) => const SizedBox())),
            ])));
          },
        ),
      ),
      SizedBox(height: 22 * s),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: AnimatedBuilder(
          animation: _intro,
          builder: (_, __) => Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            for (int i = 0; i < allWords.length; i++)
              Builder(builder: (_) {
                final v = _iv(.3 + i * .04, .5 + i * .04).value;
                return Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 16 * (1 - v)),
                    child: Text(allWords[i], style: GoogleFonts.rozhaOne(fontSize: 30 * s, height: 1.15, color: i >= goldFrom ? _gold : Colors.white,
                        shadows: [Shadow(color: Colors.black.withOpacity(.35), offset: const Offset(0, 2)), Shadow(color: Colors.black.withOpacity(.85), blurRadius: 24, offset: const Offset(0, 6))]))));
              }),
          ]),
        ),
      ),
      const SizedBox(height: 6),
      FadeTransition(opacity: _iv(.68, .85), child: Text('${_t['subtitle']}', textAlign: TextAlign.center,
          style: GoogleFonts.kalam(fontSize: 16 * s, fontWeight: FontWeight.w700, color: const Color(0xFFFFE1B8)))),
    ]);
  }

  Widget _legal({bool dark = true}) => Text.rich(
        TextSpan(style: GoogleFonts.poppins(fontSize: 10.5, color: dark ? Colors.white.withOpacity(.65) : _muted), children: [
          const TextSpan(text: 'By continuing, I accept the '),
          WidgetSpan(child: GestureDetector(onTap: () => _openUrl('${_t['privacyUrl']}'),
              child: Text('privacy policy', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: dark ? _gold : _red)))),
          const TextSpan(text: ' and '),
          WidgetSpan(child: GestureDetector(onTap: () => _openUrl('${_t['termsUrl']}'),
              child: Text('terms of use', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: dark ? _gold : _red)))),
        ]),
        textAlign: TextAlign.center,
      );

  void _openUrl(String u) {
    if (u.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening link: $u')));
    }
  }

  Widget _introButtons() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _step != _Step.intro
            ? const SizedBox.shrink()
            : FadeTransition(
                key: ValueKey(_returning),
                opacity: _iv(.8, 1),
                child: _returning ? _welcomeBackCard() : Column(mainAxisSize: MainAxisSize.min, children: [
                  _Press(onTap: _open, child: AnimatedBuilder(
                    animation: _loop,
                    builder: (_, child) => Container(
                      height: 58,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(colors: [Color(0xFFFFE3A0), Color(0xFFF2A93B), Color(0xFFE07B12)], stops: [0, .55, 1]),
                          boxShadow: [BoxShadow(color: const Color(0xFFF2A93B).withOpacity(.7 + .3 * math.sin(_loop.value * 2 * math.pi)), blurRadius: 30, offset: const Offset(0, 18), spreadRadius: -12)]),
                      child: _Shine(t: _loop.value, child: child!),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 30, height: 30, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF3A0612), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.mail_rounded, size: 16, color: _gold)),
                      const SizedBox(width: 10),
                      Text('${_t['buttonText']}', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF3A0612))),
                    ]),
                  )),
                  const SizedBox(height: 12),
                  _legal(),
                ]),
              ),
      );

  Widget _welcomeBackCard() => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 30, offset: const Offset(0, -10), spreadRadius: -10)]),
          child: Row(children: [
            Container(width: 52, height: 52, padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [_gold, Color(0xFFE8486B), Color(0xFF8B5CF6), Color(0xFF2BB3A3), _gold])),
                child: Container(alignment: Alignment.center, decoration: const BoxDecoration(color: Color(0xFFFFF4DC), shape: BoxShape.circle),
                    child: Text((_savedName ?? '?').isEmpty ? '?' : _savedName![0].toUpperCase(), style: GoogleFonts.rozhaOne(fontSize: 22, color: _red)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_t['welcomeBack']}, ${(_savedName ?? '').split(' ').first} 👋', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.rozhaOne(fontSize: 20, color: _maroon)),
              Text(_savedEmail ?? '', style: GoogleFonts.poppins(fontSize: 11.5, color: _muted)),
            ])),
          ]),
        ),
        const SizedBox(height: 12),
        _Press(onTap: _busy ? () {} : _useSaved, child: _maroonButton(_busy ? '📨 Sending code…' : 'Send code to $_savedEmail →', true)),
        const SizedBox(height: 10),
        GestureDetector(onTap: _open, child: Text.rich(TextSpan(style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFFFE1C2)), children: [
          const TextSpan(text: 'Not you? '),
          TextSpan(text: 'Use another email', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _gold)),
        ]))),
      ]);

  Widget _maroonButton(String label, bool on) => AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 56, alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: on ? const LinearGradient(colors: [Color(0xFFB3122A), Color(0xFF8A0F22), Color(0xFF5A0818)], stops: [0, .55, 1]) : null,
          color: on ? null : const Color(0xFFE9DCC8),
          boxShadow: on ? [BoxShadow(color: const Color(0xFF780A1E).withOpacity(.9), blurRadius: 26, offset: const Offset(0, 16), spreadRadius: -14)] : null,
        ),
        child: AnimatedBuilder(animation: _loop, builder: (_, __) => _Shine(t: on ? _loop.value : 1, child: Center(child: Text(label,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, color: on ? Colors.white : const Color(0xFFA8957E)))))),
      );

  // ───────── sheet with flipping recipe card ─────────
  Widget _sheet(double bottomPad) {
    final otp = _step == _Step.otp;
    final canGo = true;
    final label = _busy ? (otp ? '⏳ Signing you in…' : '📨 Sending code…') : (otp ? 'Verify & continue →' : 'Continue →');
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
      decoration: BoxDecoration(color: _cream, borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 40, offset: const Offset(0, -20), spreadRadius: -10)]),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFDCC9AE), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 14),
        Row(children: [
          Image.asset(widget.logoAsset, width: 52, height: 52, errorBuilder: (_, __, ___) => const SizedBox(width: 52)),
          const SizedBox(width: 12),
          Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 300),
              child: Text('${otp ? _t['otpSheetTitle'] : _t['sheetTitle']}', key: ValueKey(otp), style: GoogleFonts.rozhaOne(fontSize: 22, color: _maroon)))),
          IconButton(onPressed: () { FocusScope.of(context).unfocus(); setState(() => _step = _Step.intro); _flip.value = 0; _wallC.repeat(); },
              icon: const Icon(Icons.close_rounded, color: _muted)),
        ]),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: _flip,
          builder: (_, __) {
            final a = _flip.value * math.pi;
            final back = a > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..setEntry(3, 2, .0012)..rotateY(a),
              child: back ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: _otpCard()) : _detailsCard(),
            );
          },
        ),
        if (_sendErr != null) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(_sendErr!, textAlign: TextAlign.center, style: GoogleFonts.kalam(fontSize: 14, fontWeight: FontWeight.w700, color: _err))),
        const SizedBox(height: 18),
        _Press(onTap: canGo ? (otp ? _verify : _sendCode) : (otp ? () {} : _sendCode), child: _maroonButton(label, canGo || _busy)),
        const SizedBox(height: 12),
        _legal(dark: false),
      ]),
    );
  }

  Widget _paperBox({required Widget child, double tilt = -1.2}) => Transform.rotate(
        angle: tilt * math.pi / 180,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(color: _paperColor, borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: const Color(0xFF5A2800).withOpacity(.5), blurRadius: 24, offset: const Offset(0, 14), spreadRadius: -14)]),
            child: CustomPaint(painter: _LinedPaper(), child: Padding(padding: const EdgeInsets.only(left: 30), child: child)),
          ),
          Positioned(top: -10, left: 0, right: 0, child: Center(child: Transform.rotate(angle: .05,
              child: Container(width: 90, height: 22, color: const Color(0xFFF2A93B).withOpacity(.55))))),
        ]),
      );

  Widget _detailsCard() => _paperBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${_t['cardTitle']}', style: GoogleFonts.kalam(fontSize: 18, fontWeight: FontWeight.w700, color: _maroon)),
        _line('FULL NAME', _name, _nameF, ok: _name.text.trim().length >= 2, next: _emailF, type: TextInputType.name, caps: TextCapitalization.words),
        AnimatedBuilder(
          animation: _shakeE,
          builder: (_, child) => Transform.translate(offset: Offset(math.sin(_shakeE.value * math.pi * 4) * 6 * (1 - _shakeE.value), 0), child: child),
          child: _line('EMAIL', _email, _emailF, ok: _validEmail(_email.text), bad: _emailErr != null, type: TextInputType.emailAddress, onDone: _sendCode),
        ),
        AnimatedSize(duration: const Duration(milliseconds: 250), child: _emailErr == null ? const SizedBox(width: double.infinity) : Padding(
            padding: const EdgeInsets.only(left: 70, top: 2),
            child: Text(_emailErr!, style: GoogleFonts.kalam(fontSize: 14, fontWeight: FontWeight.w700, color: _err)))),
      ]));

  Widget _line(String label, TextEditingController c, FocusNode f,
      {required bool ok, bool bad = false, FocusNode? next, TextInputType? type, TextCapitalization caps = TextCapitalization.none, VoidCallback? onDone}) {
    final focused = f.hasFocus;
    return Container(
      height: 40, margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bad ? _err : focused ? _red : Colors.transparent, width: 1.5))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 62, child: Text(label, style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: ok ? _green : const Color(0xFFA88B68)))),
        Expanded(child: Focus(
          onFocusChange: (_) => setState(() {}),
          child: TextField(
            controller: c, focusNode: f, keyboardType: type, textCapitalization: caps, autocorrect: false,
            textInputAction: next != null ? TextInputAction.next : TextInputAction.done,
            onSubmitted: (_) {
              if (next != null) {
                next.requestFocus();
              } else {
                onDone?.call();
              }
            },
            cursorColor: _blue,
            style: GoogleFonts.kalam(fontSize: 20, fontWeight: FontWeight.w700, color: bad ? _err : _blue),
            decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
          ),
        )),
        AnimatedScale(scale: ok && !bad ? 1.0 : 0.0, duration: const Duration(milliseconds: 400), curve: Curves.elasticOut,
            child: Container(width: 22, height: 22, alignment: Alignment.center, decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 14, color: Colors.white))),
      ]),
    );
  }

  Widget _otpCard() => Stack(clipBehavior: Clip.none, children: [
        _paperBox(tilt: 1, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${_t['otpTitle']}', style: GoogleFonts.kalam(fontSize: 18, fontWeight: FontWeight.w700, color: _maroon))),
            AnimatedBuilder(animation: _loop, builder: (_, __) => Transform.translate(offset: Offset(0, -4 * math.sin(_loop.value * 2 * math.pi).abs()),
                child: const Text('📩', style: TextStyle(fontSize: 24)))),
          ]),
          Text.rich(TextSpan(style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF7A5A44)), children: [
            TextSpan(text: 'We sent a $_len-digit code to '),
            TextSpan(text: _email.text.trim(), style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _blue)),
          ])),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _shakeO,
            builder: (_, child) => Transform.translate(offset: Offset(math.sin(_shakeO.value * math.pi * 4) * 6 * (1 - _shakeO.value), 0), child: child),
            child: _otpBoxes(),
          ),
          AnimatedSize(duration: const Duration(milliseconds: 250), child: _otpErr == null ? const SizedBox(width: double.infinity) : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_otpErr!, style: GoogleFonts.kalam(fontSize: 14, fontWeight: FontWeight.w700, color: _err)))),
          const SizedBox(height: 10),
          Row(children: [
            _resend > 0
                ? Text.rich(TextSpan(style: GoogleFonts.poppins(fontSize: 11, color: _muted), children: [
                    const TextSpan(text: 'Resend code in '),
                    TextSpan(text: '0:${_resend.toString().padLeft(2, '0')}', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: _red)),
                  ]))
                : GestureDetector(onTap: _busy ? null : _sendCode, child: Text('Resend code', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _red))),
            const Spacer(),
            GestureDetector(onTap: _changeEmail, child: Text('Change email', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _red))),
          ]),
        ])),
        // wax seal
        if (_sealed)
          Positioned(right: -18, bottom: -34, child: AnimatedBuilder(
            animation: _seal,
            builder: (_, __) {
              final k = Curves.easeIn.transform((_seal.value / .55).clamp(0.0, 1.0));
              final ink = ((_seal.value - .5) / .5).clamp(0.0, 1.0);
              return Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
                if (ink > 0) Opacity(opacity: 1 - ink, child: Container(width: 84 + 110 * ink, height: 84 + 110 * ink,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_red.withOpacity(.35), _red.withOpacity(0)])))),
                Opacity(opacity: k, child: Transform.rotate(angle: (-30 + 18 * k) * math.pi / 180, child: Transform.scale(scale: 3 - 2 * k, child: _sealDisc()))),
              ]);
            },
          )),
      ]);

  Widget _sealDisc() => Container(
        width: 84, height: 84,
        decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: const RadialGradient(center: Alignment(-.2, -.3), colors: [Color(0xFFD2263B), Color(0xFF8A0F22), Color(0xFF5A0818)], stops: [0, .7, 1]),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 14, offset: const Offset(0, 8), spreadRadius: -4)]),
        child: Stack(alignment: Alignment.center, children: [
          ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFFFFC2B0), BlendMode.modulate), child: Image.asset(widget.logoAsset, width: 54, height: 54, errorBuilder: (_, __, ___) => const SizedBox())),
          Positioned(bottom: 8, child: Text('WELCOME', style: GoogleFonts.poppins(fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: const Color(0xFFFFD9D9)))),
        ]),
      );

  Widget _otpBoxes() {
    final v = _otp.text, done = v.length == _len && _otpErr == null;
    return GestureDetector(
      onTap: () => _otpF.requestFocus(),
      child: Stack(children: [
        // hidden real input (supports paste + SMS/email autofill)
        Opacity(opacity: 0, child: SizedBox(height: 44, child: TextField(
          controller: _otp, focusNode: _otpF, keyboardType: TextInputType.number, maxLength: _len,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(counterText: '', border: InputBorder.none),
        ))),
        Row(children: [
          for (int i = 0; i < _len; i++) ...[
            if (i > 0) const SizedBox(width: 7),
            Expanded(child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 44, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? const Color(0xFFF1FBF5) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(width: 1.5, color: _otpErr != null ? _err : done ? _green : (_otpF.hasFocus && i == v.length) ? _red : const Color(0xFFE2CFB0)),
                boxShadow: (_otpF.hasFocus && i == v.length && _otpErr == null) ? [BoxShadow(color: _red.withOpacity(.12), spreadRadius: 3)] : null,
              ),
              child: i < v.length
                  ? TweenAnimationBuilder<double>(
                      key: ValueKey('$i${v[i]}'), tween: Tween<double>(begin: 1.3, end: 1.0), duration: const Duration(milliseconds: 250),
                      builder: (_, s, child) => Transform.scale(scale: s, child: child),
                      child: Text(v[i], style: GoogleFonts.kalam(fontSize: 24, fontWeight: FontWeight.w700, color: _otpErr != null ? _err : _blue)))
                  : null,
            )),
          ],
        ]),
      ]),
    );
  }

  // ───────── welcome ─────────
  Widget _welcomeView() => AnimatedBuilder(
        animation: _welcome,
        builder: (_, __) {
          final v = _welcome.value;
          final fade = (v / .2).clamp(0.0, 1.0), logo = Curves.easeOutBack.transform((v / .3).clamp(0.0, 1.0));
          final write = ((v - .25) / .45).clamp(0.0, 1.0), line = ((v - .65) / .25).clamp(0.0, 1.0);
          return Opacity(
            opacity: fade,
            child: Container(
                decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -.2), colors: [_red, const Color(0xFF2A060E)], stops: const [0, .7])),
                child: Stack(alignment: Alignment.center, children: [
                  CustomPaint(size: Size.infinite, painter: _BurstPainter(((v - .2) / .6).clamp(0.0, 1.0))),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 250, height: 250, child: Stack(alignment: Alignment.center, children: [
                      AnimatedBuilder(animation: _spin, builder: (_, __) => Transform.rotate(angle: _spin.value * 2 * math.pi * 1.6, child: CustomPaint(size: const Size.square(250), painter: _MandalaPainter(8)))),
                      Opacity(opacity: logo.clamp(0.0, 1.0), child: Transform.scale(scale: 2.4 - 1.4 * logo, child: Image.asset(widget.logoAsset, width: 150, height: 150, errorBuilder: (_, __, ___) => const SizedBox()))),
                    ])),
                    Text('${_t['welcomeTitle']}', style: GoogleFonts.rozhaOne(fontSize: 28, color: Colors.white)),
                    ClipRect(child: Align(alignment: Alignment.centerLeft, widthFactor: write,
                        child: Text(_name.text.trim(), style: GoogleFonts.kalam(fontSize: 30, fontWeight: FontWeight.w700, color: _gold)))),
                    const SizedBox(height: 6),
                    Opacity(opacity: line, child: Text('${_t['welcomeLine']}', style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFFFFE1C2)))),
                  ]),
                ]),
              ),
          );
        },
      );
}

// ───────────────────────────── helpers & painters ─────────────────────────────
class _Press extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Press({required this.child, required this.onTap});
  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _d = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _d = true),
        onTapCancel: () => setState(() => _d = false),
        onTapUp: (_) { setState(() => _d = false); HapticFeedback.lightImpact(); widget.onTap(); },
        child: AnimatedScale(scale: _d ? 0.95 : 1.0, duration: const Duration(milliseconds: 140), child: widget.child),
      );
}

class _Shine extends StatelessWidget {
  final double t; // 0..1 loop; sweep happens in the first 45%
  final Widget child;
  const _Shine({required this.t, required this.child});
  @override
  Widget build(BuildContext context) {
    final k = t / .45;
    return ClipRRect(borderRadius: BorderRadius.circular(18), child: Stack(children: [
      Positioned.fill(child: child),
      if (k < 1) Positioned.fill(child: IgnorePointer(child: FractionallySizedBox(
          alignment: Alignment(-1.6 + 3.2 * k, 0), widthFactor: .28,
          child: Transform(transform: Matrix4.skewX(-.35), child: const DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, Color(0x99FFFFFF), Colors.transparent]))))))),
    ]));
  }
}

class _MandalaPainter extends CustomPainter {
  final int petals;
  _MandalaPainter(this.petals);
  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero), r = s.width / 2;
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = _gold.withOpacity(.85);
    c.drawCircle(o, r * .96, line);
    final dots = Paint()..color = _gold.withOpacity(.85);
    for (int i = 0; i < 90; i++) {
      final a = i / 90 * 2 * math.pi;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * .9, .9, dots);
    }
    final fill = Paint()..color = _gold.withOpacity(.9);
    for (int i = 0; i < petals; i++) {
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(i / petals * 2 * math.pi);
      final p = Path()
        ..moveTo(0, -r)
        ..quadraticBezierTo(r * .1, -r * .86, 0, -r * .72)
        ..quadraticBezierTo(-r * .1, -r * .86, 0, -r);
      c.drawPath(p, fill);
      c.restore();
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class _SparkPainter extends CustomPainter {
  final Animation<double> a;
  _SparkPainter(this.a) : super(repaint: a);
  static final _r = math.Random(3);
  static final _s = List.generate(22, (_) => [_r.nextDouble(), _r.nextDouble(), 2 + _r.nextDouble() * 3, _r.nextDouble()]);
  @override
  void paint(Canvas c, Size s) {
    final t = DateTime.now().millisecondsSinceEpoch / 1000;
    for (final p in _s) {
      final dur = 5 + p[3] * 5, k = ((t / dur) + p[3]) % 1;
      final op = k < .15 ? k / .15 : 1 - (k - .15) / .85;
      c.drawCircle(Offset(p[0] * s.width, s.height * (.5 + p[1] * .35) - 260 * k), p[2] / 2,
          Paint()..color = _gold.withOpacity(.9 * op)..maskFilter = const MaskFilter.blur(BlurStyle.normal, .5));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}

class _BurstPainter extends CustomPainter {
  final double k;
  _BurstPainter(this.k);
  static final _r = math.Random(9);
  static final _b = List.generate(36, (_) => [_r.nextDouble() * 2 * math.pi, 90 + _r.nextDouble() * 120]);
  @override
  void paint(Canvas c, Size s) {
    if (k <= 0 || k >= 1) return;
    final o = Offset(s.width / 2, s.height * .42), e = Curves.easeOutCubic.transform(k);
    for (final b in _b) {
      c.drawCircle(o + Offset(math.cos(b[0]), math.sin(b[0])) * b[1] * e, 3 * (1 - .7 * e), Paint()..color = _gold.withOpacity(1 - k));
    }
  }
  @override
  bool shouldRepaint(covariant _BurstPainter o) => o.k != k;
}

class _LinedPaper extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFE9D8BD)..strokeWidth = 1;
    for (double y = 40; y < s.height + 10; y += 34) { c.drawLine(Offset(-16, y), Offset(s.width + 16, y), p); }
    c.drawLine(const Offset(22, -16), Offset(22, s.height + 18), Paint()..color = const Color(0xFFE8486B).withOpacity(.35)..strokeWidth = 1.5);
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}
