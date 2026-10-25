import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class UserManager extends ChangeNotifier {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  String _userName = "HEMANTH SILLA";
  String _email = "hemanth.s@example.com";

  String get userName => _userName;
  String get email => _email;

  String get currentUserId {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      return firebaseUid;
    }
    if (_email.isNotEmpty && _email != "hemanth.s@example.com") {
      return 'USER-${_email.replaceAll('@', '_').replaceAll('.', '_')}';
    }
    return "demo_user_123";
  }

  Future<void> setUser({required String name, required String email}) async {
    if (name.trim().isNotEmpty) {
      _userName = name.trim().toUpperCase();
    }
    if (email.trim().isNotEmpty) {
      _email = email.trim();
    }
    notifyListeners();

    // Sync to backend database so orders connect to the correct user
    try {
      final String userId = 'USER-${_email.replaceAll('@', '_').replaceAll('.', '_')}';
      debugPrint("Syncing user to database: userId=$userId, name=$_userName, email=$_email");
      final success = await ApiService.saveUser(
        userId: userId,
        phone: _email,
        extraData: {
          'name': _userName,
          'email': _email,
        },
      );
      debugPrint("User database sync result: $success");
    } catch (e) {
      debugPrint("Error syncing user to database: $e");
    }
  }

  void clearUser() {
    _userName = "Guest";
    _email = "";
    notifyListeners();
  }
}
