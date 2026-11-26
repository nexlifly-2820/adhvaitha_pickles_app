import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// The signed-in customer (name, email, phone). Saved on the phone so the app remembers them.
class UserManager extends ChangeNotifier {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  String _userName = '';
  String _email = '';
  String _phone = '';
  DateTime? _since;
  bool _loggedIn = false;

  String get userName {
    if (_userName.isNotEmpty) return _userName;
    final String? dn = FirebaseAuth.instance.currentUser?.displayName;
    if (dn != null && dn.trim().isNotEmpty) return dn.trim();
    return '';
  }

  String get email => _email.isNotEmpty ? _email : (FirebaseAuth.instance.currentUser?.email ?? '');
  String get phone => _phone.isNotEmpty ? _phone : (FirebaseAuth.instance.currentUser?.phoneNumber ?? '').replaceAll('+91', '');
  DateTime? get memberSince => _since ?? FirebaseAuth.instance.currentUser?.metadata.creationTime;
  bool get isLoggedIn => _loggedIn || FirebaseAuth.instance.currentUser != null;

  String get currentUserId {
    final String? firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) return firebaseUid;
    final String e = email.trim().toLowerCase();
    if (e.isNotEmpty) return 'USER-${e.replaceAll('@', '_').replaceAll('.', '_')}';
    return 'guest';
  }

  /// Call once at app start (before showing screens).
  Future<void> init() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      _userName = p.getString('aj_user_name') ?? p.getString('aj_last_name') ?? '';
      _email = p.getString('aj_user_email') ?? p.getString('aj_last_email') ?? '';
      _phone = p.getString('aj_user_phone') ?? '';
      final int? s = p.getInt('aj_user_since');
      _since = s == null ? null : DateTime.fromMillisecondsSinceEpoch(s);
      _loggedIn = p.getBool('aj_logged_in') ?? false;
      if (_userName == 'User') _userName = '';
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('aj_user_name', _userName);
      await p.setString('aj_user_email', _email);
      await p.setString('aj_user_phone', _phone);
      await p.setBool('aj_logged_in', _loggedIn);
      if (_since != null) await p.setInt('aj_user_since', _since!.millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// After login, or when the customer edits their profile.
  Future<void> setUser({required String name, required String email, String? phone}) async {
    if (name.trim().isNotEmpty && name.trim() != 'User') _userName = name.trim();
    if (email.trim().isNotEmpty) _email = email.trim();
    if (phone != null) _phone = phone.replaceAll(' ', '').trim();
    _loggedIn = true;
    _since ??= DateTime.now();
    notifyListeners();
    await _persist();

    // keep the shop's customer list up to date (best effort)
    try {
      await ApiService.saveUser(
        userId: currentUserId,
        phone: _phone.isNotEmpty ? _phone : _email,
        extraData: <String, dynamic>{'name': _userName, 'email': _email, 'phone': _phone},
      );
    } catch (e) {
      debugPrint('Error syncing user: $e');
    }
  }

  Future<void> logout() async {
    _userName = '';
    _email = '';
    _phone = '';
    _since = null;
    _loggedIn = false;
    notifyListeners();
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      for (final String k in <String>['aj_user_name', 'aj_user_email', 'aj_user_phone', 'aj_user_since', 'aj_logged_in']) {
        await p.remove(k);
      }
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  void clearUser() {
    logout();
  }
}
