import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_manager.dart';
import 'recently_viewed_store.dart';
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
  String _token = ''; // login token from our server (proves who this customer is)

  String get token => _token;
  bool get hasSession => _loggedIn && _token.isNotEmpty;
  /// Headers for calls to our server that need the logged-in customer.
  Map<String, String> get authHeaders => <String, String>{'Content-Type': 'application/json', if (_token.isNotEmpty) 'Authorization': 'Bearer $_token'};

  String get userName {
    if (_userName.isNotEmpty) return _userName;
    final String? dn = FirebaseAuth.instance.currentUser?.displayName;
    if (dn != null && dn.trim().isNotEmpty) return dn.trim();
    return '';
  }

  String get email => _email.isNotEmpty ? _email : (FirebaseAuth.instance.currentUser?.email ?? '');
  String get phone => _phone.isNotEmpty ? _phone : (FirebaseAuth.instance.currentUser?.phoneNumber ?? '').replaceAll('+91', '');
  DateTime? get memberSince => _since ?? FirebaseAuth.instance.currentUser?.metadata.creationTime;
  bool get isLoggedIn => hasSession;

  String get currentUserId {
    if (_token.isNotEmpty && _email.trim().isNotEmpty) return 'USER-${_email.trim().toLowerCase().replaceAll('@', '_').replaceAll('.', '_')}';
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
      _token = p.getString('aj_token') ?? '';
      // logins from before the secure code check have no token → ask them to log in once more
      if (_token.isEmpty) _loggedIn = false;
      if (_userName == 'User') _userName = '';
    } catch (_) {}
    notifyListeners();
    // bring back this customer's cart and recently viewed (after the first frame, so start-up stays fast)
    Future<void>.delayed(const Duration(milliseconds: 300), syncUserData);
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('aj_user_name', _userName);
      await p.setString('aj_user_email', _email);
      await p.setString('aj_user_phone', _phone);
      await p.setBool('aj_logged_in', _loggedIn);
      await p.setString('aj_token', _token);
      if (_since != null) await p.setInt('aj_user_since', _since!.millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// After login, or when the customer edits their profile.
  Future<void> setUser({required String name, required String email, String? phone, String? token}) async {
    if (token != null && token.isNotEmpty) _token = token;
    if (name.trim().isNotEmpty && name.trim() != 'User') _userName = name.trim();
    if (email.trim().isNotEmpty) _email = email.trim();
    if (phone != null) _phone = phone.replaceAll(' ', '').trim();
    _loggedIn = true;
    _since ??= DateTime.now();
    notifyListeners();
    await _persist();
    syncUserData();

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

  /// this customer's own cart + recently viewed (phone + server)
  void syncUserData() {
    CartManager().loadForUser();
    RecentlyViewedStore().loadForUser();
  }

  Future<void> logout() async {
    CartManager().resetForLogout();
    RecentlyViewedStore().resetForLogout();
    _userName = '';
    _email = '';
    _phone = '';
    _since = null;
    _loggedIn = false;
    _token = '';
    notifyListeners();
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      for (final String k in <String>['aj_user_name', 'aj_user_email', 'aj_user_phone', 'aj_user_since', 'aj_logged_in', 'aj_token']) {
        await p.remove(k);
      }
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  void clearUser() {
    logout();
  }
}
