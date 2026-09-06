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
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.grid_view_rounded, 'Shop'),
                  _buildNavItem(2, Icons.favorite_rounded, 'Wishlist'),
                  _buildNavItem(3, Icons.local_shipping_rounded, 'Orders'),
                  _buildNavItem(4, Icons.person_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0F4D3C) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0F4D3C) : const Color(0xFF9CA3AF),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
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
                        color: Colors.black.withOpacity(0.06),
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
