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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Managers
  await NotificationManager().init();
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
      context.findAncestorStateOfType<_MainScreenState>();

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void setIndex(int index) {
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      HapticFeedback.lightImpact();
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildTab(int index, Widget child) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) => PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final NavigatorState? currentNavigator = _navigatorKeys[_selectedIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        } else {
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
          } else {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            _buildTab(0, const HomePage()),
            _buildTab(1, const CategoriesPage()),
            _buildTab(2, const WishlistPage()),
            _buildTab(3, const OrderHistoryPage()),
            _buildTab(4, const ProfilePage()),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onTabSelected: setIndex,
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {'label': 'Home', 'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded},
      {'label': 'Shop', 'icon': Icons.grid_view_outlined, 'activeIcon': Icons.widgets_rounded},
      {'label': 'Wishlist', 'icon': Icons.favorite_border_rounded, 'activeIcon': Icons.favorite_rounded},
      {'label': 'Orders', 'icon': Icons.local_shipping_outlined, 'activeIcon': Icons.local_shipping_rounded},
      {'label': 'Profile', 'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded},
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    const horizontalMargin = 16.0;
    final barWidth = screenWidth - (horizontalMargin * 2);
    final itemWidth = barWidth / 5;
    const buttonRadius = 37.0; // Button diameter = 74.0
    final activeLeft = (itemWidth * selectedIndex) + (itemWidth / 2) - buttonRadius;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 12),
          child: SizedBox(
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
                            children: List.generate(5, (index) {
                              final item = navItems[index];
                              final isSelected = index == selectedIndex;

                              return Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => onTabSelected(index),
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: isSelected ? 0.0 : 1.0,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          item['icon'] as IconData,
                                          color: const Color(0xFF18453B),
                                          size: 24,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item['label'] as String,
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF18453B),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
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
                  top: 0, // Pops out above the main bar top!
                  child: GestureDetector(
                    onTap: () => onTabSelected(selectedIndex),
                    child: Container(
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
                              navItems[selectedIndex]['activeIcon'] as IconData,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              navItems[selectedIndex]['label'] as String,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.5,
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
                  ),
                ),
              ],
            ),
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
        int count = CartManager().items.length;
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
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF18453B),
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
