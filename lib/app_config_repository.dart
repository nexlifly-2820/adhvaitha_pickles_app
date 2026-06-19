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
  Stream<Map<String, dynamic>> getDealsStream() {
    return _firestore.collection('app_data').doc('deals').snapshots().map((snapshot) {
      if (!snapshot.exists) return {'product_names': [], 'end_time': Timestamp.now()};
      return snapshot.data() ?? {'product_names': [], 'end_time': Timestamp.now()};
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
      if (!snapshot.exists) {
        print('DEBUG: Categories document does not exist in Firestore');
        return [];
      }
      final List<dynamic> data = snapshot.data()?['list'] ?? [];
      print('DEBUG: Fetched ${data.length} categories from Firestore');
      return data.map((item) {
        final map = item as Map<String, dynamic>;
        return {
          'label': map['label']?.toString() ?? '',
          'img': map['img']?.toString() ?? '',
        };
      }).toList();
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

  // 10. App State (Maintenance/Version/Inventory)
  Stream<Map<String, dynamic>> getAppStateStream() {
    return _firestore.collection('app_data').doc('config').snapshots().map((snapshot) {
      return snapshot.data() ?? {
        'maintenance_mode': false, 
        'min_version': '1.0.0',
        'inventory_threshold': 10
      };
    });
  }

  // 11. Delivery Configuration
  Stream<Map<String, dynamic>> getDeliveryConfigStream() {
    return _firestore.collection('app_data').doc('delivery_config').snapshots().map((snapshot) {
      if (!snapshot.exists) return {'base_fee': 40.0, 'free_threshold': 500.0};
      return snapshot.data()!;
    });
  }

  // 12. Perfect Pairings
  Stream<List<Map<String, String>>> getPairingsStream() {
    return _firestore.collection('app_data').doc('pairings').snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final List<dynamic> data = snapshot.data()?['list'] ?? [];
      return data.map((item) => Map<String, String>.from(item)).toList();
    });
  }

  // 13. Heritage Story Banner
  Stream<Map<String, String>> getHeritageBannerStream() {
    return _firestore.collection('app_data').doc('heritage_banner').snapshots().map((snapshot) {
      if (!snapshot.exists) return {};
      return Map<String, String>.from(snapshot.data() ?? {});
    });
  }

  // 14. Trending Searches
  Stream<List<String>> getTrendingSearchesStream() {
    return _firestore.collection('app_data').doc('search_config').snapshots().map((snapshot) {
      if (!snapshot.exists) return ['Mango Special', 'New Snacks', 'Spicy Chicken', 'Ladoo', 'Combos'];
      final List<dynamic> data = snapshot.data()?['trending_keywords'] ?? [];
      return data.map((item) => item.toString()).toList();
    });
  }
}
