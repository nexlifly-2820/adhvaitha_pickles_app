import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      apiBase: 'https://admin.adhvaithafoods.in/api',
      logoAsset: 'assets/images/AMBHUJAKSHI  logo.png',
      onLoggedIn: (token, user) async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      },
    );
  }
}
