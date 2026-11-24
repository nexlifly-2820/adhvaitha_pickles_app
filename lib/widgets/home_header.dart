import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'category_tabs.dart';

class HeaderCategory {
  final String name;
  final String icon; // emoji like '🫙' or image URL
  final String? badge; // e.g. 'New'
  const HeaderCategory(this.name, this.icon, {this.badge});
}

class HomeHeader extends StatefulWidget {
  final String videoUrl;
  final String location;
  final String userName;
  final int cartCount;
  final List<String> searchHints;
  final List<HeaderCategory> categories;
  final int selectedCategory;
  final VoidCallback? onLocationTap;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onMicTap;
  final ValueChanged<int>? onCategoryTap;

  const HomeHeader({
    super.key,
    required this.videoUrl,
    required this.location,
    required this.userName,
    this.cartCount = 0,
    this.searchHints = const ['Search royal flavors...'],
    this.categories = const [],
    this.selectedCategory = 0,
    this.onLocationTap,
    this.onWishlistTap,
    this.onProfileTap,
    this.onCartTap,
    this.onSearchTap,
    this.onMicTap,
    this.onCategoryTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> with WidgetsBindingObserver {
  static const maroon = Color(0xFF7A0F12);
  static const maroonDark = Color(0xFF3A0406);
  static const gold = Color(0xFFF6C453);

  VideoPlayerController? _ctrl;
  Timer? _hintTimer;
  int _hint = 0;
  bool _isInitialized = false;
  bool _isVisible = true;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[HomeHeader] initState with videoUrl: ${widget.videoUrl}');
    _initVideo(widget.videoUrl);
    _hintTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || widget.searchHints.isEmpty) return;
      setState(() => _hint = (_hint + 1) % widget.searchHints.length);
    });
  }

  @override
  void didUpdateWidget(covariant HomeHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('[HomeHeader] didUpdateWidget old: ${oldWidget.videoUrl}, new: ${widget.videoUrl}');
    if (oldWidget.videoUrl != widget.videoUrl) {
      _initVideo(widget.videoUrl);
    }
  }

  int _attempt = 0;

  Future<void> _initVideo(String url, {bool isRetry = false}) async {
    url = url.trim();
    debugPrint('[HomeHeader] _initVideo: "$url" (retry: $isRetry)');
    // empty = settings not loaded yet -> keep the red poster, load nothing
    if (url.isEmpty) return;
    if (url == _currentUrl && _ctrl != null && _isInitialized) return;
    _currentUrl = url;
    if (!isRetry) _attempt = 0;

    final VideoPlayerController? old = _ctrl;
    _ctrl = null;
    if (mounted) setState(() => _isInitialized = false);
    await old?.dispose();

    final bool isNetwork = url.startsWith('http');
    final String assetPath = isNetwork || url.startsWith('assets/') ? url : 'assets/images/$url';
    final VideoPlayerController c = isNetwork
        ? VideoPlayerController.networkUrl(Uri.parse(url),
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true))
        : VideoPlayerController.asset(assetPath,
            videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
    _ctrl = c;

    try {
      await c.initialize().timeout(const Duration(seconds: 25));
      if (!mounted || _ctrl != c) return;
      await c.setVolume(0);
      await c.setLooping(true);
      await c.play();
      if (mounted && _ctrl == c) setState(() => _isInitialized = true);
      debugPrint('[HomeHeader] playing ${c.value.size}');
    } catch (e) {
      debugPrint('[HomeHeader] init error: $e');
      if (!mounted || _ctrl != c) return;
      // The phone's video decoder may be busy with another video for a moment:
      // retry the SAME video a few times instead of loading a heavy fallback.
      if (_attempt < 3) {
        _attempt++;
        _currentUrl = '';
        final VideoPlayerController failed = c;
        _ctrl = null;
        await failed.dispose().catchError((Object _) {});
        await Future<void>.delayed(Duration(seconds: 2 * _attempt));
        if (mounted && _ctrl == null) _initVideo(url, isRetry: true);
      }
      // after 3 retries the red poster stays (no crash, no loop)
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ctrl == null || !_isInitialized) return;
    if (state == AppLifecycleState.resumed && _isVisible) {
      _ctrl?.play();
    } else {
      _ctrl?.pause();
    }
  }

  @override
  void dispose() {
    debugPrint('[HomeHeader] dispose');
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 👋';
    if (h < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final s = w / 390;
    final statusBar = MediaQuery.of(context).padding.top;

    return VisibilityDetector(
      key: ValueKey<String>('home_header_video_${widget.videoUrl}'),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0;
        if (visible != _isVisible) {
          _isVisible = visible;
          debugPrint('[HomeHeader] visibility changed: $visible');
          if (_ctrl != null && _isInitialized) {
            if (visible) {
              _ctrl?.play();
            } else {
              _ctrl?.pause();
            }
          }
        }
      },
      child: Container(
        color: maroon,
        padding: EdgeInsets.only(top: statusBar),
        child: SizedBox(
          width: w,
          height: 420 * s,
          child: Stack(
            children: [
              // Poster background (Red gradient)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, .45),
                      radius: 1.1,
                      colors: [Color(0xFFC4262B), maroon, maroonDark],
                      stops: [0, .5, 1],
                    ),
                  ),
                ),
              ),
              // Video Player with AnimatedOpacity fade-in
              if (_isInitialized && _ctrl != null)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _isInitialized ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: _ctrl!.value.size.width > 0 ? _ctrl!.value.size.width : 1600,
                        height: _ctrl!.value.size.height > 0 ? _ctrl!.value.size.height : 900,
                        child: VideoPlayer(_ctrl!),
                      ),
                    ),
                  ),
                ),
              Positioned(top: 22 * s, left: 16 * s, right: 16 * s, child: _topRow(s)),
              Positioned(top: 110 * s, left: 16 * s, right: 16 * s, height: 50 * s, child: _searchBar(s)),
              Positioned(top: 176 * s, left: 10 * s, right: 10 * s, child: _categoryRow(s)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topRow(double s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: widget.onLocationTap,
                child: Row(children: [
                  Icon(Icons.location_on, color: gold, size: 14 * s),
                  SizedBox(width: 2 * s),
                  Flexible(
                    child: Text(widget.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: gold, fontSize: 12 * s, fontWeight: FontWeight.w700)),
                  ),
                  Icon(Icons.arrow_drop_down, color: gold, size: 18 * s),
                ]),
              ),
              SizedBox(height: 2 * s),
              Text(_greeting, style: TextStyle(color: Colors.white70, fontSize: 13 * s)),
              Text(widget.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white, fontSize: 28 * s, fontWeight: FontWeight.w900, height: 1.15)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(children: [
              _circleIcon(Icons.favorite_border, widget.onWishlistTap, s),
              SizedBox(width: 8 * s),
              _circleIcon(Icons.person_outline, widget.onProfileTap, s),
              SizedBox(width: 8 * s),
              Badge(
                isLabelVisible: widget.cartCount > 0,
                label: Text('${widget.cartCount}'),
                backgroundColor: const Color(0xFF1F7A34),
                child: _circleIcon(Icons.shopping_bag_outlined, widget.onCartTap, s),
              ),
            ]),
            SizedBox(height: 10 * s),
            Text('Taste Tradition Every Day',
                style: TextStyle(
                    color: gold, fontSize: 12 * s, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback? onTap, double s) {
    return InkResponse(
      onTap: onTap,
      radius: 24 * s,
      child: Container(
        width: 40 * s,
        height: 40 * s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(.35),
          border: Border.all(color: gold.withOpacity(.45)),
        ),
        child: Icon(icon, color: Colors.white, size: 20 * s),
      ),
    );
  }

  Widget _searchBar(double s) {
    final hint = widget.searchHints.isEmpty ? 'Search' : widget.searchHints[_hint % widget.searchHints.length];
    return GestureDetector(
      onTap: widget.onSearchTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14 * s),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Row(children: [
          Icon(Icons.search, color: Colors.black54, size: 22 * s),
          SizedBox(width: 10 * s),
          Expanded(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween(begin: const Offset(0, .8), end: Offset.zero).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Align(
                  key: ValueKey(hint),
                  alignment: Alignment.centerLeft,
                  child: Text(hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.black54, fontSize: 15 * s)),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 22 * s, color: Colors.black12),
          IconButton(
            onPressed: widget.onMicTap,
            icon: Icon(Icons.mic_none, color: Colors.black54, size: 22 * s),
          ),
        ]),
      ),
    );
  }

  Widget _categoryRow(double s) {
    return CategoryTabs(
      apiBase: 'https://admin.adhvaithafoods.in/api',
      initialSlug: widget.categories.isNotEmpty && widget.selectedCategory < widget.categories.length
          ? widget.categories[widget.selectedCategory].name.toLowerCase()
          : 'all',
      onChanged: (tab) {
        final idx = widget.categories.indexWhere((c) => c.name.toLowerCase() == tab.slug.toLowerCase() || c.name.toLowerCase() == tab.label.toLowerCase());
        if (idx >= 0) {
          widget.onCategoryTap?.call(idx);
        } else {
          widget.onCategoryTap?.call(0);
        }
      },
    );
  }
}
