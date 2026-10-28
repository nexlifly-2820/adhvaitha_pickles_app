// spice_grinder_webview.dart
// "Fresh ground spices" — renders the interactive HTML animation (assets/spice_widget.html) inside a WebView.
// Connected live to AppConfigRepository and CartManager.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models.dart';
import '../cart_manager.dart';
import '../product_detail_page.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../product_manager.dart';
import '../app_config_repository.dart';

class SpiceGrinderWebView extends StatefulWidget {
  final ValueChanged<String>? onOpen;
  final Future<bool> Function(String productId, String variantId)? onAdd;
  final void Function(String productId, String variantId)? onNotify;
  final ValueChanged<String>? onWishlist;
  final Set<String> wishlistIds;
  final VoidCallback? onViewAll;

  const SpiceGrinderWebView({
    super.key,
    this.onOpen,
    this.onAdd,
    this.onNotify,
    this.onWishlist,
    this.wishlistIds = const {},
    this.onViewAll,
  });

  @override
  State<SpiceGrinderWebView> createState() => _SpiceGrinderWebViewState();
}

class _SpiceGrinderWebViewState extends State<SpiceGrinderWebView> {
  late final WebViewController _c;
  double _height = 0;
  bool _ready = false, _hidden = false;
  String? _json;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'SpiceBridge',
        onMessageReceived: (m) => _onMessage(m.message),
      )
      ..loadFlutterAsset('assets/spice_widget.html');

    _listenToSpicesConfig();
  }

  void _listenToSpicesConfig() {
    _sub = AppConfigRepository().getSpicesStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final enabled = (data['settings'] ?? {})['enabled'] ?? true;
        if (enabled == false || (data['products'] as List? ?? []).isEmpty) {
          setState(() => _hidden = true);
          return;
        }
        setState(() {
          _hidden = false;
          _json = jsonEncode(data);
        });
        _push();
      }
    });
  }

  void _push() {
    if (!_ready || _json == null) return;
    _c.runJavaScript('loadSpices($_json);');
    _c.runJavaScript(
        'setWishlist(${jsonEncode(widget.wishlistIds.toList())});');
  }

  @override
  void didUpdateWidget(covariant SpiceGrinderWebView old) {
    super.didUpdateWidget(old);
    if (_ready && !setEquals(old.wishlistIds, widget.wishlistIds)) {
      _c.runJavaScript(
          'setWishlist(${jsonEncode(widget.wishlistIds.toList())});');
    }
  }

  Future<void> _onMessage(String raw) async {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      switch (m['type']) {
        case 'ready':
          _ready = true;
          _push();
          break;
        case 'height':
          final h = (m['h'] as num).toDouble();
          if (mounted && h > 0 && (h - _height).abs() > 1) {
            setState(() => _height = h);
          }
          break;
        case 'open':
          _openProductDetail('${m['id']}');
          break;
        case 'viewAll':
          if (widget.onViewAll != null) {
            widget.onViewAll!();
          } else {
            AppNavigator.push(
              context,
              const ProductListingPage(category: 'Spices'),
            );
          }
          break;
        case 'wishlist':
          HapticFeedback.selectionClick();
          if (widget.onWishlist != null) {
            widget.onWishlist!('${m['id']}');
          }
          break;
        case 'notify':
          widget.onNotify?.call('${m['id']}', '${m['variantId']}');
          break;
        case 'add':
          HapticFeedback.lightImpact();
          final productId = '${m['id']}';
          final variantId = '${m['variantId']}';

          bool ok = false;
          if (widget.onAdd != null) {
            ok = await widget.onAdd!(productId, variantId);
          } else {
            ok = await _defaultAddToCart(productId, variantId);
          }

          if (ok) {
            _c.runJavaScript('addedOk();');
          }
          break;
      }
    } catch (e) {
      debugPrint('Error handling WebView message: $e');
    }
  }

  Future<bool> _defaultAddToCart(String productId, String variantId) async {
    final allProducts = ProductManager().products;
    final match = allProducts.firstWhere(
      (p) =>
          p.name.toLowerCase().contains(productId.toLowerCase()) ||
          productId.toLowerCase().contains(p.name.toLowerCase()),
      orElse: () => Product(
        name: 'Moringa Karam Podi',
        description: 'Freshly ground spice powder',
        weightPriceMap: {'100g': 129.0},
        rating: 4.8,
        image: 'assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg',
        color: const Color(0xFF6B7A2A),
        category: 'Spices',
        secretIngredient: IngredientDetail(
          name: 'Fresh Ingredients',
          description: 'Stone ground blend',
          image: 'assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg',
        ),
      ),
    );

    CartManager().addToCart(match, weight: '100g');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${match.name} added to cart!'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return true;
  }

  void _openProductDetail(String productId) {
    HapticFeedback.lightImpact();
    if (widget.onOpen != null) {
      widget.onOpen!(productId);
      return;
    }

    final allProducts = ProductManager().products;
    Product? match;
    if (allProducts.isNotEmpty) {
      match = allProducts.firstWhere(
        (p) =>
            p.name.toLowerCase().contains(productId.toLowerCase()) ||
            productId.toLowerCase().contains(p.name.toLowerCase()),
        orElse: () => allProducts.first,
      );
    }

    if (match != null) {
      AppNavigator.push(
          context, ProductDetailPage(product: match, allProducts: allProducts));
    } else {
      AppNavigator.push(context, const ProductListingPage(category: 'Spices'));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    final w = MediaQuery.of(context).size.width;
    final h = _height == 0 ? w * 1.55 : _height * w / 390;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: h,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: WebViewWidget(
        controller: _c,
        gestureRecognizers: {
          Factory<TapGestureRecognizer>(() => TapGestureRecognizer())
        },
      ),
    );
  }
}
