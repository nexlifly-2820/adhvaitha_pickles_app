import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class HeaderCategory {
  final String name;
  final String icon; // emoji like '🫙' or image URL
  final String? badge; // e.g. 'New'
  const HeaderCategory(this.name, this.icon, {this.badge});
}

class HomeHeader extends StatefulWidget {
  /// 'assets/videos/xxx.mp4' or an https:// URL coming from your backend.
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

class _HomeHeaderState extends State<HomeHeader> {
  static const maroon = Color(0xFF7A0F12);
  static const maroonDark = Color(0xFF3A0406);
  static const gold = Color(0xFFF6C453);

  VideoPlayerController? _ctrl;
  Timer? _hintTimer;
  int _hint = 0;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _hintTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || widget.searchHints.isEmpty) return;
      setState(() => _hint = (_hint + 1) % widget.searchHints.length);
    });
  }

  void _initVideo() {
    final url = widget.videoUrl;
    if (url.isEmpty) return;
    
    final opts = VideoPlayerOptions(mixWithOthers: true);
    final c = url.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(url), videoPlayerOptions: opts)
        : VideoPlayerController.asset(url, videoPlayerOptions: opts);
    _ctrl = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c
        ..setVolume(0)
        ..setLooping(true)
        ..play();
      setState(() {});
    }).catchError((_) {/* falls back to gradient */});
  }

  @override
  void didUpdateWidget(covariant HomeHeader old) {
    super.didUpdateWidget(old);
    if (old.videoUrl != widget.videoUrl) {
      _ctrl?.dispose();
      _initVideo();
    }
  }

  @override
  void dispose() {
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
    final ready = _ctrl?.value.isInitialized ?? false;

    return Container(
      color: maroon,
      padding: EdgeInsets.only(top: statusBar),
      child: SizedBox(
        width: w,
        height: 420 * s,
        child: Stack(
          children: [
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
            if (ready)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _ctrl!.value.size.width,
                    height: _ctrl!.value.size.height,
                    child: VideoPlayer(_ctrl!),
                  ),
                ),
              ),
            Positioned(top: 22 * s, left: 16 * s, right: 16 * s, child: _topRow(s)),
            Positioned(top: 110 * s, left: 16 * s, right: 16 * s, height: 50 * s, child: _searchBar(s)),
            Positioned(top: 176 * s, left: 10 * s, right: 10 * s, child: _categoryRow(s)),
          ],
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
    final cats = widget.categories.take(6).toList();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(cats.length, (i) {
        final c = cats[i];
        final on = i == widget.selectedCategory;
        return GestureDetector(
          onTap: () => widget.onCategoryTap?.call(i),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 60 * s,
            child: Column(children: [
              Stack(clipBehavior: Clip.none, children: [
                SizedBox(
                  width: 30 * s,
                  height: 30 * s,
                  child: Center(
                    child: c.icon.startsWith('http')
                        ? Image.network(c.icon, width: 28 * s, height: 28 * s)
                        : Text(c.icon, style: TextStyle(fontSize: 24 * s)),
                  ),
                ),
                if (c.badge != null)
                  Positioned(
                    top: -8 * s,
                    right: -16 * s,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 1 * s),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE63946), borderRadius: BorderRadius.circular(6 * s)),
                      child: Text(c.badge!,
                          style: TextStyle(color: Colors.white, fontSize: 8 * s, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ]),
              SizedBox(height: 3 * s),
              Text(c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: on ? Colors.white : Colors.white.withOpacity(.85),
                    fontSize: 11.5 * s,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w400,
                  )),
              SizedBox(height: 4 * s),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: on ? 30 * s : 0,
                height: 3 * s,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(3 * s)),
              ),
            ]),
          ),
        );
      }),
    );
  }
}
