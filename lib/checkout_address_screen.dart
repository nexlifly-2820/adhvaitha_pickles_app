// checkout_address_screen.dart — AmbhuJakshi checkout, step 1 (matches checkout_parcel_address.mp4)
// A kraft parcel with twine; its courier label prints the name, address, pincode, phone and Home/Office/Other
// live while the customer types (long addresses shrink to fit). Form below: contact, "Use my current location",
// pincode → city/state auto-fill, house, road/area, address type, Royal Gift switch (+ note), trust row,
// dark bottom bar with "Continue to Billing".
// Backend: checkout_address_backend.js
//
// pubspec.yaml:
//   http: ^1.2.0
//   google_fonts: ^6.2.1
//   geolocator: ^12.0.0
//   geocoding: ^3.0.0
// flutter: assets: - assets/logo_full.png
// Android (android/app/src/main/AndroidManifest.xml):
//   <uses-permission android:name="android.permission.INTERNET"/>
//   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
//   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
// iOS (Info.plist): NSLocationWhenInUseUsageDescription = "To fill your delivery address"
//
// Usage:
//   CheckoutAddressScreen(
//     apiBase: 'https://your-api.com/api',
//     headers: {'Authorization': 'Bearer $token'},
//     amountToPay: cartTotal,                         // shown in the bottom bar
//     onContinue: (address) => Navigator.push(context, MaterialPageRoute(builder: (_) => BillingScreen(address: address))),
//   )

import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

const Color _ink = Color(0xFF1F3A68);
const Color _stamp = Color(0xFFB8242F);
const Color _paper = Color(0xFFFBF7EE);
const Color _txt = Color(0xFF2B2018);
const Color _mut = Color(0xFF8D7A64);
const Color _okC = Color(0xFF2F6B45);
const Color _dark = Color(0xFF2B1D12);
const Color _brown = Color(0xFF3B2A1A);

class CheckoutAddressScreen extends StatefulWidget {
  final String apiBase;
  final Map<String, String>? headers;
  final double amountToPay;
  final String logoAsset;
  final void Function(Map<String, dynamic> address) onContinue;
  const CheckoutAddressScreen({
    super.key,
    required this.apiBase,
    required this.onContinue,
    this.headers,
    this.amountToPay = 0,
    this.logoAsset = 'assets/logo_full.png',
  });
  @override
  State<CheckoutAddressScreen> createState() => _CheckoutAddressScreenState();
}

