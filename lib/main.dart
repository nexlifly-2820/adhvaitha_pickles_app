import 'profile_extras.dart' show isActiveOrder;
import 'models.dart';
import 'order_manager.dart';
import 'wishlist_manager.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'home_page.dart';
import 'wishlist_page.dart';
import 'profile_page.dart';
import 'splash_screen.dart';
import 'categories_page.dart';
import 'order_history_page.dart';
import 'cart_manager.dart';
import 'cart_page.dart';
import 'navigation_util.dart';
import 'product_manager.dart';
import 'notification_manager.dart';
import 'user_manager.dart';
import 'widgets/tab_transition_video_overlay.dart';
import 'widgets/cart_bar.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Managers
  await UserManager().init(); // who is signed in (saved on the phone)
  NotificationManager().init(); // not awaited: the permission prompt must not hold up the splash screen
  ProductManager().init();
  
  // Background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adhvaitha Pickles',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF8E8),
        primaryColor: const Color(0xFF18453B),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18453B),
          primary: const Color(0xFF18453B),
          secondary: const Color(0xFFD4AF37),
          surface: const Color(0xFFFFF8E8),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF2D1B12),
        ),
        textTheme: GoogleFonts.philosopherTextTheme(
          const TextTheme(
            displayLarge: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B)),
            headlineLarge: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B)),
            titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D1B12)),
            bodyMedium: TextStyle(color: Color(0xFF2D1B12)),
          ),
        ).copyWith(
          bodyLarge: GoogleFonts.poppins(color: const Color(0xFF2D1B12)),
          bodyMedium: GoogleFonts.poppins(color: const Color(0xFF2D1B12)),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFFFF8E8),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.philosopher(
            color: const Color(0xFF18453B),
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF18453B)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static _MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainScreenState>() ?? instance;

  /// the live main screen, so any page (even one opened above it) can switch tabs
  static _MainScreenState? instance;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// One tab of the bottom bar (order, name and visibility come from Admin → App Bottom Bar).
class NavTab {
  final String id, label;
  final bool enabled;
  const NavTab(this.id, this.label, {this.enabled = true});
}

// pages stay at fixed places so each tab keeps its own history
const List<String> _kPages = <String>['home', 'shop', 'wishlist', 'orders', 'profile', 'cart'];
// old tab numbers used around the app: 0 Home · 1 Shop · 2 Wishlist · 3 Orders · 4 Profile
const List<String> _kLegacy = <String>['home', 'shop', 'wishlist', 'orders', 'profile'];
const List<NavTab> _kDefaultTabs = <NavTab>[
  NavTab('home', 'Home'),
  NavTab('shop', 'Shop'),
  NavTab('wishlist', 'Wishlist'),
  NavTab('cart', 'Cart'),
  NavTab('orders', 'Orders'),
  NavTab('profile', 'Profile'),
];

