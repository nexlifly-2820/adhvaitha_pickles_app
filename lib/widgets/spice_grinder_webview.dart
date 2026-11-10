// spice_grinder_webview.dart
// "Fresh ground spices" — renders EXACTLY like the preview video (spices_realistic_v8.mp4),
// because it runs the same animation file (assets/spice_widget.html) inside a WebView.
// All data (podis, colours, prices, falling ingredient images, texts) comes from your admin dashboard
// through GET /api/home/spices — nothing is hard-coded.
//
// pubspec.yaml:
//   dependencies:
//     webview_flutter: ^4.10.0
//     http: ^1.2.0
//   flutter:
//     assets:
//       - assets/spice_widget.html
//
// Android: android/app/src/main/AndroidManifest.xml must have  <uses-permission android:name="android.permission.INTERNET"/>
//
// Usage on the home page:
//   SpiceGrinderWebView(
//     apiUrl: 'https://your-api.com/api/home/spices',
//     onOpen: (id) => Navigator.pushNamed(context, '/product', arguments: id),
//     onAdd: (id, variantId) async => cart.add(id, variantId),     // return true when added
//     onNotify: (id, variantId) => notifyMe(id, variantId),
//     onWishlist: (id) => wishlist.toggle(id),
//     wishlistIds: wishlist.ids,                                   // to show ♥ on saved podis
//     onViewAll: () => Navigator.pushNamed(context, '/category/podis'),
//   )

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class SpiceGrinderWebView extends StatefulWidget {
  final String apiUrl;
  final Map<String, String>? headers;                       // e.g. auth token if your API needs it
  final ValueChanged<String>? onOpen;
  final Future<bool> Function(String productId, String variantId)? onAdd;
  final void Function(String productId, String variantId)? onNotify;
  final ValueChanged<String>? onWishlist;
  final Set<String> wishlistIds;
  final VoidCallback? onViewAll;
  const SpiceGrinderWebView({super.key, required this.apiUrl, this.headers, this.onOpen, this.onAdd, this.onNotify,
      this.onWishlist, this.wishlistIds = const {}, this.onViewAll});
  @override
  State<SpiceGrinderWebView> createState() => _SpiceGrinderWebViewState();
}

class _SpiceGrinderWebViewState extends State<SpiceGrinderWebView> {
  late final WebViewController _c;
  double _height = 0;          // reported by the page (in 390-px design units)
  bool _ready = false, _hidden = false;
  String? _json;

  static const String _defaultJson = '{"settings": {"kicker": "FROM WHOLE SPICE TO PODI", "title": "Fresh ground", "titleAccent": "spices", "subtitle": "Pounded in stone, the way Ammamma did.", "cardTag": "🪨 STONE-GROUND TODAY"}, "products": [{"id": "p1", "name": "Moringa Karam Podi", "tagline": "Stone-ground podi", "image": "assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg", "powderColor": "#6B7A2A", "accentColor": "#A8D86A", "glowColor": "#3A4A14", "heat": 2, "throwIn": [{"name": "Moringa leaves", "pieces": ["assets/images/munagakuu.png"], "count": 3, "size": "big"}], "chips": [{"name": "Moringa leaves", "icon": "assets/images/munagakuu.png"}], "variants": [{"id": "v1", "label": "100g", "price": 129, "mrp": 149, "inStock": true}]}, {"id": "p2", "name": "Putnala Karam Podi", "tagline": "Stone-ground podi", "image": "assets/images/putnala_karam_podi_roasted_gram_spice_powder_for_idlis.jpg", "powderColor": "#D98E4A", "accentColor": "#FFB86B", "glowColor": "#6A3A14", "heat": 2, "throwIn": [{"name": "Roasted gram", "pieces": ["assets/images/chana.png"], "count": 6, "size": "small"}], "chips": [{"name": "Roasted gram", "icon": "assets/images/chana.png"}], "variants": [{"id": "v1", "label": "100g", "price": 129, "mrp": 149, "inStock": true}]}]}';

  @override
  void initState() {
    super.initState();
    _json = _defaultJson;
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('SpiceBridge', onMessageReceived: (m) => _onMessage(m.message))
      ..loadFlutterAsset('assets/spice_widget.html');
    _fetch();
  }

  Future<void> _fetch() async {
    _push();
    try {
      final r = await http.get(Uri.parse(widget.apiUrl), headers: widget.headers);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final enabled = (data['settings'] ?? {})['enabled'] ?? true;
        if (enabled != false && (data['products'] as List? ?? []).isNotEmpty) {
          _json = r.body;
          _push();
        }
      }
    } catch (e) {
      debugPrint('Spice section network fetch failed, using fallback: $e');
    }
  }

  void _push() {
    if (!_ready || _json == null) return;
    _c.runJavaScript('loadSpices($_json);');
    _c.runJavaScript('setWishlist(${jsonEncode(widget.wishlistIds.toList())});');
  }

  @override
  void didUpdateWidget(covariant SpiceGrinderWebView old) {
    super.didUpdateWidget(old);
    if (_ready && !setEquals(old.wishlistIds, widget.wishlistIds)) {
      _c.runJavaScript('setWishlist(${jsonEncode(widget.wishlistIds.toList())});');
    }
  }

  Future<void> _onMessage(String raw) async {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    switch (m['type']) {
      case 'ready':
        _ready = true;
        _push();
        break;
      case 'height':
        final h = (m['h'] as num).toDouble();
        if (mounted && h > 0 && (h - _height).abs() > 1) setState(() => _height = h);
        break;
      case 'open':
        widget.onOpen?.call('${m['id']}');
        break;
      case 'viewAll':
        widget.onViewAll?.call();
        break;
      case 'wishlist':
        HapticFeedback.selectionClick();
        widget.onWishlist?.call('${m['id']}');
        break;
      case 'notify':
        widget.onNotify?.call('${m['id']}', '${m['variantId']}');
        break;
      case 'add':
        HapticFeedback.lightImpact();
        final ok = await (widget.onAdd?.call('${m['id']}', '${m['variantId']}') ?? Future.value(false));
        if (ok) _c.runJavaScript('addedOk();');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    // page is designed at 390 px wide (viewport meta) and scales to the screen width
    final w = MediaQuery.of(context).size.width;
    final h = _height == 0 ? w * 1.55 : _height * w / 390;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: h,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: WebViewWidget(
        controller: _c,
        // let taps reach the page, but keep vertical scroll for the home page
        gestureRecognizers: {Factory<TapGestureRecognizer>(() => TapGestureRecognizer())},
      ),
    );
  }
}
