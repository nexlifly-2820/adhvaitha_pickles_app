import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_page.dart';
import 'wishlist_page.dart';
import 'profile_page.dart';
import 'splash_screen.dart';
import 'categories_page.dart';
import 'order_history_page.dart';

void main() {
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
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30, offset: const Offset(0, -10)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18453B) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF18453B).withOpacity(0.4),
              size: isSelected ? 26 : 24,
            ),
            if (isSelected)
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 0.5
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          ],
        ),
      ),
    );
  }
}
