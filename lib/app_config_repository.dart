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
  Stream<List<Map<String, dynamic>>> getCategoriesStream() {
    return _firestore.collection('app_data').doc('categories').snapshots().map((snapshot) {
      List<Map<String, dynamic>> finalCategories = List.from(_defaultCategories);
      
      if (snapshot.exists) {
        final List<dynamic> data = snapshot.data()?['list'] ?? [];
        if (data.isNotEmpty) {
          final List<Map<String, dynamic>> firestoreList = data.map((item) {
            final map = item as Map<String, dynamic>;
            return {
              'label': map['label']?.toString() ?? '',
              'img': map['img']?.toString() ?? '',
              'tagline': map['tagline']?.toString() ?? '',
              'badge': map['badge']?.toString() ?? '',
              'description': map['description']?.toString() ?? '',
              'banner_img': map['banner_img']?.toString() ?? '',
            };
          }).toList();

          // Merge: Firestore categories override defaults with same label
          for (var fCat in firestoreList) {
            int index = finalCategories.indexWhere((dCat) => 
              dCat['label'].toString().toLowerCase() == fCat['label'].toString().toLowerCase()
            );
            if (index != -1) {
              finalCategories[index] = fCat;
            } else {
              finalCategories.add(fCat);
            }
          }
        }
      }
      return finalCategories;
    });
  }

  static final List<Map<String, dynamic>> _defaultCategories = [
    {
      'label': 'Pickles',
      'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      'tagline': 'Traditional Sun-Dried Jars',
      'description': 'Handmade in small batches since 1982.',
    },
    {
      'label': 'Snacks',
      'img': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg',
      'tagline': 'Crispy Heritage Delights',
      'description': 'Authentic traditional snacks for every mood.',
    },
    {
      'label': 'Spices',
      'img': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
      'tagline': 'Hand-Ground Aromatic Blends',
      'description': 'Purity you can taste, heritage you can feel.',
    },
    {
      'label': 'Sweets',
      'img': 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
      'tagline': 'Ghee-Soaked Memories',
      'description': 'Traditional sweets made with pure desi cow ghee.',
    },
  ];

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

  // 15. Categories Page Hero Banner
  Stream<Map<String, dynamic>> getCategoryPageConfigStream() {
    return _firestore.collection('app_data').doc('category_page_config').snapshots().map((snapshot) {
      if (!snapshot.exists) return {
        'hero_title': 'The Royal Summer Festival',
        'hero_subtitle': 'Authentic sun-dried mango delicacies',
        'hero_image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
        'hero_tag': 'FEATURED COLLECTION'
      };
      return snapshot.data() ?? {};
    });
  }

  // 16. Cart Configuration
  Stream<Map<String, dynamic>> getCartConfigStream() {
    return _firestore.collection('app_data').doc('cart_config').snapshots().map((snapshot) {
      if (!snapshot.exists) return {
        'freshness_tagline': 'FRESHNESS GUARANTEED',
        'dispatch_reassurance': 'Order in the next 2 hrs for same-day dispatch.',
        'upsell_section_title': 'COMPLETES THE EXPERIENCE'
      };
      return snapshot.data() ?? {};
    });
  }

  // 17. Serviceable Pincodes
  Stream<List<String>> getServiceablePincodesStream() {
    return _firestore.collection('app_data').doc('serviceability').snapshots().map((snapshot) {
      if (!snapshot.exists) return []; // Empty means ship everywhere for now
      final List<dynamic> list = snapshot.data()?['pincodes'] ?? [];
      return list.map((e) => e.toString()).toList();
    });
  }

  // 18. Billing Page Configuration
  Stream<Map<String, dynamic>> getBillingConfigStream() {
    return _firestore.collection('app_data').doc('billing_config').snapshots().map((snapshot) {
      if (!snapshot.exists) return {
        'delivery_estimate_text': 'Estimated Delivery: 3-5 Business Days',
        'support_chat_text': 'Need help? Chat with our heritage kitchen',
        'savings_highlight_text': 'Total Savings on this order:'
      };
      return snapshot.data() ?? {};
    });
  }
}
