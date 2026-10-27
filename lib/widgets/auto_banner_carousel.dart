// auto_banner_carousel.dart
// Auto-scrolling IMAGE banner carousel. Each banner = one image uploaded from your admin dashboard.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../product_listing_page.dart';
import '../navigation_util.dart';
import '../app_config_repository.dart';

class BannerItem {
  final String id, image;
  final Map<String, dynamic> link;
  const BannerItem({required this.id, required this.image, this.link = const {}});

  factory BannerItem.fromJson(Map<String, dynamic> j) => BannerItem(
        id: '${j['id'] ?? ''}',
        image: j['image'] ?? '',
        link: Map<String, dynamic>.from(j['link'] ?? {}),
      );
}

class AutoBannerCarousel extends StatefulWidget {
  final List<BannerItem> banners;
  final ValueChanged<BannerItem>? onTap;
  final Duration interval;
  final double aspect;

  const AutoBannerCarousel({
    super.key,
    required this.banners,
    this.onTap,
    this.interval = const Duration(milliseconds: 2500),
    this.aspect = 870 / 540,
  });

  @override
  State<AutoBannerCarousel> createState() => _AutoBannerCarouselState();
}

class _AutoBannerCarouselState extends State<AutoBannerCarousel> {
  static const _loop = 10000;
  late final PageController _pc =
      PageController(viewportFraction: .82, initialPage: _loop ~/ 2);
  Timer? _t;
  int _page = _loop ~/ 2;

  StreamSubscription? _sub;
  List<BannerItem> _liveBanners = [];

  @override
  void initState() {
    super.initState();
    _listenToBannersConfig();
    _start();
  }

  void _listenToBannersConfig() {
    _sub = AppConfigRepository().getAutoBannersStream().listen((data) {
      if (!mounted) return;
      if (data.isNotEmpty) {
        final parsed = data.map((e) => BannerItem.fromJson(e)).toList();
        if (parsed.isNotEmpty) {
          setState(() => _liveBanners = parsed);
        }
      }
    });
  }

  void _start() {
    _t?.cancel();
    _t = Timer.periodic(widget.interval, (_) {
      if (_pc.hasClients && _effectiveBanners.length > 1) {
        _pc.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _t?.cancel();
    _pc.dispose();
    super.dispose();
  }

  List<BannerItem> get _effectiveBanners {
    if (_liveBanners.isNotEmpty) {
      return _liveBanners;
    }
    if (widget.banners.isNotEmpty) {
      return widget.banners;
    }
    return defaultBanners;
  }

  Widget _buildImg(String u) {
    if (u.isEmpty) {
      return Container(color: const Color(0xFFF2EEE8));
    }
    if (u.startsWith('http')) {
      return Image.network(
        u,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, prog) =>
            prog == null ? child : Container(color: const Color(0xFFF2EEE8)),
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF2EEE8)),
      );
    }
    String assetPath = u.startsWith('assets/') ? u : 'assets/images/$u';
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF2EEE8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banners = _effectiveBanners;
    final n = banners.length;
    if (n == 0) return const SizedBox.shrink();

    final w = MediaQuery.of(context).size.width;
    final cardW = w * .82 - 12;
    final h = cardW / widget.aspect;
    final cur = _page % n;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          SizedBox(
            height: h,
            child: Listener(
              onPointerDown: (_) => _t?.cancel(),
              onPointerUp: (_) => _start(),
              child: PageView.builder(
                controller: _pc,
                itemCount: n > 1 ? _loop : 1,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (_, p) {
                  final b = banners[p % n];
                  return AnimatedBuilder(
                    animation: _pc,
                    builder: (_, child) {
                      double d = 0;
                      if (_pc.position.haveDimensions) {
                        d = ((_pc.page ?? _page.toDouble()) - p).abs().clamp(0, 1).toDouble();
                      }
                      return Transform.scale(
                        scale: 1 - .08 * d,
                        child: Opacity(
                          opacity: 1 - .15 * d,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (widget.onTap != null) {
                            widget.onTap!(b);
                          } else {
                            final category = b.link['category'] ?? 'Pickles';
                            AppNavigator.push(
                              context,
                              ProductListingPage(category: category.toString()),
                            );
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _buildImg(b.image),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (n > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < n; k++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: k == cur ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: k == cur
                          ? const Color(0xFF1B1B1B)
                          : const Color(0xFFDDDDDD),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static const List<BannerItem> defaultBanners = [
    BannerItem(id: 'b1', image: 'assets/images/banner_1.jpg', link: {'category': 'Pickles'}),
    BannerItem(id: 'b2', image: 'assets/images/banner_2.jpg', link: {'category': 'Powders'}),
    BannerItem(id: 'b3', image: 'assets/images/banner_3.jpg', link: {'category': 'Sweets'}),
    BannerItem(id: 'b4', image: 'assets/images/banner_4.jpg', link: {'category': 'Snacks'}),
  ];
}