class _MainScreenState extends State<MainScreen> {
  String _selected = 'home';
  int _pulse = 0; // bubble pop on every tap
  List<NavTab> _tabs = _kDefaultTabs;
  String _ordersSeen = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MainScreen.instance = this;
  }

  @override
  void initState() {
    super.initState();
    _loadTabs();
    SharedPreferences.getInstance().then((SharedPreferences p) {
      if (mounted) setState(() => _ordersSeen = p.getString('aj_orders_seen') ?? '');
    }).catchError((_) {});
  }

  Future<void> _loadTabs() async {
    try {
      final Map<String, dynamic> d = await ApiService.getAppConfig('bottom_nav');
      final List<dynamic> items = d['items'] is List ? d['items'] as List<dynamic> : <dynamic>[];
      if (items.isEmpty) return;
      final List<NavTab> list = <NavTab>[];
      for (final dynamic x in items) {
        if (x is! Map) continue;
        final String id = '${x['id'] ?? ''}';
        if (!_kPages.contains(id) || list.any((NavTab t) => t.id == id)) continue;
        final String label = '${x['label'] ?? ''}'.trim();
        list.add(NavTab(id, label.isEmpty ? _kDefaultTabs.firstWhere((NavTab t) => t.id == id).label : label,
            enabled: id == 'home' || x['enabled'] != false));
      }
      final List<NavTab> shown = list.where((NavTab t) => t.enabled).toList();
      if (shown.length < 3 || !shown.any((NavTab t) => t.id == 'home')) return;
      if (mounted) {
        setState(() {
          _tabs = shown.take(6).toList();
          if (!_tabs.any((NavTab t) => t.id == _selected)) _selected = 'home';
        });
      }
    } catch (_) {}
  }

  bool _isTransitioning = false;

  final Map<String, GlobalKey<NavigatorState>> _navigatorKeys = <String, GlobalKey<NavigatorState>>{
    for (final String id in _kPages) id: GlobalKey<NavigatorState>(),
  };

  /// Old API (numbers): 0 Home · 1 Shop · 2 Wishlist · 3 Orders · 4 Profile
  void setIndex(int index) {
    if (index < 0 || index >= _kLegacy.length) return;
    selectTab(_kLegacy[index]);
  }

  void selectTab(String id) {
    if (!_kPages.contains(id)) return;
    setState(() => _pulse++);
    if (_selected == id) {
      HapticFeedback.selectionClick();
      final NavigatorState? nav = _navigatorKeys[id]?.currentState;
      if (nav != null && nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
      } else if (id == 'home') {
        HomePage.scrollToTop?.call(); // tap Home again → back to the top
      }
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _selected = id;
      _isTransitioning = true;
    });
    if (id == 'orders') _markOrdersSeen();
  }

  // ───── green dot on Orders while an order is on its way (until they open Orders) ─────
  String get _ordersSig {
    final List<String> parts = OrderManager().orders.where(isActiveOrder).map((Order o) => '${o.id}:${o.status}').toList()..sort();
    return parts.join(',');
  }

  void _markOrdersSeen() {
    final String sig = _ordersSig;
    _ordersSeen = sig;
    SharedPreferences.getInstance().then((SharedPreferences p) => p.setString('aj_orders_seen', sig)).catchError((_) => true);
  }

  void _onTransitionComplete() {
    if (mounted && _isTransitioning) {
      setState(() => _isTransitioning = false);
    }
  }

  Widget _pageFor(String id) {
    switch (id) {
      case 'shop':
        return const CategoriesPage();
      case 'wishlist':
        return const WishlistPage();
      case 'orders':
        return const OrderHistoryPage();
      case 'profile':
        return const ProfilePage();
      case 'cart':
        return const CartPage();
      default:
        return const HomePage();
    }
  }

  Widget _buildTab(String id) {
    return Navigator(
      key: _navigatorKeys[id],
      onGenerateRoute: (settings) => PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _pageFor(id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final NavigatorState? currentNavigator = _navigatorKeys[_selected]?.currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        } else {
          if (_selected != 'home') {
            setState(() => _selected = 'home');
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _kPages.indexOf(_selected),
              children: [for (final String id in _kPages) _buildTab(id)],
            ),
            TabTransitionVideoOverlay(
              isVisible: _isTransitioning,
              onTransitionComplete: _onTransitionComplete,
            ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[CartManager(), WishlistManager(), OrderManager()]),
          builder: (BuildContext context, _) {
            final String sig = _ordersSig;
            if (_selected == 'orders' && sig != _ordersSeen) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _markOrdersSeen());
            }
            return CustomBottomNavBar(
              tabs: _tabs,
              selectedId: _selected,
              pulse: _pulse,
              onTabSelected: selectTab,
              badges: <String, int>{
                'cart': CartManager().itemCount,
                'wishlist': WishlistManager().items.length,
              },
              dots: <String>{if (sig.isNotEmpty && sig != _ordersSeen && _selected != 'orders') 'orders'},
            );
          },
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final List<NavTab> tabs;
  final String selectedId;
  final int pulse;
  final ValueChanged<String> onTabSelected;
  final Map<String, int> badges;
  final Set<String> dots;

  const CustomBottomNavBar({
    super.key,
    required this.tabs,
    required this.selectedId,
    required this.onTabSelected,
    this.pulse = 0,
    this.badges = const <String, int>{},
    this.dots = const <String>{},
  });

  static const Map<String, List<IconData>> _icons = <String, List<IconData>>{
    'home': <IconData>[Icons.home_outlined, Icons.home_rounded],
    'shop': <IconData>[Icons.grid_view_outlined, Icons.widgets_rounded],
    'wishlist': <IconData>[Icons.favorite_border_rounded, Icons.favorite_rounded],
    'cart': <IconData>[Icons.shopping_cart_outlined, Icons.shopping_cart_rounded],
    'orders': <IconData>[Icons.local_shipping_outlined, Icons.local_shipping_rounded],
    'profile': <IconData>[Icons.person_outline_rounded, Icons.person_rounded],
  };

  Widget _badge(String id, {double top = -6, double right = -10}) {
    final int n = badges[id] ?? 0;
    if (n > 0) {
      return Positioned(
        top: top,
        right: right,
        child: Container(
          constraints: const BoxConstraints(minWidth: 17),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: id == 'wishlist' ? const Color(0xFFC2185B) : const Color(0xFFC62828),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFFDF8), width: 1.6),
          ),
          child: Text(n > 99 ? '99+' : '$n',
              textAlign: TextAlign.center, style: GoogleFonts.poppins(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, height: 1.3)),
        ),
      );
    }
    if (dots.contains(id)) {
      return Positioned(
        top: -2,
        right: -4,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF2E9E5B),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFFDF8), width: 1.6),
            boxShadow: <BoxShadow>[BoxShadow(color: const Color(0xFF2E9E5B).withValues(alpha: .45), blurRadius: 6, spreadRadius: 1)],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final List<NavTab> items = tabs.isEmpty ? _kDefaultTabs : tabs;
    final int n = items.length;
    final int selectedIndex = items.indexWhere((NavTab t) => t.id == selectedId).clamp(0, n - 1);
    final NavTab active = items[selectedIndex];

    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalMargin = 16.0;
    final barWidth = screenWidth - (horizontalMargin * 2);
    final itemWidth = barWidth / n;
    final double buttonRadius = n >= 6 ? 33.0 : 37.0;
    final double labelSize = n >= 6 ? 10.0 : 11.0;
    final activeLeft = (itemWidth * selectedIndex) + (itemWidth / 2) - buttonRadius;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: globalCartBar,
                builder: (context, child) {
                  if (globalCartBar.count == 0 || selectedId == 'cart') return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CartBar(
                      controller: globalCartBar,
                      onViewCart: () => onTabSelected('cart'),
                    ),
                  );
                },
              ),
              SizedBox(
                height: 84,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. MAIN PILL BAR CONTAINER (Positioned at bottom)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 64,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFFDF8),
                          Color(0xFFFFF9EE),
                          Color(0xFFFFFDF8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(36),
                      border: Border.all(
                        color: const Color(0xFFE2C482).withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF18453B).withValues(alpha: 0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Stack(
                        children: [
                          // Left Decorative Leaf Art
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: 50,
                            child: CustomPaint(
                              painter: LeafFlourishPainter(isLeft: true),
                            ),
                          ),

                          // Right Decorative Leaf Art
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 50,
                            child: CustomPaint(
                              painter: LeafFlourishPainter(isLeft: false),
                            ),
                          ),

                          // Row of Inactive / Tap Items
                          Row(
                            children: List.generate(n, (index) {
                              final NavTab item = items[index];
                              final isSelected = index == selectedIndex;

                              return Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => onTabSelected(item.id),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: isSelected ? 0.0 : 1.0,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Icon(
                                              (_icons[item.id] ?? _icons['home']!)[0],
                                              color: const Color(0xFF18453B),
                                              size: 24,
                                            ),
                                            _badge(item.id),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.fade,
                                          softWrap: false,
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF18453B),
                                            fontWeight: FontWeight.w600,
                                            fontSize: labelSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. ACTIVE FLOATING POP-OUT CIRCLE BUTTON
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  left: activeLeft,
                  top: n >= 6 ? 4 : 0, // Pops out above the main bar top!
                  child: GestureDetector(
                    onTap: () => onTabSelected(active.id),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<String>('pop-${active.id}-$pulse'),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOut,
                      builder: (BuildContext context, double t, Widget? child) =>
                          Transform.scale(scale: 1 + 0.12 * math.sin(math.pi * t), child: child),
                      child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                    Container(
                      width: buttonRadius * 2,
                      height: buttonRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0F382C), // Deep forest green
                        border: Border.all(
                          color: const Color(0xFFE5C778), // Golden ring
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: const Color(0xFF0F382C).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 2),
                            Icon(
                              (_icons[active.id] ?? _icons['home']!)[1],
                              color: Colors.white,
                              size: n >= 6 ? 22 : 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              active.label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: n >= 6 ? 9.5 : 10.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Golden Indicator Line underneath text inside circle
                            Container(
                              width: 18,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5C778),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _badge(active.id, top: -2, right: -2),
                      ],
                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class LeafFlourishPainter extends CustomPainter {
  final bool isLeft;
  LeafFlourishPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8AC6C).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    canvas.save();
    if (!isLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    // Stem path
    final stemPath = Path();
    stemPath.moveTo(8, size.height * 0.75);
    stemPath.quadraticBezierTo(
      size.width * 0.5, size.height * 0.6,
      size.width * 0.8, size.height * 0.25,
    );
    canvas.drawPath(stemPath, paint);

    // Leaf 1
    final leaf1 = Path()
      ..moveTo(size.width * 0.35, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.35, size.width * 0.45, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.45, size.width * 0.35, size.height * 0.58);
    canvas.drawPath(leaf1, fillPaint);
    canvas.drawPath(leaf1, paint);

    // Leaf 2
    final leaf2 = Path()
      ..moveTo(size.width * 0.55, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.2, size.width * 0.82, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.68, size.height * 0.48, size.width * 0.55, size.height * 0.42);
    canvas.drawPath(leaf2, fillPaint);
    canvas.drawPath(leaf2, paint);

    // Small accent dot
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.42), 1.5, paint..style = PaintingStyle.fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LeafFlourishPainter oldDelegate) => oldDelegate.isLeft != isLeft;
}

class GlobalCartBadge extends StatelessWidget {
  const GlobalCartBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartManager(),
      builder: (context, _) {
        int count = CartManager().items.fold(0, (sum, item) => sum + item.quantity);
        return Padding(
          padding: const EdgeInsets.only(right: 14, top: 8, bottom: 8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  AppNavigator.push(context, CartPage());
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Color(0xFFD4AF37),
                    size: 20,
                  ),
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ).animate().scale(curve: Curves.elasticOut),
            ],
          ),
        );
      },
    );
  }
}