class _CheckoutAddressScreenState extends State<CheckoutAddressScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _alt = TextEditingController();
  final TextEditingController _pin = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _house = TextEditingController();
  final TextEditingController _road = TextEditingController();
  final TextEditingController _note = TextEditingController();

  String _type = 'HOME';
  bool _gift = false;
  int _gps = 0; // 0 idle, 1 finding, 2 found
  String _gpsTitle = 'Use my current location';
  String _gpsSub = 'Fills pincode, city & area';
  bool _saving = false;
  bool _tried = false;
  String _lastPin = '';
  int _bump = 0;
  late AnimationController _pulse;

  // admin texts
  String _giftTitle = 'Send as a Royal Gift';
  String _giftSub = 'Add a personalized note for your loved ones';
  List<String> _trust = <String>['🔒 100% Secure', '⚡ Fast Delivery', '🌿 Authentic'];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
    for (final TextEditingController c in <TextEditingController>[_name, _phone, _alt, _city, _state, _house, _road, _note]) {
      c.addListener(_changed);
    }
    _pin.addListener(_pinChanged);
    _load();
  }

  @override
  void dispose() {
    _pulse.dispose();
    for (final TextEditingController c in <TextEditingController>[_name, _phone, _alt, _pin, _city, _state, _house, _road, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Map<String, String> get _jsonHeaders {
    final Map<String, String> h = <String, String>{'Content-Type': 'application/json'};
    if (widget.headers != null) h.addAll(widget.headers!);
    return h;
  }

  // ───────── data ─────────
  Future<void> _load() async {
    try {
      final http.Response r = await http.get(Uri.parse('${widget.apiBase}/checkout/address'), headers: widget.headers);
      if (r.statusCode != 200 || !mounted) return;
      final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
      final Map<String, dynamic> a = (j['address'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final Map<String, dynamic> s = (j['settings'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      _name.text = '${a['name'] ?? ''}';
      _phone.text = '${a['phone'] ?? ''}';
      _alt.text = '${a['altPhone'] ?? ''}';
      _house.text = '${a['house'] ?? ''}';
      _road.text = '${a['road'] ?? ''}';
      _city.text = '${a['city'] ?? ''}';
      _state.text = '${a['state'] ?? ''}';
      _lastPin = '${a['pincode'] ?? ''}';
      _pin.text = _lastPin;
      setState(() {
        _type = '${a['type'] ?? 'HOME'}'.toUpperCase();
        if (s['giftTitle'] != null) _giftTitle = '${s['giftTitle']}';
        if (s['giftSubtitle'] != null) _giftSub = '${s['giftSubtitle']}';
        if (s['trust'] is List) _trust = (s['trust'] as List).map((dynamic e) => '$e').toList();
      });
    } catch (_) {}
  }

  void _pinChanged() {
    final String p = _pin.text.trim();
    if (mounted) setState(() {});
    if (p.length == 6 && p != _lastPin) {
      _lastPin = p;
      _lookupPin(p);
    }
  }

  Future<void> _lookupPin(String p) async {
    try {
      final http.Response r = await http.get(Uri.parse('${widget.apiBase}/pincode/$p'), headers: widget.headers);
      if (r.statusCode != 200 || !mounted) return;
      final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
      if (j['city'] != null && _city.text.trim().isEmpty) _city.text = '${j['city']}';
      if (j['state'] != null && _state.text.trim().isEmpty) _state.text = '${j['state']}';
      setState(() => _bump++);
    } catch (_) {}
  }

  Future<void> _useLocation() async {
    if (_gps == 1) return;
    HapticFeedback.selectionClick();
    setState(() {
      _gps = 1;
      _gpsTitle = 'Finding you…';
      _gpsSub = '';
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
        throw 'Turn on location (GPS), then tap again';
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw 'Allow location for this app in Settings, then tap again';
      }
      if (perm == LocationPermission.denied) throw 'Location permission is needed to fill your address';

      // never wait forever: quick last-known fix first, then a fresh one with a time limit
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 12));
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
        pos ??= await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 10));
      }
      final Position p = pos;

      // address from the phone's geocoder; if that fails, from OpenStreetMap
      String pin = '', city = '', state = '', road = '', area = '', house = '';
      try {
        final List<Placemark> marks = await placemarkFromCoordinates(p.latitude, p.longitude).timeout(const Duration(seconds: 8));
        if (marks.isNotEmpty) {
          final Placemark m = marks.first;
          pin = m.postalCode ?? '';
          city = (m.locality ?? '').isNotEmpty ? m.locality! : (m.subAdministrativeArea ?? '');
          state = m.administrativeArea ?? '';
          road = m.thoroughfare ?? '';
          area = m.subLocality ?? '';
          house = m.subThoroughfare ?? '';
        }
      } catch (_) {}
      if (pin.isEmpty || city.isEmpty) {
        try {
          final http.Response r = await http.get(
            Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&addressdetails=1&lat=${p.latitude}&lon=${p.longitude}'),
            headers: const <String, String>{'User-Agent': 'AmbhujakshiApp/1.0 (orders@adhvaithafoods.in)', 'Accept-Language': 'en'},
          ).timeout(const Duration(seconds: 8));
          final Map<String, dynamic> a = Map<String, dynamic>.from(((jsonDecode(r.body) as Map)['address'] as Map?) ?? const <String, dynamic>{});
          String g(List<String> ks) => ks.map((String k) => '${a[k] ?? ''}').firstWhere((String v) => v.isNotEmpty, orElse: () => '');
          if (pin.isEmpty) pin = g(<String>['postcode']);
          if (city.isEmpty) city = g(<String>['city', 'town', 'village', 'county', 'state_district']);
          if (state.isEmpty) state = g(<String>['state']);
          if (road.isEmpty) road = g(<String>['road', 'pedestrian']);
          if (area.isEmpty) area = g(<String>['suburb', 'neighbourhood', 'quarter', 'city_district']);
          if (house.isEmpty) house = g(<String>['house_number']);
        } catch (_) {}
      }
      if (pin.isEmpty && city.isEmpty && road.isEmpty) throw 'Found you, but could not read the address — please type it';

      pin = pin.replaceAll(' ', '');
      _lastPin = pin;
      if (pin.isNotEmpty) _pin.text = pin;
      if (city.isNotEmpty) _city.text = city;
      if (state.isNotEmpty) _state.text = state;
      final String roadLine = <String>[road, area].where((String e) => e.isNotEmpty).join(', ');
      if (roadLine.isNotEmpty) _road.text = roadLine;
      if (house.isNotEmpty && _house.text.trim().isEmpty) _house.text = house;
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() {
        _gps = 2;
        _gpsTitle = <String>[area, city].where((String e) => e.isNotEmpty).join(', ');
        if (_gpsTitle.isEmpty) _gpsTitle = 'Location found';
        _gpsSub = 'Location found · accurate to ${p.accuracy.round()} m · please check house no.';
        _bump++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gps = 0;
        _gpsTitle = 'Use my current location';
        _gpsSub = e is String ? e : 'Could not get your location — please try again or type the address';
      });
    }
  }

  // ───────── validation ─────────
  bool get _nameOk => _name.text.trim().length >= 2;
  bool get _phoneOk => RegExp(r'^[6-9]\d{9}$').hasMatch(_phone.text.replaceAll(' ', ''));
  bool get _altOk => _alt.text.trim().isEmpty || RegExp(r'^[6-9]\d{9}$').hasMatch(_alt.text.replaceAll(' ', ''));
  bool get _pinOk => RegExp(r'^[1-9]\d{5}$').hasMatch(_pin.text.trim());
  bool get _cityOk => _city.text.trim().length >= 2;
  bool get _stateOk => _state.text.trim().length >= 2;
  bool get _houseOk => _house.text.trim().length >= 3;
  bool get _roadOk => _road.text.trim().length >= 3;
  bool get _allOk => _nameOk && _phoneOk && _altOk && _pinOk && _cityOk && _stateOk && _houseOk && _roadOk;

  Future<void> _continue() async {
    if (!_allOk) {
      HapticFeedback.mediumImpact();
      setState(() => _tried = true);
      return;
    }
    setState(() => _saving = true);
    final Map<String, dynamic> body = <String, dynamic>{
      'name': _name.text.trim(),
      'phone': _phone.text.replaceAll(' ', ''),
      'altPhone': _alt.text.replaceAll(' ', ''),
      'pincode': _pin.text.trim(),
      'city': _city.text.trim(),
      'state': _state.text.trim(),
      'house': _house.text.trim(),
      'road': _road.text.trim(),
      'type': _type,
      'gift': _gift,
      'giftNote': _gift ? _note.text.trim() : '',
    };
    try {
      final http.Response r = await http.post(Uri.parse('${widget.apiBase}/checkout/address'), headers: _jsonHeaders, body: jsonEncode(body)).timeout(const Duration(seconds: 4));
      if (r.statusCode == 200) {
        final Map<String, dynamic> j = jsonDecode(r.body) as Map<String, dynamic>;
        if (mounted) setState(() => _saving = false);
        HapticFeedback.lightImpact();
        widget.onContinue(<String, dynamic>{...body, 'id': '${j['id'] ?? '1'}'});
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() => _saving = false);
    HapticFeedback.lightImpact();
    widget.onContinue(<String, dynamic>{...body, 'id': '1'});
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));
  }

  // ───────── UI ─────────
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final bool kb = mq.viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFEDE4D6),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -1), radius: 1.4, colors: <Color>[Color(0xFFF6EFE3), Color(0xFFE6D9C5)]),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              _topBar(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                height: kb ? 176.0 : 300.0,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(width: 390, height: 300, child: _parcel()),
                ),
              ),
              Expanded(child: _sheet(mq)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: <Widget>[
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3), spreadRadius: -4)],
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 18, color: _txt),
              ),
            ),
            const SizedBox(width: 10),
            Text('Checkout', style: GoogleFonts.rozhaOne(fontSize: 21, color: _brown)),
            const Spacer(),
            _chip('ADDRESS', true),
            const SizedBox(width: 4),
            _chip('BILL', false),
            const SizedBox(width: 4),
            _chip('PAY', false),
          ],
        ),
      ),
    );
  }

  Widget _chip(String t, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: on ? _brown : _brown.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
      child: Text(t, style: GoogleFonts.poppins(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: on ? const Color(0xFFF6E7C8) : const Color(0xFF9A8670))),
    );
  }

  // ───────── parcel (designed at 390 × 300, scaled by FittedBox) ─────────
  Widget _parcel() {
    return Center(
      child: Transform(
        alignment: const Alignment(0, 0.2),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0011)
          ..rotateX(0.31)
          ..rotateZ(-0.035),
        child: Container(
          width: 342,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFFD4A86F), Color(0xFFC4935A), Color(0xFFB07F48)],
            ),
            boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFF462808).withOpacity(0.55), blurRadius: 40, offset: const Offset(0, 30), spreadRadius: -18)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                const Positioned.fill(child: CustomPaint(painter: _KraftPainter())),
                // tape band across the middle
                Positioned(
                  left: 0,
                  right: 0,
                  top: 123,
                  height: 34,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Colors.white.withOpacity(0.16), Colors.white.withOpacity(0.05), Colors.black.withOpacity(0.06)],
                      ),
                    ),
                  ),
                ),
                // printed logo on the box
                Positioned(
                  right: 14,
                  top: 150,
                  child: Transform.rotate(
                    angle: 0.07,
                    child: Opacity(
                      opacity: 0.5,
                      child: Column(
                        children: <Widget>[
                          ColorFiltered(
                            colorFilter: const ColorFilter.mode(Color(0xFF5A2D0A), BlendMode.srcATop),
                            child: Image.asset(widget.logoAsset, width: 60, height: 60, errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox(width: 60, height: 60)),
                          ),
                          Text('HANDLE WITH\nLOVE', textAlign: TextAlign.center, style: GoogleFonts.rozhaOne(fontSize: 11, height: 1.1, letterSpacing: 1, color: const Color(0xFF5A2D0A))),
                        ],
                      ),
                    ),
                  ),
                ),
                // fragile stamp
                Positioned(
                  left: 22,
                  bottom: 18,
                  child: Transform.rotate(
                    angle: -0.05,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(border: Border.all(color: const Color(0xFF8C1E1E).withOpacity(0.45), width: 1.5), borderRadius: BorderRadius.circular(3)),
                      child: Text('FRAGILE · GLASS JARS', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2, color: const Color(0xFF8C1E1E).withOpacity(0.55))),
                    ),
                  ),
                ),
                // twine
                const Positioned(left: 168, top: -4, bottom: -4, width: 6, child: _Twine(vertical: true)),
                const Positioned(left: -4, right: -4, top: 215, height: 6, child: _Twine(vertical: false)),
                // courier label (on top of the twine so it is always readable)
                Positioned(left: 18, top: 16, child: _label()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label() {
    final String name = _name.text.trim();
    final String line2 = <String>[_road.text.trim(), _city.text.trim(), _state.text.trim()].where((String e) => e.isNotEmpty).join(', ');
    final String addr = <String>[_house.text.trim(), line2].where((String e) => e.isNotEmpty).join('\n');
    final String phone = _phone.text.trim();
    final String pin = _pin.text.trim();
    final TextStyle mono = GoogleFonts.courierPrime(color: const Color(0xFF151515));
    // shrink text so long names / addresses always fit
    const double textW = 230;
    final double nameSize = _fit(name, mono.copyWith(fontWeight: FontWeight.w700), textW, 18, 12, 9);
    final double addrSize = _fit('$addr ${pin.isEmpty ? '' : '[$pin]'}', mono, textW, 66, 9.5, 7.2);

    return Transform.rotate(
      angle: -0.026,
      child: TweenAnimationBuilder<double>(
        key: ValueKey<int>(_bump),
        tween: Tween<double>(begin: 1.03, end: 1.0),
        duration: const Duration(milliseconds: 350),
        builder: (BuildContext c, double s, Widget? child) => Transform.scale(scale: s, child: child),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: 250,
              constraints: const BoxConstraints(minHeight: 132),
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 34),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF7),
                borderRadius: BorderRadius.circular(4),
                boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFF3C1E00).withOpacity(0.25), blurRadius: 3, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.only(bottom: 4),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF222222), width: 1.5))),
                    child: Row(
                      children: <Widget>[
                        Text('AMBHUJAKSHI · SHIP TO', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: const Color(0xFF151515))),
                        const Spacer(),
                        Image.asset(widget.logoAsset, width: 22, height: 22, errorBuilder: (BuildContext c, Object e, StackTrace? s) => const SizedBox(width: 22, height: 22)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('DELIVER TO', style: GoogleFonts.poppins(fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 1, color: const Color(0xFF777777))),
                  Text(name, style: mono.copyWith(fontSize: nameSize, fontWeight: FontWeight.w700)),
                  Text.rich(
                    TextSpan(
                      style: mono.copyWith(fontSize: addrSize, height: 1.3, color: const Color(0xFF222222)),
                      children: <InlineSpan>[
                        TextSpan(text: addr),
                        if (pin.isNotEmpty)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF111111), width: 1.2)),
                              child: Text(pin, style: mono.copyWith(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (phone.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text('Ph: +91 $phone', style: mono.copyWith(fontSize: 9.5, color: const Color(0xFF222222))),
                    ),
                ],
              ),
            ),
            // HOME / OFFICE / OTHER box
            Positioned(
              left: 8,
              bottom: 8,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Container(
                  key: ValueKey<String>(_type),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF111111), width: 1.2), borderRadius: BorderRadius.circular(3)),
                  child: Text(_type, style: GoogleFonts.poppins(fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 1, color: const Color(0xFF111111))),
                ),
              ),
            ),
            const Positioned(right: 10, bottom: 9, child: SizedBox(width: 96, height: 20, child: CustomPaint(painter: _BarcodePainter(7)))),
            // tape pieces
            Positioned(left: -14, top: -4, child: Transform.rotate(angle: -0.52, child: Container(width: 56, height: 16, color: const Color(0xBFF4E8C8)))),
            Positioned(right: -14, bottom: -2, child: Transform.rotate(angle: -0.52, child: Container(width: 56, height: 16, color: const Color(0xBFF4E8C8)))),
          ],
        ),
      ),
    );
  }

  /// Largest font size (start → min) at which [text] fits inside width × maxHeight.
  double _fit(String text, TextStyle style, double width, double maxHeight, double start, double min) {
    if (text.isEmpty) return start;
    double size = start;
    while (size > min) {
      final TextPainter tp = TextPainter(text: TextSpan(text: text, style: style.copyWith(fontSize: size, height: 1.3)), textDirection: TextDirection.ltr)
        ..layout(maxWidth: width);
      if (tp.height <= maxHeight) break;
      size -= 0.3;
    }
    return math.max(size, min);
  }

  // ───────── form sheet ─────────
  Widget _sheet(MediaQueryData mq) {
    return Container(
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFF3C1E00).withOpacity(0.5), blurRadius: 30, offset: const Offset(0, -14), spreadRadius: -18)],
      ),
      child: Stack(
        children: <Widget>[
          ListView(
            padding: EdgeInsets.fromLTRB(18, 22, 18, 100 + mq.padding.bottom),
            children: <Widget>[
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: const Color(0xFFDACDB8), borderRadius: BorderRadius.circular(2)))),
              _head("WHO'S RECEIVING"),
              _field(_name, 'Full name', ok: _nameOk, caps: TextCapitalization.words, type: TextInputType.name, error: 'Enter your full name'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _field(_phone, 'Phone number', ok: _phoneOk, type: TextInputType.phone, digits: 10, error: 'Enter a valid number')),
                  const SizedBox(width: 16),
                  Expanded(child: _field(_alt, 'Alternate (optional)', ok: _alt.text.trim().isNotEmpty && _altOk, type: TextInputType.phone, digits: 10, error: 'Invalid number', optional: true)),
                ],
              ),
              const SizedBox(height: 16),
              _head('WHERE TO'),
              _gpsButton(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _field(_pin, 'Pincode', ok: _pinOk, type: TextInputType.number, digits: 6, error: 'Enter 6-digit pincode')),
                  const SizedBox(width: 16),
                  Expanded(child: _field(_city, 'City', ok: _cityOk, caps: TextCapitalization.words, error: 'Enter city')),
                ],
              ),
              _field(_state, 'State', ok: _stateOk, caps: TextCapitalization.words, error: 'Enter state'),
              _field(_house, 'House no. / Building', ok: _houseOk, caps: TextCapitalization.words, error: 'Enter house no. / building', multi: true),
              _field(_road, 'Road / Area / Colony', ok: _roadOk, caps: TextCapitalization.words, error: 'Enter road / area', multi: true),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(child: _typeChip('Home', 'HOME')),
                  const SizedBox(width: 8),
                  Expanded(child: _typeChip('Office', 'OFFICE')),
                  const SizedBox(width: 8),
                  Expanded(child: _typeChip('Other', 'OTHER')),
                ],
              ),
              const SizedBox(height: 12),
              _giftCard(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (final String t in _trust) Text(t, style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: _mut)),
                ],
              ),
            ],
          ),
          Positioned(left: 16, right: 16, bottom: 16 + mq.padding.bottom, child: _bottomBar()),
        ],
      ),
    );
  }

  Widget _head(String t) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: <Widget>[
          Text(t, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: const Color(0xFF9A8468))),
          const SizedBox(width: 8),
          const Expanded(child: _DashLine()),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    required bool ok,
    required String error,
    TextInputType type = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    int digits = 0,
    bool multi = false,
    bool optional = false,
  }) {
    final bool showErr = _tried && !ok && !(optional && c.text.trim().isEmpty);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
        controller: c,
        keyboardType: multi ? TextInputType.multiline : type,
        textCapitalization: caps,
        minLines: 1,
        maxLines: multi ? 3 : 1,
        maxLength: digits > 0 ? digits : null,
        inputFormatters: digits > 0 ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly] : null,
        cursorColor: _ink,
        style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w500, color: _txt),
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.only(top: 14, bottom: 6),
          labelStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFA99579)),
          floatingLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: showErr ? _stamp : _ink),
          errorText: showErr ? error : null,
          errorStyle: GoogleFonts.poppins(fontSize: 10.5, color: _stamp),
          suffixIconConstraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          suffixIcon: ok ? const Icon(Icons.check_rounded, size: 16, color: _okC) : null,
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: ok ? _okC : const Color(0xFFDCCDB6), width: 1.5)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _ink, width: 1.8)),
          errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _stamp, width: 1.5)),
          focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _stamp, width: 1.8)),
        ),
      ),
    );
  }

  Widget _gpsButton() {
    final bool found = _gps == 2;
    return GestureDetector(
      onTap: _useLocation,
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: found ? const Color(0xFFEFF6F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: found ? _okC : const Color(0xFFBFA987), width: 1.5),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 28,
              height: 28,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (BuildContext c, Widget? child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Container(decoration: BoxDecoration(shape: BoxShape.circle, color: found ? _okC : const Color(0xFFE3EBF7))),
                      if (_gps == 1)
                        Transform.scale(
                          scale: 0.6 + _pulse.value,
                          child: Opacity(
                            opacity: 1 - _pulse.value,
                            child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _ink, width: 2))),
                          ),
                        ),
                      Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: found ? Colors.white : _ink)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(_gpsTitle, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: found ? _okC : _ink)),
                  Text(_gpsSub, style: GoogleFonts.poppins(fontSize: 10.5, color: _mut)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final bool on = _type == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _type = value;
          _bump++;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? _brown : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? _brown : const Color(0xFFDCCDB6), width: 1.5),
        ),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: on ? const Color(0xFFF6E7C8) : const Color(0xFF7C6A55))),
      ),
    );
  }

  Widget _giftCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0xFFECE1CF), offset: Offset(0, 1))]),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text('🎁', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_giftTitle, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _txt)),
                    Text(_giftSub, style: GoogleFonts.poppins(fontSize: 10.5, color: _mut)),
                  ],
                ),
              ),
              Switch.adaptive(
                value: _gift,
                activeColor: _stamp,
                onChanged: (bool v) {
                  HapticFeedback.selectionClick();
                  setState(() => _gift = v);
                },
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: _gift
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: TextField(
                      controller: _note,
                      maxLength: 150,
                      maxLines: 3,
                      minLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.kalam(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
                      decoration: InputDecoration(
                        hintText: 'Write your note…',
                        hintStyle: GoogleFonts.kalam(fontSize: 16, color: const Color(0xFFB9A88F)),
                        filled: true,
                        fillColor: const Color(0xFFFFFCF4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEADCC4))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEADCC4))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _ink)),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final String amount = widget.amountToPay == widget.amountToPay.roundToDouble() ? widget.amountToPay.toStringAsFixed(0) : widget.amountToPay.toStringAsFixed(2);
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 16, right: 7),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 24, offset: const Offset(0, 14), spreadRadius: -14)],
      ),
      child: Row(
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('To pay', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFFBFA987))),
              Text('₹$amount', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFFF6E7C8))),
            ],
          ),
          const Spacer(),
          _PressButton(
            onTap: _saving ? null : _continue,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFF2D9A6), borderRadius: BorderRadius.circular(12)),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _dark))
                  : Text('Continue to Billing →', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── small widgets & painters ─────────────────────────────
class _PressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _PressButton({required this.child, this.onTap});
  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (TapDownDetails d) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (TapUpDetails d) {
        setState(() => _down = false);
        if (widget.onTap != null) widget.onTap!();
      },
      child: AnimatedScale(scale: _down ? 0.93 : 1.0, duration: const Duration(milliseconds: 120), child: widget.child),
    );
  }
}

