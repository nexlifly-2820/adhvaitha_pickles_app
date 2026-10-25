import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AppConfigRepository {
  // 1. Banners & Ad Banners
  Stream<Map<String, List<Map<String, String>>>> getBannersStream() async* {
    yield {'main': [], 'ad': []};
    try {
      final data = await ApiService.getAppConfig('banners');
      final List<dynamic> mainRaw = data['main_banners'] ?? [];
      final List<dynamic> adRaw = data['ad_banners'] ?? [];
      yield {
        'main': mainRaw.map((item) => Map<String, String>.from(item)).toList(),
        'ad': adRaw.map((item) => Map<String, String>.from(item)).toList(),
      };
    } catch (_) {}
  }

  // 2. Stories Section (Packaging, Origin, etc.)
  Stream<List<Map<String, dynamic>>> getStoriesStream() async* {
    yield [];
    try {
      final data = await ApiService.getAppConfig('stories');
      final List<dynamic> list = data['list'] ?? [];
      yield list.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {}
  }

  // 3. Bento Selection (Today's Selection)
  Stream<Map<String, dynamic>> getBentoConfigStream() async* {
    yield {};
    try {
      final data = await ApiService.getAppConfig('bento_selection');
      if (data.isNotEmpty) yield data;
    } catch (_) {}
  }

  // 4. Coupons
  Stream<List<Map<String, dynamic>>> getCouponsStream() async* {
    yield [];
    try {
      final data = await ApiService.getAppConfig('coupons');
      final List<dynamic> list = data['active_list'] ?? [];
      yield list.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {}
  }

  // 5. Deals of the Day
  Stream<Map<String, dynamic>> getDealsStream() async* {
    yield {'product_names': [], 'end_time': DateTime.now().toString()};
    try {
      final data = await ApiService.getAppConfig('deals');
      if (data.isNotEmpty) yield data;
    } catch (_) {}
  }

  // 6. Royal Packaging Section
  Stream<List<Map<String, String>>> getPackagingStream() async* {
    yield [];
    try {
      final data = await ApiService.getAppConfig('packaging');
      final List<dynamic> list = data['list'] ?? [];
      yield list.map((item) => Map<String, String>.from(item)).toList();
    } catch (_) {}
  }

  // 7. Categories Section
  Stream<List<Map<String, dynamic>>> getCategoriesStream() async* {
    yield List<Map<String, dynamic>>.from(_defaultCategories); // Instant baseline
    try {
      final data = await ApiService.getAppConfig('categories');
      final List<dynamic> list = data['list'] ?? data['categories'] ?? [];
      if (list.isNotEmpty) {
        List<Map<String, dynamic>> finalCategories = List.from(_defaultCategories);
        final List<Map<String, dynamic>> fetchedList = list.map((item) {
          final map = item as Map<String, dynamic>;
          return {
            'label': map['label']?.toString() ?? '',
            'img': map['img']?.toString() ?? map['image']?.toString() ?? '',
            'tagline': map['tagline']?.toString() ?? '',
            'badge': map['badge']?.toString() ?? '',
            'description': map['description']?.toString() ?? '',
          };
        }).toList();

        for (var fCat in fetchedList) {
          int index = finalCategories.indexWhere((dCat) =>
              dCat['label'].toString().toLowerCase() == fCat['label'].toString().toLowerCase());
          if (index != -1) {
            finalCategories[index] = fCat;
          } else {
            finalCategories.add(fCat);
          }
        }
        yield finalCategories;
      }
    } catch (_) {}
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
  Stream<List<Map<String, String>>> getOnboardingStream() async* {
    yield [];
    try {
      final data = await ApiService.getAppConfig('onboarding');
      final List<dynamic> list = data['steps'] ?? [];
      yield list.map((item) => Map<String, String>.from(item)).toList();
    } catch (_) {}
  }

  // 9. Taste Personalizer Options
  Stream<List<Map<String, dynamic>>> getTasteOptionsStream() async* {
    yield [];
    try {
      final data = await ApiService.getAppConfig('onboarding');
      final List<dynamic> list = data['taste_options'] ?? [];
      yield list.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {}
  }

  // 10. App State (Maintenance/Version/Inventory)
  Stream<Map<String, dynamic>> getAppStateStream() async* {
    yield {'maintenance_mode': false, 'min_version': '1.0.0', 'inventory_threshold': 10}; // Instant yield first
    try {
      final data = await ApiService.getAppConfig('config');
      if (data.isNotEmpty) yield data;
    } catch (_) {}
  }

  // 11. Delivery Configuration
  Stream<Map<String, dynamic>> getDeliveryConfigStream() async* {
    yield {'base_fee': 40.0, 'free_threshold': 500.0};
    try {
      final data = await ApiService.getAppConfig('delivery_config');
      if (data.isNotEmpty) yield data;
    } catch (_) {}
  }

  // 15. Categories Page Parent Cards (Ads / Banners)
  Stream<List<Map<String, dynamic>>> getCategoryParentCardsStream() async* {
    yield [
      {'img': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'},
      {'img': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg'},
    ];
    try {
      final data = await ApiService.getAppConfig('category_parent_cards');
      final List<dynamic> list = data['list'] ?? data['banners'] ?? data['ads'] ?? [];
      if (list.isNotEmpty) {
        yield list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (_) {}
  }

  // 12. Perfect Pairings
  Stream<List<Map<String, dynamic>>> getPairingsStream() async* {
    yield [];
    try {
      final data = await ApiService.getAppConfig('pairings');
      debugPrint("Pairings API fetched data: $data");
      List<dynamic> list = [];
      if (data.isNotEmpty) {
        list = data['list'] ?? data['pairings'] ?? data['items'] ?? data['combos'] ?? data['data'] ?? [];
        if (list.isEmpty && data['content'] is Map) {
          final contentMap = data['content'] as Map;
          list = contentMap['list'] ?? contentMap['pairings'] ?? contentMap['items'] ?? [];
        } else if (list.isEmpty && data['content'] is List) {
          list = data['content'] as List;
        } else if (list.isEmpty) {
          for (var val in data.values) {
            if (val is List && val.isNotEmpty) {
              list = val;
              break;
            }
          }
        }
      }

      debugPrint("Parsed pairings list length: ${list.length}");
      if (list.isNotEmpty) {
        yield list.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        yield [];
      }
    } catch (e) {
      debugPrint('Error loading pairings: $e');
      yield [];
    }
  }

  // 13. Heritage Story Banner
  Stream<Map<String, String>> getHeritageBannerStream() async* {
    yield {};
    try {
      final data = await ApiService.getAppConfig('heritage_banner');
      if (data.isNotEmpty) yield Map<String, String>.from(data);
    } catch (_) {}
  }

  // 14. Trending Searches
  Stream<List<String>> getTrendingSearchesStream() async* {
    yield ['Mango Special', 'New Snacks', 'Spicy Chicken', 'Ladoo', 'Combos'];
    try {
      final data = await ApiService.getAppConfig('search_config');
      final List<dynamic> list = data['trending_keywords'] ?? [];
      if (list.isNotEmpty) yield list.map((e) => e.toString()).toList();
    } catch (_) {}
  }

  // 15. Categories Page Hero Banner
  Stream<Map<String, dynamic>> getCategoryPageConfigStream() async* {
    yield {
      'hero_title': 'The Royal Summer Festival',
      'hero_subtitle': 'Authentic sun-dried mango delicacies',
      'hero_image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      'hero_tag': 'FEATURED COLLECTION'
    };
    try {
      final data = await ApiService.getAppConfig('category_page_config');
      if (data.isNotEmpty) yield data;
    } catch (_) {}
  }

  // 16. Cart Configuration
  Stream<Map<String, dynamic>> getCartConfigStream() async* {
    yield {
      'freshness_tagline': 'FRESHNESS GUARANTEED',
      'dispatch_reassurance': 'Order in the next 2 hrs for same-day dispatch.',
      'upsell_section_title': 'COMPLETES THE EXPERIENCE'
    };
    try {
      final data = await ApiService.getAppConfig('cart_config');
      if (data.isNotEmpty) yield data;
    } catch (_) {}
  }

  // 17. Serviceable Pincodes
  Stream<List<String>> getServiceablePincodesStream() async* {
    yield [];
    try {
      final data = await ApiService.getAppConfig('serviceability');
      final List<dynamic> list = data['pincodes'] ?? [];
      yield list.map((e) => e.toString()).toList();
    } catch (_) {}
  }

  // 18. Billing Page Configuration
  Stream<Map<String, dynamic>> getBillingConfigStream() async* {
    yield {
      'delivery_estimate_text': 'Estimated Delivery: 3-5 Business Days',
      'support_chat_text': 'Need help? Chat with our heritage kitchen',
      'savings_highlight_text': 'Total Savings on this order:'
    };
    try {
      final data = await ApiService.getAppConfig('billing_config');
      if (data.isNotEmpty) yield data;
    } catch (_) {}
  }

  // 19. Home Video Configuration
  Stream<Map<String, dynamic>> getHomeVideoConfigStream() async* {
    yield {
      'enabled': true,
      'video_url': 'assets/images/ambhujakshi-all.mp4',
    };
    try {
      final data = await ApiService.getAppConfig('home_video');
      if (data.isNotEmpty) yield data;
    } catch (_) {}
  }

  // 20. Festival Section Configuration (Admin Controlled)
  static Map<String, dynamic> _inMemoryFestivalConfig = {};

  Stream<Map<String, dynamic>> getFestivalConfigStream() async* {
    if (_inMemoryFestivalConfig.isNotEmpty) {
      yield _inMemoryFestivalConfig;
    } else {
      yield _defaultFestivalData;
    }
    try {
      final data = await ApiService.getAppConfig('festival_config');
      if (data.isNotEmpty) {
        _inMemoryFestivalConfig = data;
        yield data;
      }
    } catch (_) {}
  }

  Future<bool> saveFestivalConfig(Map<String, dynamic> festivalData) async {
    _inMemoryFestivalConfig = festivalData;
    try {
      return await ApiService.saveAppConfig('festival_config', festivalData);
    } catch (e) {
      debugPrint('Error saving festival config: $e');
      return true;
    }
  }

  static final Map<String, dynamic> _defaultFestivalData = {
    'enabled': true,
    'id': 'sankranti-2027',
    'kicker': 'CELEBRATE',
    'title': 'Sankranti',
    'subtitle': 'Pindi vantalu, sweets & gift boxes, made fresh',
    'chipsTitle': 'FESTIVE SPECIALS',
    'theme': {
      'bgTop': '#F9DFB3',
      'bgBottom': '#F6D6A2',
      'tile': '#B81D3B',
      'line': '#EFCF8C',
      'title': '#7A1240',
      'kicker': '#5A1030',
      'strip': '#D98F2E',
      'chipBg': '#FDF3DD',
      'accent': '#E9952C'
    },
    'tiles': [
      {
        'title': 'Pindi\nVantalu',
        'image': 'assets/images/snacks.png',
        'image2': 'assets/images/sweets.png',
        'link': {'category': 'Snacks'}
      },
      {
        'title': 'Festive\nSweets',
        'image': 'assets/images/sweets.png',
        'image2': 'assets/images/snacks.png',
        'link': {'category': 'Sweets'}
      },
      {
        'title': 'Gifting\nCorner',
        'image': 'assets/images/combos.png',
        'image2': 'assets/images/pickles.png',
        'link': {'category': 'Combos'}
      },
      {
        'title': 'Pickles\n& Podis',
        'image': 'assets/images/pickles.png',
        'image2': 'assets/images/spices.png',
        'link': {'category': 'Pickles'}
      }
    ],
    'strip': ['HOMEMADE', 'STONE-GROUND', 'FRESH BATCHES', 'PAN-INDIA'],
    'chips': [
      {
        'title': 'Sankranti\nEssentials',
        'image': 'assets/images/sweets.png',
        'link': {'tag': 'sankranti'}
      },
      {
        'title': 'Snacks\n& More',
        'image': 'assets/images/snacks.png',
        'link': {'category': 'Snacks'}
      },
      {
        'title': 'Traditional\nSweets',
        'image': 'assets/images/combos.png',
        'link': {'category': 'Sweets'}
      },
      {
        'title': 'Pickles\n& Podis',
        'image': 'assets/images/pickles.png',
        'link': {'category': 'Pickles'}
      },
      {
        'title': 'Under\n₹299',
        'image': 'assets/images/spices.png',
        'link': {'maxPrice': 299}
      }
    ],
    'products': {'tag': 'sankranti', 'limit': 10}
  };
}
