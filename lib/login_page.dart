import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main.dart';
import 'user_manager.dart';
import 'notification_manager.dart';
import 'address_book.dart';
import 'order_manager.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      apiBase: 'https://admin.adhvaithafoods.in/api',
      logoAsset: 'assets/images/AMBHUJAKSHI  logo.png',
      onLoggedIn: (token, user) async {
        // remember who signed in (name, email) — used by profile, orders, addresses and notifications
        await UserManager().setUser(name: '${user['name'] ?? ''}', email: '${user['email'] ?? ''}');
        AddressBook().ensureLoaded();
        OrderManager().ensureLoaded();
        NotificationManager().updateToken();
        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      },
    );
  }
}