class _Twine extends StatelessWidget {
  final bool vertical;
  const _Twine({required this.vertical});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(-0.6, -0.6),
          colors: const <Color>[Color(0xFFE9DFC9), Color(0xFFE9DFC9), Color(0xFFCDBF9F), Color(0xFFCDBF9F)],
          stops: const <double>[0, 0.5, 0.5, 1],
          tileMode: TileMode.repeated,
        ),
        boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFF3C1E00).withOpacity(0.35), blurRadius: 2, offset: const Offset(0, 2))],
      ),
    );
  }
}

class _DashLine extends StatelessWidget {
  const _DashLine();
  @override
  Widget build(BuildContext context) => const SizedBox(height: 1, child: CustomPaint(painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  const _DashPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = const Color(0xFFD9CBB4)
      ..strokeWidth = 1;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0.5), Offset(math.min(x + 4, size.width), 0.5), p);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Kraft paper fibres + soft light
class _KraftPainter extends CustomPainter {
  const _KraftPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final math.Random r = math.Random(11);
    final Paint fibre = Paint()..strokeWidth = 0.8;
    for (int i = 0; i < 420; i++) {
      final double x = r.nextDouble() * size.width;
      final double y = r.nextDouble() * size.height;
      final double len = 3 + r.nextDouble() * 9;
      final double a = (r.nextDouble() - 0.5) * 0.6;
      fibre.color = (r.nextBool() ? const Color(0xFF7A4A18) : const Color(0xFFF2D3A2)).withOpacity(0.12 + r.nextDouble() * 0.12);
      canvas.drawLine(Offset(x, y), Offset(x + len * math.cos(a), y + len * math.sin(a)), fibre);
    }
    final Rect rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(center: const Alignment(-0.4, -0.6), radius: 0.9, colors: <Color>[Colors.white.withOpacity(0.18), Colors.white.withOpacity(0)]).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarcodePainter extends CustomPainter {
  final int seed;
  const _BarcodePainter(this.seed);
  @override
  void paint(Canvas canvas, Size size) {
    final math.Random r = math.Random(seed);
    final Paint p = Paint()..color = const Color(0xFF111111);
    double x = 0;
    while (x < size.width) {
      final double w = <double>[1, 1, 2, 1, 3, 1, 2][r.nextInt(7)];
      canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), p);
      x += w + (r.nextBool() ? 1 : 2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
