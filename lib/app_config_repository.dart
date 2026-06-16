import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Banners & Ad Banners
  Stream<Map<String, List<Map<String, String>>>> getBannersStream() {
    return _firestore.collection('app_data').doc('banners').snapshots().map((snapshot) {
      if (!snapshot.exists) return {'main': [], 'ad': []};
      final data = snapshot.data() ?? {};
      final List<dynamic> mainRaw = data['main_banners'] ?? [];
      final List<dynamic> adRaw = data['ad_banners'] ?? [];
      return {
        'main': mainRaw.map((item) => Map<String, String>.from(item)).toList(),
        'ad': adRaw.map((item) => Map<String, String>.from(item)).toList(),
      };
    });
  }

  // 2. Stories Section (Packaging, Origin, etc.)
  Stream<List<Map<String, dynamic>>> getStoriesStream() {
    return _firestore.collection('app_data').doc('stories').snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final List<dynamic> data = snapshot.data()?['list'] ?? [];
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    });
  }

  // 3. Bento Selection (Today's Selection)
  Stream<Map<String, dynamic>> getBentoConfigStream() {
    return _firestore.collection('app_data').doc('bento_selection').snapshots().map((snapshot) {
      return snapshot.data() ?? {};
    });
  }

  // 4. Coupons
  Stream<List<Map<String, dynamic>>> getCouponsStream() {
    return _firestore.collection('app_data').doc('coupons').snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final List<dynamic> data = snapshot.data()?['active_list'] ?? [];
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    });
  }

  // 5. Deals of the Day
  Stream<List<String>> getDealsStream() {
    return _firestore.collection('app_data').doc('deals').snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final List<dynamic> data = snapshot.data()?['product_names'] ?? [];
      return data.map((item) => item.toString()).toList();
    });
  }

  // 6. Royal Packaging Section
  Stream<List<Map<String, String>>> getPackagingStream() {
    return _firestore.collection('app_data').doc('packaging').snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final List<dynamic> data = snapshot.data()?['list'] ?? [];
      return data.map((item) => Map<String, String>.from(item)).toList();
    });
  }

  // 7. Categories Section
  Stream<List<Map<String, String>>> getCategoriesStream() {
    return _firestore.collection('app_data').doc('categories').snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final List<dynamic> data = snapshot.data()?['list'] ?? [];
      return data.map((item) => Map<String, String>.from(item)).toList();
    });
  }

  // 8. Onboarding Section
  Stream<List<Map<String, String>>> getOnboardingStream() {
    return _firestore.collection('app_data').doc('onboarding').snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final List<dynamic> data = snapshot.data()?['steps'] ?? [];
      return data.map((item) => Map<String, String>.from(item)).toList();
    });
  }

  // 9. Taste Personalizer Options
  Stream<List<Map<String, dynamic>>> getTasteOptionsStream() {
    return _firestore.collection('app_data').doc('onboarding').snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final List<dynamic> data = snapshot.data()?['taste_options'] ?? [];
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    });
  }

  // 10. App State (Maintenance/Version)
  Stream<Map<String, dynamic>> getAppStateStream() {
    return _firestore.collection('app_data').doc('config').snapshots().map((snapshot) {
      return snapshot.data() ?? {'maintenance_mode': false, 'min_version': '1.0.0'};
    });
  }
}
