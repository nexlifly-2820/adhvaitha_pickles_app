import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'widgets/scratch_save_section.dart';

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
    yield _defaultPairingsData;
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
        final parsed = list.map((item) => Map<String, dynamic>.from(item)).toList();
        final hasPairs = parsed.any((item) => item.containsKey('pairs') || item.containsKey('subs') || item.containsKey('subPairings'));
        if (hasPairs) {
          yield parsed;
        } else {
          yield _defaultPairingsData;
        }
      } else {
        yield _defaultPairingsData;
      }
    } catch (e) {
      debugPrint('Error loading pairings: $e');
      yield _defaultPairingsData;
    }
  }

  Future<bool> savePairingsConfig(List<Map<String, dynamic>> pairingsData) async {
    try {
      return await ApiService.saveAppConfig('pairings', {'list': pairingsData});
    } catch (e) {
      debugPrint('Error saving pairings config: $e');
      return true;
    }
  }

  // 15. AmbhuJakshi Specials (Light Section)
  Stream<List<Map<String, dynamic>>> getSpecialsLightStream() async* {
    yield _defaultSpecialsLightData;
    try {
      final data = await ApiService.getAppConfig('specials_light');
      debugPrint("Specials Light API fetched data: $data");
      List<dynamic> list = [];
      if (data.isNotEmpty) {
        list = data['list'] ?? data['items'] ?? data['specials'] ?? data['data'] ?? [];
        if (list.isEmpty && data['content'] is Map) {
          final contentMap = data['content'] as Map;
          list = contentMap['list'] ?? contentMap['items'] ?? [];
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

      if (list.isNotEmpty) {
        yield list.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        yield _defaultSpecialsLightData;
      }
    } catch (e) {
      debugPrint('Error loading specials_light: $e');
      yield _defaultSpecialsLightData;
    }
  }

  Future<bool> saveSpecialsLightConfig(List<Map<String, dynamic>> specialsData) async {
    try {
      return await ApiService.saveAppConfig('specials_light', {'list': specialsData});
    } catch (e) {
      debugPrint('Error saving specials_light config: $e');
      return true;
    }
  }

  // 16. Snacks with a Story
  Stream<List<Map<String, dynamic>>> getStorySnacksStream() async* {
    yield _defaultStorySnacksData;
    try {
      final data = await ApiService.getAppConfig('story_snacks');
      debugPrint("Story Snacks API fetched data: $data");
      List<dynamic> list = [];
      if (data.isNotEmpty) {
        list = data['list'] ?? data['items'] ?? data['snacks'] ?? data['data'] ?? [];
        if (list.isEmpty && data['content'] is Map) {
          final contentMap = data['content'] as Map;
          list = contentMap['list'] ?? contentMap['items'] ?? [];
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

      if (list.isNotEmpty) {
        yield list.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        yield _defaultStorySnacksData;
      }
    } catch (e) {
      debugPrint('Error loading story_snacks: $e');
      yield _defaultStorySnacksData;
    }
  }

  Future<bool> saveStorySnacksConfig(List<Map<String, dynamic>> snacksData) async {
    try {
      return await ApiService.saveAppConfig('story_snacks', {'list': snacksData});
    } catch (e) {
      debugPrint('Error saving story_snacks config: $e');
      return true;
    }
  }

  // 17. Auto Carousel Banners
  Stream<List<Map<String, dynamic>>> getAutoBannersStream() async* {
    yield _defaultAutoBannersData;
    try {
      final data = await ApiService.getAppConfig('auto_banners');
      debugPrint("Auto Banners API fetched data: $data");
      List<dynamic> list = [];
      if (data.isNotEmpty) {
        list = data['banners'] ?? data['list'] ?? data['items'] ?? data['data'] ?? [];
        if (list.isEmpty && data['content'] is Map) {
          final contentMap = data['content'] as Map;
          list = contentMap['banners'] ?? contentMap['list'] ?? contentMap['items'] ?? [];
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

      if (list.isNotEmpty) {
        yield list.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        yield _defaultAutoBannersData;
      }
    } catch (e) {
      debugPrint('Error loading auto_banners: $e');
      yield _defaultAutoBannersData;
    }
  }

  Future<bool> saveAutoBannersConfig(List<Map<String, dynamic>> bannersData) async {
    try {
      return await ApiService.saveAppConfig('auto_banners', {'banners': bannersData});
    } catch (e) {
      debugPrint('Error saving auto_banners config: $e');
      return true;
    }
  }

  // 19. Letters from Home Customer Reviews
  Stream<Map<String, dynamic>> getReviewsStream() async* {
    yield _defaultReviewsData;
    try {
      final data = await ApiService.getAppConfig('reviews');
      debugPrint("Reviews API fetched data: $data");
      if (data.isNotEmpty) {
        yield Map<String, dynamic>.from(data);
      } else {
        yield _defaultReviewsData;
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      yield _defaultReviewsData;
    }
  }

  Future<bool> saveReviewsConfig(Map<String, dynamic> reviewsData) async {
    try {
      return await ApiService.saveAppConfig('reviews', reviewsData);
    } catch (e) {
      debugPrint('Error saving reviews config: $e');
      return true;
    }
  }

  // 20. The AmbhuJakshi Promise (Trust Section)
  Stream<Map<String, dynamic>> getTrustStream() async* {
    yield _defaultTrustData;
    try {
      final data = await ApiService.getAppConfig('trust');
      debugPrint("Trust API fetched data: $data");
      if (data.isNotEmpty) {
        yield Map<String, dynamic>.from(data);
      } else {
        yield _defaultTrustData;
      }
    } catch (e) {
      debugPrint('Error loading trust data: $e');
      yield _defaultTrustData;
    }
  }

  Future<bool> saveTrustConfig(Map<String, dynamic> trustData) async {
    try {
      return await ApiService.saveAppConfig('trust', trustData);
    } catch (e) {
      debugPrint('Error saving trust config: $e');
      return true;
    }
  }

  // 21. Pickles Showcase Section
  Stream<Map<String, dynamic>> getPicklesStream() async* {
    yield _defaultPicklesData;
    try {
      final data = await ApiService.getAppConfig('pickles');
      debugPrint("Pickles API fetched data: $data");
      if (data.isNotEmpty) {
        yield Map<String, dynamic>.from(data);
      } else {
        yield _defaultPicklesData;
      }
    } catch (e) {
      debugPrint('Error loading pickles data: $e');
      yield _defaultPicklesData;
    }
  }

  Future<bool> savePicklesConfig(Map<String, dynamic> picklesData) async {
    try {
      return await ApiService.saveAppConfig('pickles', picklesData);
    } catch (e) {
      debugPrint('Error saving pickles config: $e');
      return true;
    }
  }

  // 18. Scratch & Save Rewards
  Stream<Map<String, dynamic>> getRewardsStream() async* {
    yield _defaultRewardsData;
    try {
      final data = await ApiService.getAppConfig('rewards');
      debugPrint("Rewards API fetched data: $data");
      if (data.isNotEmpty && (data.containsKey('cards') || data.containsKey('ordersDone'))) {
        yield Map<String, dynamic>.from(data);
      } else {
        yield _defaultRewardsData;
      }
    } catch (e) {
      debugPrint('Error loading rewards: $e');
      yield _defaultRewardsData;
    }
  }

  Future<bool> saveRewardsConfig(Map<String, dynamic> rewardsData) async {
    try {
      return await ApiService.saveAppConfig('rewards', rewardsData);
    } catch (e) {
      debugPrint('Error saving rewards config: $e');
      return true;
    }
  }

  // 19. Most Loved Section
  Stream<Map<String, dynamic>> getMostLovedStream() async* {
    yield _defaultMostLovedData;
    try {
      final data = await ApiService.getAppConfig('most_loved');
      debugPrint("Most Loved API fetched data: $data");
      if (data.isNotEmpty) {
        yield Map<String, dynamic>.from(data);
      } else {
        yield _defaultMostLovedData;
      }
    } catch (e) {
      debugPrint('Error loading most_loved: $e');
      yield _defaultMostLovedData;
    }
  }

  Future<bool> saveMostLovedConfig(Map<String, dynamic> mostLovedData) async {
    try {
      return await ApiService.saveAppConfig('most_loved', mostLovedData);
    } catch (e) {
      debugPrint('Error saving most_loved config: $e');
      return true;
    }
  }

  // 20. Best Sellers Section
  Stream<Map<String, dynamic>> getBestSellersStream() async* {
    yield _defaultBestSellersData;
    try {
      final data = await ApiService.getAppConfig('best_sellers');
      debugPrint("Best Sellers API fetched data: $data");
      if (data.isNotEmpty && (data.containsKey('categories') || data.containsKey('settings'))) {
        yield Map<String, dynamic>.from(data);
      } else {
        yield _defaultBestSellersData;
      }
    } catch (e) {
      debugPrint('Error loading best_sellers: $e');
      yield _defaultBestSellersData;
    }
  }

  Future<bool> saveBestSellersConfig(Map<String, dynamic> bestSellersData) async {
    try {
      return await ApiService.saveAppConfig('best_sellers', bestSellersData);
    } catch (e) {
      debugPrint('Error saving best_sellers config: $e');
      return true;
    }
  }

  // 21. Fresh Picks Section
  Stream<Map<String, dynamic>> getFreshPicksStream() async* {
    yield _defaultFreshPicksData;
    try {
      final data = await ApiService.getAppConfig('fresh_picks');
      debugPrint("Fresh Picks API fetched data: $data");
      // Only the new admin format (version 2) replaces the built-in 13 spices.
      if (data.isNotEmpty && data['version']?.toString() == '2' && data['products'] is List && (data['products'] as List).isNotEmpty) {
        final Map<String, dynamic> d = Map<String, dynamic>.from(data);
        d['products'] = (d['products'] as List).where((dynamic p) => p is Map && p['enabled']?.toString() != 'false').toList();
        yield (d['products'] as List).isEmpty ? _defaultSpicesData : d;
      } else {
        yield _defaultFreshPicksData;
      }
    } catch (e) {
      debugPrint('Error loading fresh_picks: $e');
      yield _defaultFreshPicksData;
    }
  }

  Future<bool> saveFreshPicksConfig(Map<String, dynamic> freshPicksData) async {
    try {
      return await ApiService.saveAppConfig('fresh_picks', freshPicksData);
    } catch (e) {
      debugPrint('Error saving fresh_picks config: $e');
      return true;
    }
  }

  // 23. Spice Grinder Section
  Stream<Map<String, dynamic>> getSpicesStream() async* {
    yield _defaultSpicesData;
    try {
      final data = await ApiService.getAppConfig('spices_grinder');
      debugPrint("Spices Grinder API fetched data: $data");
      // Only the new admin format (version 2) replaces the built-in 13 spices.
      if (data.isNotEmpty && data['version']?.toString() == '2' && data['products'] is List && (data['products'] as List).isNotEmpty) {
        final Map<String, dynamic> d = Map<String, dynamic>.from(data);
        d['products'] = (d['products'] as List).where((dynamic p) => p is Map && p['enabled']?.toString() != 'false').toList();
        yield (d['products'] as List).isEmpty ? _defaultSpicesData : d;
      } else {
        yield _defaultSpicesData;
      }
    } catch (e) {
      debugPrint('Error loading spices_grinder: $e');
      yield _defaultSpicesData;
    }
  }

  Future<bool> saveSpicesConfig(Map<String, dynamic> spicesData) async {
    try {
      return await ApiService.saveAppConfig('spices_grinder', spicesData);
    } catch (e) {
      debugPrint('Error saving spices_grinder config: $e');
      return true;
    }
  }

  // 22. Sweets Thali Section
  Stream<Map<String, dynamic>> getSweetsStream() async* {
    yield _defaultSweetsData;
    try {
      final data = await ApiService.getAppConfig('sweets');
      debugPrint("Sweets API fetched data: $data");
      // Only the new admin format (version 2) replaces the built-in 13 spices.
      if (data.isNotEmpty && data['version']?.toString() == '2' && data['products'] is List && (data['products'] as List).isNotEmpty) {
        final Map<String, dynamic> d = Map<String, dynamic>.from(data);
        d['products'] = (d['products'] as List).where((dynamic p) => p is Map && p['enabled']?.toString() != 'false').toList();
        yield (d['products'] as List).isEmpty ? _defaultSpicesData : d;
      } else {
        yield _defaultSweetsData;
      }
    } catch (e) {
      debugPrint('Error loading sweets: $e');
      yield _defaultSweetsData;
    }
  }

  Future<bool> saveSweetsConfig(Map<String, dynamic> sweetsData) async {
    try {
      return await ApiService.saveAppConfig('sweets', sweetsData);
    } catch (e) {
      debugPrint('Error saving sweets config: $e');
      return true;
    }
  }

  Future<RewardCard> scratchRewardCard(RewardCard card) async {
    try {
      final res = await ApiService.scratchCard(card.id);
      if (res.isNotEmpty) {
        return RewardCard.fromJson(res);
      }
    } catch (e) {
      debugPrint('Error scratching card in repo: $e');
    }
    // Fallback if server offline / test mode
    return RewardCard(
      id: card.id,
      status: 'revealed',
      title: card.title.isNotEmpty ? card.title : '₹100 OFF',
      subtitle: card.subtitle.isNotEmpty ? card.subtitle : 'on orders above ₹799',
      code: card.code.isNotEmpty ? card.code : 'ROYAL100',
      image: card.image.isNotEmpty
          ? card.image
          : 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      validDays: card.validDays > 0 ? card.validDays : 7,
      step: card.step,
      unlockAfter: card.unlockAfter,
      big: card.big,
    );
  }

  static final Map<String, dynamic> _defaultRewardsData = {
    'ordersDone': 1,
    'cards': [
      {
        'id': 'c1',
        'step': 1,
        'status': 'new',
        'title': '₹100 OFF',
        'subtitle': 'on orders above ₹799',
        'code': 'ROYAL100',
        'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
        'validDays': 7,
        'unlockAfter': 0,
      },
      {
        'id': 'c2',
        'step': 2,
        'status': 'locked',
        'title': '15% OFF',
        'subtitle': 'on all pickles & powders',
        'code': 'HERITAGE15',
        'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        'validDays': 10,
        'unlockAfter': 1,
      },
      {
        'id': 'c3',
        'step': 3,
        'status': 'locked',
        'title': 'FREE SWEET BOX',
        'subtitle': 'Sunnunda Laddu on ₹999+',
        'code': 'FREESWEET',
        'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        'validDays': 14,
        'unlockAfter': 2,
      },
      {
        'id': 'c4',
        'step': 4,
        'status': 'locked',
        'title': '₹500 OFF BUMPER',
        'subtitle': 'Royal privilege gift box',
        'code': 'BUMPER500',
        'image': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
        'validDays': 30,
        'unlockAfter': 3,
        'big': true,
      },
    ],
  };

  static final Map<String, dynamic> _defaultMostLovedData = {
    'settings': {
      'enabled': true,
      'kicker': 'THE LOVE CHART',
      'title': 'Most loved',
      'titleAccent': 'products',
      'intervalMs': 2500,
      'maxItems': 10
    },
    'products': [
      {
        'id': 'p1',
        'name': 'Bellam Avakaya',
        'short': 'Avakaya',
        'tagline': 'sweet jaggery meets fiery mango',
        'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
        'colors': ['#F7B733', '#E2722B'],
        'rating': 4.8,
        'soldToday': 320,
        'loves': '2.1k',
        'spice': 2,
        'badge': '👑 No.1 this week',
        'variants': [
          {'id': 'v1', 'label': '250g', 'price': 120, 'mrp': 136, 'inStock': true},
          {'id': 'v2', 'label': '500g', 'price': 230, 'mrp': 260, 'inStock': true},
          {'id': 'v3', 'label': '1kg', 'price': 440, 'mrp': 500, 'inStock': true}
        ]
      },
      {
        'id': 'p2',
        'name': 'Idli Karam Podi',
        'short': 'Karam Podi',
        'tagline': 'authentic gun powder spice blend',
        'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        'colors': ['#8E1B2B', '#5C0A0D'],
        'rating': 4.9,
        'soldToday': 280,
        'loves': '1.8k',
        'spice': 3,
        'badge': '🔥 Bestseller',
        'variants': [
          {'id': 'v4', 'label': '200g', 'price': 139, 'mrp': 150, 'inStock': true},
          {'id': 'v5', 'label': '500g', 'price': 320, 'mrp': 350, 'inStock': true}
        ]
      },
      {
        'id': 'p3',
        'name': 'Kara Murukku',
        'short': 'Murukku',
        'tagline': 'crispy spiral festive savory',
        'image': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
        'colors': ['#18453B', '#235D4E'],
        'rating': 4.7,
        'soldToday': 195,
        'loves': '1.4k',
        'spice': 1,
        'badge': '✨ Crunchy',
        'variants': [
          {'id': 'v6', 'label': '250g', 'price': 129, 'mrp': 140, 'inStock': true},
          {'id': 'v7', 'label': '500g', 'price': 249, 'mrp': 270, 'inStock': true}
        ]
      },
      {
        'id': 'p4',
        'name': 'Sunnunda Laddu',
        'short': 'Sunnunda',
        'tagline': 'roasted urad dal & pure cow ghee',
        'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        'colors': ['#8B4513', '#B8860B'],
        'rating': 4.9,
        'soldToday': 210,
        'loves': '1.9k',
        'spice': 0,
        'badge': '🍯 Ghee Special',
        'variants': [
          {'id': 'v8', 'label': '250g', 'price': 199, 'mrp': 220, 'inStock': true},
          {'id': 'v9', 'label': '500g', 'price': 380, 'mrp': 420, 'inStock': true}
        ]
      },
      {
        'id': 'p5',
        'name': 'Gongura Pickle',
        'short': 'Gongura',
        'tagline': 'tangy sorrel leaves with garlic',
        'image': 'assets/images/gongura_pickle.png',
        'colors': ['#1E7A46', '#0F3F33'],
        'rating': 4.9,
        'soldToday': 245,
        'loves': '1.6k',
        'spice': 3,
        'badge': '🌿 Andhra Pride',
        'variants': [
          {'id': 'v10', 'label': '250g', 'price': 130, 'mrp': 145, 'inStock': true},
          {'id': 'v11', 'label': '500g', 'price': 245, 'mrp': 275, 'inStock': true}
        ]
      }
    ]
  };

  static final Map<String, dynamic> _defaultBestSellersData = {
    'settings': {
      'enabled': true,
      'kicker': "THIS MONTH'S CHAMPIONS",
      'title': 'Best',
      'titleAccent': 'sellers',
      'subtitle': 'Ranked by real orders from 12,000+ homes',
      'intervalMs': 4000,
      'rows': 3
    },
    'categories': [
      {
        'id': 'all',
        'name': 'All',
        'emoji': '🔥',
        'items': [
          {
            'id': 'p1',
            'variantId': 'v1',
            'name': 'Bellam Avakaya',
            'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
            'price': 120,
            'mrp': 136,
            'sold': '12K+',
            'rating': 4.8,
            'move': 'up',
            'moveBy': 2
          },
          {
            'id': 'p2',
            'variantId': 'v4',
            'name': 'Idli Karam Podi',
            'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
            'price': 139,
            'mrp': 150,
            'sold': '9.8K+',
            'rating': 4.9,
            'move': 'up',
            'moveBy': 1
          },
          {
            'id': 'p3',
            'variantId': 'v8',
            'name': 'Sunnunda Laddu',
            'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
            'price': 199,
            'mrp': 220,
            'sold': '8.4K+',
            'rating': 4.9,
            'move': 'new',
            'moveBy': 0
          },
          {
            'id': 'p4',
            'variantId': 'v6',
            'name': 'Kara Murukku',
            'image': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
            'price': 129,
            'mrp': 140,
            'sold': '6.2K+',
            'rating': 4.7,
            'move': 'up',
            'moveBy': 3
          },
          {
            'id': 'p5',
            'variantId': 'v10',
            'name': 'Khara Mixture',
            'image': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
            'price': 149,
            'mrp': 165,
            'sold': '5.5K+',
            'rating': 4.6,
            'move': 'down',
            'moveBy': 1
          },
          {
            'id': 'p6',
            'variantId': 'v12',
            'name': 'Gongura Pickle',
            'image': 'assets/images/gongura_pickle.png',
            'price': 130,
            'mrp': 145,
            'sold': '7.1K+',
            'rating': 4.9,
            'move': 'up',
            'moveBy': 2
          },
          {
            'id': 'p7',
            'variantId': 'v14',
            'name': 'Usiri Pickle',
            'image': 'assets/images/avakaya_pickle.png',
            'price': 130,
            'mrp': 150,
            'sold': '6.8K+',
            'rating': 4.8,
            'move': 'up',
            'moveBy': 1
          },
          {
            'id': 'p8',
            'variantId': 'v16',
            'name': 'Chakinalu',
            'image': 'assets/images/chakralu.png',
            'price': 110,
            'mrp': 130,
            'sold': '8.2K+',
            'rating': 4.8,
            'move': 'new',
            'moveBy': 0
          }
        ]
      },
      {
        'id': 'pickles',
        'name': 'Pickles',
        'emoji': '🥭',
        'items': [
          {
            'id': 'p1',
            'variantId': 'v1',
            'name': 'Bellam Avakaya',
            'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
            'price': 120,
            'mrp': 136,
            'sold': '12K+',
            'rating': 4.8,
            'move': 'up',
            'moveBy': 2
          },
          {
            'id': 'p6',
            'variantId': 'v11',
            'name': 'Allam Pickle',
            'image': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
            'price': 140,
            'mrp': 160,
            'sold': '7.1K+',
            'rating': 4.7,
            'move': 'up',
            'moveBy': 1
          },
          {
            'id': 'p7',
            'variantId': 'v12',
            'name': 'Usiri Pickle',
            'image': 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg',
            'price': 130,
            'mrp': 145,
            'sold': '5.8K+',
            'rating': 4.6,
            'move': '',
            'moveBy': 0
          }
        ]
      },
      {
        'id': 'powders',
        'name': 'Powders',
        'emoji': '🌶️',
        'items': [
          {
            'id': 'p2',
            'variantId': 'v4',
            'name': 'Idli Karam Podi',
            'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
            'price': 139,
            'mrp': 150,
            'sold': '9.8K+',
            'rating': 4.9,
            'move': 'up',
            'moveBy': 1
          },
          {
            'id': 'p8',
            'variantId': 'v13',
            'name': 'Allam Karam Podi',
            'image': 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
            'price': 145,
            'mrp': 160,
            'sold': '6.4K+',
            'rating': 4.8,
            'move': 'up',
            'moveBy': 2
          },
          {
            'id': 'p9',
            'variantId': 'v14',
            'name': 'Karvepaku Podi',
            'image': 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg',
            'price': 135,
            'mrp': 150,
            'sold': '4.9K+',
            'rating': 4.7,
            'move': 'new',
            'moveBy': 0
          }
        ]
      },
      {
        'id': 'sweets',
        'name': 'Sweets',
        'emoji': '🍯',
        'items': [
          {
            'id': 'p3',
            'variantId': 'v8',
            'name': 'Sunnunda Laddu',
            'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
            'price': 199,
            'mrp': 220,
            'sold': '8.4K+',
            'rating': 4.9,
            'move': 'new',
            'moveBy': 0
          },
          {
            'id': 'p10',
            'variantId': 'v15',
            'name': 'Dry Fruits Laddu',
            'image': 'assets/images/dry_fruit_laddu.png',
            'price': 299,
            'mrp': 350,
            'sold': '5.2K+',
            'rating': 5.0,
            'move': 'up',
            'moveBy': 1
          }
        ]
      },
      {
        'id': 'snacks',
        'name': 'Snacks',
        'emoji': '🥨',
        'items': [
          {
            'id': 'p4',
            'variantId': 'v6',
            'name': 'Kara Murukku',
            'image': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
            'price': 129,
            'mrp': 140,
            'sold': '6.2K+',
            'rating': 4.7,
            'move': 'up',
            'moveBy': 3
          },
          {
            'id': 'p5',
            'variantId': 'v10',
            'name': 'Khara Mixture',
            'image': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
            'price': 149,
            'mrp': 165,
            'sold': '5.5K+',
            'rating': 4.6,
            'move': 'down',
            'moveBy': 1
          }
        ]
      }
    ]
  };

  static final Map<String, dynamic> _defaultFreshPicksData = {
    'settings': {
      'enabled': true,
      'kicker': 'FRESH OFF THE STOVE',
      'title': 'Fresh picks,',
      'titleAccent': 'just for you',
      'subtitle': "new from Amma's kitchen this week",
      'intervalMs': 3400
    },
    'products': [
      {
        'id': 'p1',
        'name': 'Chakinalu',
        'tagline': 'Sankranti spiral snack',
        'image': 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg',
        'madeLabel': 'Made today, 6 AM',
        'batch': 'Batch #24',
        'badge': 'NEW',
        'variants': [
          {'id': 'v1', 'label': '250g', 'price': 100, 'mrp': 115, 'inStock': true},
          {'id': 'v2', 'label': '500g', 'price': 190, 'mrp': 220, 'inStock': true}
        ]
      },
      {
        'id': 'p2',
        'name': 'Idli Karam Podi',
        'tagline': 'freshly roasted & ground spice powder',
        'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        'madeLabel': 'Made today, 7 AM',
        'batch': 'Batch #25',
        'badge': 'HOT',
        'variants': [
          {'id': 'v3', 'label': '200g', 'price': 139, 'mrp': 150, 'inStock': true},
          {'id': 'v4', 'label': '500g', 'price': 320, 'mrp': 350, 'inStock': true}
        ]
      },
      {
        'id': 'p3',
        'name': 'Sunnunda Laddu',
        'tagline': 'ghee-infused roasted urad laddus',
        'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        'madeLabel': 'Made today, 5 AM',
        'batch': 'Batch #22',
        'badge': 'FRESH',
        'variants': [
          {'id': 'v5', 'label': '250g', 'price': 199, 'mrp': 220, 'inStock': true},
          {'id': 'v6', 'label': '500g', 'price': 380, 'mrp': 420, 'inStock': true}
        ]
      }
    ]
  };

  static final Map<String, dynamic> _defaultSweetsData = {
    'settings': {
      'enabled': true,
      'kicker': 'MITHAI THALI',
      'title': 'Traditional sweets,',
      'titleAccent': 'timeless joy',
      'subtitle': 'Pure ghee. Jaggery. Just like Ammamma made.',
      'intervalMs': 2800,
      'badges': ['🧈 Pure desi ghee', 'No preservatives'],
      'giftTag': '🎁 Gift box available'
    },
    'products': [
      {
        'id': 'p1',
        'name': 'Sunnunda Laddu',
        'tagline': 'roasted urad dal & organic jaggery',
        'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        'tags': ['🧈 Pure Desi Ghee', 'No Sugar'],
        'giftBox': true,
        'variants': [
          {'id': 'v1', 'label': '250g', 'price': 199, 'mrp': 220, 'inStock': true},
          {'id': 'v2', 'label': '500g', 'price': 380, 'mrp': 420, 'inStock': true}
        ]
      },
      {
        'id': 'p2',
        'name': 'Dry Fruits Laddu',
        'tagline': 'almonds, cashews, dates & pistachios',
        'image': 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg',
        'tags': ['🥜 Loaded with nuts', 'Energy Rich'],
        'giftBox': true,
        'variants': [
          {'id': 'v3', 'label': '250g', 'price': 240, 'mrp': 275, 'inStock': true},
          {'id': 'v4', 'label': '500g', 'price': 460, 'mrp': 520, 'inStock': true}
        ]
      },
      {
        'id': 'p3',
        'name': 'Gondh Laddu',
        'tagline': 'edible gum, ghee & wholesome dry fruits',
        'image': 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
        'tags': ['💪 Immunity Boost', 'Winter Special'],
        'giftBox': false,
        'variants': [
          {'id': 'v5', 'label': '250g', 'price': 210, 'mrp': 235, 'inStock': true},
          {'id': 'v6', 'label': '500g', 'price': 410, 'mrp': 450, 'inStock': true}
        ]
      },
      {
        'id': 'p4',
        'name': 'Gulab Jamun Kova',
        'tagline': 'rich khoya gulab jamun in cardamom syrup',
        'image': 'assets/images/kova_gulam_jamun_rich_gulab_jamun_sweet.jpg',
        'tags': ['🍯 Melt in mouth', 'Khoya Made'],
        'giftBox': false,
        'variants': [
          {'id': 'v7', 'label': '250g', 'price': 180, 'mrp': 200, 'inStock': true},
          {'id': 'v8', 'label': '500g', 'price': 340, 'mrp': 380, 'inStock': true}
        ]
      }
    ]
  };

  static final Map<String, dynamic> _defaultSpicesData = {
      "version": 2,
      "settings": {
        "enabled": true,
        "kicker": "FROM WHOLE SPICE TO PODI",
        "title": "Fresh ground",
        "titleAccent": "spices",
        "subtitle": "Pounded in stone, the way Ammamma did.",
        "cardTag": "🪨 STONE-GROUND TODAY"
      },
      "products": [
        {
          "id": "allam_velluli",
          "productId": "allam_velluli_karam_podi",
          "name": "Allam Velluli Karam Podi",
          "tagline": "Ginger-garlic spice powder",
          "image": "assets/images/sp_allam_velluli_podi.png",
          "enabled": true,
          "powderColor": "#C2410C",
          "accentColor": "#FF8A4C",
          "glowColor": "#7A2A10",
          "heat": 3,
          "throwIn": [
            {
              "name": "Ginger",
              "pieces": [
                "assets/images/ginger_0.png",
                "assets/images/ginger_1.png"
              ],
              "count": 3,
              "size": "big"
            },
            {
              "name": "Red chilli",
              "pieces": [
                "assets/images/redchilli_0.png",
                "assets/images/chillies_0.png"
              ],
              "count": 3,
              "size": "big"
            },
            {
              "name": "Cumin",
              "pieces": [
                "assets/images/cumin_0.png",
                "assets/images/cumin_1.png"
              ],
              "count": 8,
              "size": "small"
            }
          ],
          "chips": [
            {
              "name": "Ginger",
              "icon": "assets/images/ginger_0.png"
            },
            {
              "name": "Red chilli",
              "icon": "assets/images/redchilli_0.png"
            },
            {
              "name": "Cumin",
              "icon": "assets/images/cumin_0.png"
            }
          ],
          "variants": [
            {
              "id": "allam_velluli_250g",
              "label": "250g",
              "price": 145,
              "mrp": 167,
              "inStock": true
            },
            {
              "id": "allam_velluli_500g",
              "label": "500g",
              "price": 276,
              "mrp": 317,
              "inStock": true
            },
            {
              "id": "allam_velluli_1kg",
              "label": "1kg",
              "price": 522,
              "mrp": 601,
              "inStock": true
            }
          ]
        },
        {
          "id": "karvepaku",
          "productId": "karvepaku_karam_podi",
          "name": "Karvepaku Karam Podi",
          "tagline": "Curry-leaf spice powder",
          "image": "assets/images/sp_karvepaku_podi.png",
          "enabled": true,
          "powderColor": "#4D5A1E",
          "accentColor": "#9DB040",
          "glowColor": "#2C3510",
          "heat": 2,
          "throwIn": [
            {
              "name": "Curry leaves",
              "pieces": [
                "assets/images/curryleaf_0.png",
                "assets/images/curryleaf_1.png"
              ],
              "count": 5,
              "size": "big"
            },
            {
              "name": "Red chilli",
              "pieces": [
                "assets/images/redchilli_0.png",
                "assets/images/chillies_0.png"
              ],
              "count": 2,
              "size": "big"
            },
            {
              "name": "Urad dal",
              "pieces": [
                "assets/images/urad_0.png",
                "assets/images/urad_1.png"
              ],
              "count": 6,
              "size": "small"
            }
          ],
          "chips": [
            {
              "name": "Curry leaves",
              "icon": "assets/images/curryleaf_0.png"
            },
            {
              "name": "Red chilli",
              "icon": "assets/images/redchilli_0.png"
            },
            {
              "name": "Urad dal",
              "icon": "assets/images/urad_0.png"
            }
          ],
          "variants": [
            {
              "id": "karvepaku_250g",
              "label": "250g",
              "price": 135,
              "mrp": 155,
              "inStock": true
            },
            {
              "id": "karvepaku_500g",
              "label": "500g",
              "price": 256,
              "mrp": 294,
              "inStock": true
            },
            {
              "id": "karvepaku_1kg",
              "label": "1kg",
              "price": 486,
              "mrp": 558,
              "inStock": true
            }
          ]
        },
        {
          "id": "munagaku",
          "productId": "munagaku_karam_podi",
          "name": "Munagaku Karam Podi",
          "tagline": "Drumstick-leaf spice powder",
          "image": "assets/images/sp_munagaku_podi.png",
          "enabled": true,
          "powderColor": "#6B7A2A",
          "accentColor": "#B5C24A",
          "glowColor": "#36400F",
          "heat": 2,
          "throwIn": [
            {
              "name": "Moringa leaves",
              "pieces": [
                "assets/images/moringa_0.png",
                "assets/images/moringa_1.png"
              ],
              "count": 4,
              "size": "big"
            },
            {
              "name": "Red chilli",
              "pieces": [
                "assets/images/redchilli_0.png",
                "assets/images/chillies_0.png"
              ],
              "count": 2,
              "size": "big"
            },
            {
              "name": "Cumin",
              "pieces": [
                "assets/images/cumin_0.png",
                "assets/images/cumin_1.png"
              ],
              "count": 8,
              "size": "small"
            }
          ],
          "chips": [
            {
              "name": "Moringa leaves",
              "icon": "assets/images/moringa_0.png"
            },
            {
              "name": "Red chilli",
              "icon": "assets/images/redchilli_0.png"
            },
            {
              "name": "Cumin",
              "icon": "assets/images/cumin_0.png"
            }
          ],
          "variants": [
            {
              "id": "munagaku_250g",
              "label": "250g",
              "price": 149,
              "mrp": 171,
              "inStock": true
            },
            {
              "id": "munagaku_500g",
              "label": "500g",
              "price": 283,
              "mrp": 325,
              "inStock": true
            },
            {
              "id": "munagaku_1kg",
              "label": "1kg",
              "price": 536,
              "mrp": 616,
              "inStock": true
            }
          ]
        },
        {
          "id": "idli_karam",
          "productId": "special_idli_karam_podi",
          "name": "Idli Karam Podi",
          "tagline": "Gun powder for idli & dosa",
          "image": "assets/images/sp_idli_karam_podi.png",
          "enabled": true,
          "powderColor": "#D9541E",
          "accentColor": "#FF9A4D",
          "glowColor": "#7A2A10",
          "heat": 3,
          "throwIn": [
            {
              "name": "Red chilli",
              "pieces": [
                "assets/images/redchilli_0.png",
                "assets/images/chillies_1.png"
              ],
              "count": 4,
              "size": "big"
            },
            {
              "name": "Urad dal",
              "pieces": [
                "assets/images/urad_0.png",
                "assets/images/urad_1.png"
              ],
              "count": 6,
              "size": "small"
            },
            {
              "name": "Chana dal",
              "pieces": [
                "assets/images/chanadal_0.png",
                "assets/images/chanadal_1.png"
              ],
              "count": 6,
              "size": "small"
            }
          ],
          "chips": [
            {
              "name": "Red chilli",
              "icon": "assets/images/redchilli_0.png"
            },
            {
              "name": "Urad dal",
              "icon": "assets/images/urad_0.png"
            },
            {
              "name": "Chana dal",
              "icon": "assets/images/chanadal_0.png"
            }
          ],
          "variants": [
            {
              "id": "idli_karam_250g",
              "label": "250g",
              "price": 139,
              "mrp": 160,
              "inStock": true
            },
            {
              "id": "idli_karam_500g",
              "label": "500g",
              "price": 264,
              "mrp": 304,
              "inStock": true
            },
            {
              "id": "idli_karam_1kg",
              "label": "1kg",
              "price": 500,
              "mrp": 576,
              "inStock": true
            }
          ]
        },
        {
          "id": "kura_karam",
          "productId": "special_kura_karam_podi",
          "name": "Kura Karam Podi",
          "tagline": "All-purpose curry powder",
          "image": "assets/images/sp_kura_karam_podi.png",
          "enabled": true,
          "powderColor": "#B91C1C",
          "accentColor": "#FF6B4A",
          "glowColor": "#6B1010",
          "heat": 3,
          "throwIn": [
            {
              "name": "Red chilli",
              "pieces": [
                "assets/images/redchilli_0.png",
                "assets/images/chillies_0.png"
              ],
              "count": 4,
              "size": "big"
            },
            {
              "name": "Coriander",
              "pieces": [
                "assets/images/coriander_0.png",
                "assets/images/coriander_1.png"
              ],
              "count": 6,
              "size": "small"
            },
            {
              "name": "Cumin",
              "pieces": [
                "assets/images/cumin_0.png",
                "assets/images/cumin_1.png"
              ],
              "count": 8,
              "size": "small"
            }
          ],
          "chips": [
            {
              "name": "Red chilli",
              "icon": "assets/images/redchilli_0.png"
            },
            {
              "name": "Coriander",
              "icon": "assets/images/coriander_0.png"
            },
            {
              "name": "Cumin",
              "icon": "assets/images/cumin_0.png"
            }
          ],
          "variants": [
            {
              "id": "kura_karam_250g",
              "label": "250g",
              "price": 139,
              "mrp": 160,
              "inStock": true
            },
            {
              "id": "kura_karam_500g",
              "label": "500g",
              "price": 264,
              "mrp": 304,
              "inStock": true
            },
            {
              "id": "kura_karam_1kg",
              "label": "1kg",
              "price": 500,
              "mrp": 576,
              "inStock": true
            }
          ]
        },
        {
          "id": "putnala",
          "productId": "putnala_karam_podi",
          "name": "Putnala Karam Podi",
          "tagline": "Roasted-gram spice powder",
          "image": "assets/images/sp_putnala_podi.png",
          "enabled": true,
          "powderColor": "#D9A441",
          "accentColor": "#F5CB6B",
          "glowColor": "#7A5410",
          "heat": 1,
          "throwIn": [
            {
              "name": "Roasted gram",
              "pieces": [
                "assets/images/roastedgram_0.png"
              ],
              "count": 3,
              "size": "big"
            },
            {
              "name": "Red chilli",
              "pieces": [
                "assets/images/redchilli_0.png",
                "assets/images/chillies_0.png"
              ],
              "count": 2,
              "size": "big"
            },
            {
              "name": "Cumin",
              "pieces": [
                "assets/images/cumin_0.png",
                "assets/images/cumin_1.png"
              ],
              "count": 6,
              "size": "small"
            }
          ],
          "chips": [
            {
              "name": "Roasted gram",
              "icon": "assets/images/roastedgram_0.png"
            },
            {
              "name": "Red chilli",
              "icon": "assets/images/redchilli_0.png"
            },
            {
              "name": "Cumin",
              "icon": "assets/images/cumin_0.png"
            }
          ],
          "variants": [
            {
              "id": "putnala_250g",
              "label": "250g",
              "price": 129,
              "mrp": 148,
              "inStock": true
            },
            {
              "id": "putnala_500g",
              "label": "500g",
              "price": 245,
              "mrp": 281,
              "inStock": true
            },
            {
              "id": "putnala_1kg",
              "label": "1kg",
              "price": 464,
              "mrp": 533,
              "inStock": true
            }
          ]
        },
        {
          "id": "menthi",
          "productId": "menthi_podi",
          "name": "Menthi Podi",
          "tagline": "Fenugreek spice powder",
          "image": "assets/images/sp_menthi_podi.png",
          "enabled": true,
          "powderColor": "#C99A1E",
          "accentColor": "#F2C64A",
          "glowColor": "#6E5208",
          "heat": 2,
          "throwIn": [
            {
              "name": "Fenugreek",
              "pieces": [
                "assets/images/fenugreek_0.png"
              ],
              "count": 3,
              "size": "big"
            },
            {
              "name": "Red chilli",
              "pieces": [
                "assets/images/redchilli_0.png",
                "assets/images/chillies_0.png"
              ],
              "count": 2,
              "size": "big"
            },
            {
              "name": "Mustard",
              "pieces": [
                "assets/images/mustard_0.png"
              ],
              "count": 2,
              "size": "big"
            }
          ],
          "chips": [
            {
              "name": "Fenugreek",
              "icon": "assets/images/fenugreek_0.png"
            },
            {
              "name": "Red chilli",
              "icon": "assets/images/redchilli_0.png"
            },
            {
              "name": "Mustard",
              "icon": "assets/images/mustard_0.png"
            }
          ],
          "variants": [
            {
              "id": "menthi_250g",
              "label": "250g",
              "price": 129,
              "mrp": 148,
              "inStock": true
            },
            {
              "id": "menthi_500g",
              "label": "500g",
              "price": 245,
              "mrp": 281,
              "inStock": true
            },
            {
              "id": "menthi_1kg",
              "label": "1kg",
              "price": 464,
              "mrp": 533,
              "inStock": true
            }
          ]
        },
        {
          "id": "daniya",
          "productId": "daniya_powder",
          "name": "Daniya Powder",
          "tagline": "Freshly ground coriander",
          "image": "assets/images/sp_daniya_powder.png",
          "enabled": true,
          "powderColor": "#A8814F",
          "accentColor": "#D6B07A",
          "glowColor": "#5A3F1C",
          "heat": 1,
          "throwIn": [
            {
              "name": "Coriander",
              "pieces": [
                "assets/images/coriander_0.png",
                "assets/images/coriander_1.png"
              ],
              "count": 10,
              "size": "small"
            }
          ],
          "chips": [
            {
              "name": "Coriander",
              "icon": "assets/images/coriander_0.png"
            }
          ],
          "variants": [
            {
              "id": "daniya_250g",
              "label": "250g",
              "price": 99,
              "mrp": 114,
              "inStock": true
            },
            {
              "id": "daniya_500g",
              "label": "500g",
              "price": 188,
              "mrp": 217,
              "inStock": true
            },
            {
              "id": "daniya_1kg",
              "label": "1kg",
              "price": 356,
              "mrp": 410,
              "inStock": true
            }
          ]
        },
        {
          "id": "haldi",
          "productId": "haldi_powder",
          "name": "Haldi Powder",
          "tagline": "Pure turmeric powder",
          "image": "assets/images/sp_haldi_powder.png",
          "enabled": true,
          "powderColor": "#E8A317",
          "accentColor": "#FFD04A",
          "glowColor": "#7A5208",
          "heat": 1,
          "throwIn": [
            {
              "name": "Turmeric",
              "pieces": [
                "assets/images/turmeric_0.png"
              ],
              "count": 4,
              "size": "big"
            }
          ],
          "chips": [
            {
              "name": "Turmeric",
              "icon": "assets/images/turmeric_0.png"
            }
          ],
          "variants": [
            {
              "id": "haldi_250g",
              "label": "250g",
              "price": 99,
              "mrp": 114,
              "inStock": true
            },
            {
              "id": "haldi_500g",
              "label": "500g",
              "price": 188,
              "mrp": 217,
              "inStock": true
            },
            {
              "id": "haldi_1kg",
              "label": "1kg",
              "price": 356,
              "mrp": 410,
              "inStock": true
            }
          ]
        },
        {
          "id": "garam",
          "productId": "garam_masala_powder",
          "name": "Garam Masala",
          "tagline": "Warm whole-spice blend",
          "image": "assets/images/sp_garam_masala.png",
          "enabled": true,
          "powderColor": "#6B3A1E",
          "accentColor": "#B0703F",
          "glowColor": "#3A1C0A",
          "heat": 2,
          "throwIn": [
            {
              "name": "Cinnamon",
              "pieces": [
                "assets/images/cinnamon_0.png"
              ],
              "count": 2,
              "size": "big"
            },
            {
              "name": "Star anise",
              "pieces": [
                "assets/images/staranise_0.png"
              ],
              "count": 2,
              "size": "big"
            },
            {
              "name": "Cloves",
              "pieces": [
                "assets/images/cloves_0.png"
              ],
              "count": 2,
              "size": "big"
            }
          ],
          "chips": [
            {
              "name": "Cinnamon",
              "icon": "assets/images/cinnamon_0.png"
            },
            {
              "name": "Star anise",
              "icon": "assets/images/staranise_0.png"
            },
            {
              "name": "Cloves",
              "icon": "assets/images/cloves_0.png"
            }
          ],
          "variants": [
            {
              "id": "garam_250g",
              "label": "250g",
              "price": 159,
              "mrp": 183,
              "inStock": true
            },
            {
              "id": "garam_500g",
              "label": "500g",
              "price": 302,
              "mrp": 348,
              "inStock": true
            },
            {
              "id": "garam_1kg",
              "label": "1kg",
              "price": 572,
              "mrp": 659,
              "inStock": true
            }
          ]
        },
        {
          "id": "sambhar",
          "productId": "sambhar_masala_powder",
          "name": "Sambhar Masala",
          "tagline": "For everyday sambar",
          "image": "assets/images/sp_sambhar_masala.png",
          "enabled": true,
          "powderColor": "#B4451C",
          "accentColor": "#F07A3E",
          "glowColor": "#5E200A",
          "heat": 2,
          "throwIn": [
            {
              "name": "Red chilli",
              "pieces": [
                "assets/images/redchilli_0.png",
                "assets/images/chillies_0.png"
              ],
              "count": 3,
              "size": "big"
            },
            {
              "name": "Coriander",
              "pieces": [
                "assets/images/coriander_0.png",
                "assets/images/coriander_1.png"
              ],
              "count": 6,
              "size": "small"
            },
            {
              "name": "Chana dal",
              "pieces": [
                "assets/images/chanadal_0.png",
                "assets/images/chanadal_1.png"
              ],
              "count": 5,
              "size": "small"
            }
          ],
          "chips": [
            {
              "name": "Red chilli",
              "icon": "assets/images/redchilli_0.png"
            },
            {
              "name": "Coriander",
              "icon": "assets/images/coriander_0.png"
            },
            {
              "name": "Chana dal",
              "icon": "assets/images/chanadal_0.png"
            }
          ],
          "variants": [
            {
              "id": "sambhar_250g",
              "label": "250g",
              "price": 139,
              "mrp": 160,
              "inStock": true
            },
            {
              "id": "sambhar_500g",
              "label": "500g",
              "price": 264,
              "mrp": 304,
              "inStock": true
            },
            {
              "id": "sambhar_1kg",
              "label": "1kg",
              "price": 500,
              "mrp": 576,
              "inStock": true
            }
          ]
        },
        {
          "id": "chicken",
          "productId": "chicken_masala_powder",
          "name": "Chicken Masala",
          "tagline": "Rich chicken curry blend",
          "image": "assets/images/sp_chicken_masala.png",
          "enabled": true,
          "powderColor": "#A3301A",
          "accentColor": "#E8653A",
          "glowColor": "#561408",
          "heat": 3,
          "throwIn": [
            {
              "name": "Red chilli",
              "pieces": [
                "assets/images/redchilli_0.png",
                "assets/images/chillies_0.png"
              ],
              "count": 3,
              "size": "big"
            },
            {
              "name": "Cardamom",
              "pieces": [
                "assets/images/cardamom_0.png"
              ],
              "count": 2,
              "size": "big"
            },
            {
              "name": "Bay leaf",
              "pieces": [
                "assets/images/bayleaf_0.png"
              ],
              "count": 2,
              "size": "big"
            }
          ],
          "chips": [
            {
              "name": "Red chilli",
              "icon": "assets/images/redchilli_0.png"
            },
            {
              "name": "Cardamom",
              "icon": "assets/images/cardamom_0.png"
            },
            {
              "name": "Bay leaf",
              "icon": "assets/images/bayleaf_0.png"
            }
          ],
          "variants": [
            {
              "id": "chicken_250g",
              "label": "250g",
              "price": 149,
              "mrp": 171,
              "inStock": true
            },
            {
              "id": "chicken_500g",
              "label": "500g",
              "price": 283,
              "mrp": 325,
              "inStock": true
            },
            {
              "id": "chicken_1kg",
              "label": "1kg",
              "price": 536,
              "mrp": 616,
              "inStock": true
            }
          ]
        },
        {
          "id": "mutton",
          "productId": "mutton_masala_powder",
          "name": "Mutton Masala",
          "tagline": "Bold mutton curry blend",
          "image": "assets/images/sp_mutton_masala.png",
          "enabled": true,
          "powderColor": "#7A2414",
          "accentColor": "#C2503A",
          "glowColor": "#3D0E06",
          "heat": 3,
          "throwIn": [
            {
              "name": "Black pepper",
              "pieces": [
                "assets/images/blackpepper_0.png"
              ],
              "count": 2,
              "size": "big"
            },
            {
              "name": "Cloves",
              "pieces": [
                "assets/images/cloves_0.png"
              ],
              "count": 2,
              "size": "big"
            },
            {
              "name": "Cinnamon",
              "pieces": [
                "assets/images/cinnamon_0.png"
              ],
              "count": 2,
              "size": "big"
            }
          ],
          "chips": [
            {
              "name": "Black pepper",
              "icon": "assets/images/blackpepper_0.png"
            },
            {
              "name": "Cloves",
              "icon": "assets/images/cloves_0.png"
            },
            {
              "name": "Cinnamon",
              "icon": "assets/images/cinnamon_0.png"
            }
          ],
          "variants": [
            {
              "id": "mutton_250g",
              "label": "250g",
              "price": 159,
              "mrp": 183,
              "inStock": true
            },
            {
              "id": "mutton_500g",
              "label": "500g",
              "price": 302,
              "mrp": 348,
              "inStock": true
            },
            {
              "id": "mutton_1kg",
              "label": "1kg",
              "price": 572,
              "mrp": 659,
              "inStock": true
            }
          ]
        }
      ]
    };

  static final List<Map<String, dynamic>> _defaultAutoBannersData = [
    {'id': 'b1', 'image': 'assets/images/banner_1.jpg', 'link': {'category': 'Pickles'}},
    {'id': 'b2', 'image': 'assets/images/banner_2.jpg', 'link': {'category': 'Powders'}},
    {'id': 'b3', 'image': 'assets/images/banner_3.jpg', 'link': {'category': 'Sweets'}},
    {'id': 'b4', 'image': 'assets/images/banner_4.jpg', 'link': {'category': 'Snacks'}},
  ];

  static final List<Map<String, dynamic>> _defaultStorySnacksData = [
    {
      'id': 'murukku',
      'name': 'Kara Murukku',
      'image': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
      'price': 129,
      'story': 'A crispy spiral snack made from rice flour and urad dal, prepared in our family kitchen for festive evenings.',
      'since': '1985',
      'ingredients': [
        {'name': 'Rice Flour', 'image': 'assets/images/rice_papad_crispy_rice_flour_papadums.jpg'},
        {'name': 'Urad Dal', 'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg'},
        {'name': 'Spices', 'image': 'assets/images/special_kura_karam_podi_all-purpose_curry_powder.jpg'},
      ],
    },
    {
      'id': 'mixture',
      'name': 'Khara Mixture',
      'image': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
      'price': 149,
      'story': 'A delicious assortment of spiced boondi, peanuts, and sev tossed with roasted curry leaves in pure oil.',
      'since': '1992',
      'ingredients': [
        {'name': 'Gram Flour', 'image': 'assets/images/bundhi_crispy_spiced_gram_flour_droplets.jpg'},
        {'name': 'Peanuts', 'image': 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg'},
        {'name': 'Curry Leaves', 'image': 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg'},
      ],
    },
    {
      'id': 'sunnunda',
      'name': 'Sunnunda Laddu',
      'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
      'price': 199,
      'story': 'Traditional roasted urad dal laddus sweetened with organic bellam (jaggery) and rich cow ghee.',
      'since': '1978',
      'ingredients': [
        {'name': 'Urad Dal', 'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg'},
        {'name': 'Pure Ghee', 'image': 'assets/images/good_food_text.png'},
        {'name': 'Bellam', 'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg'},
      ],
    },
    {
      'id': 'chips',
      'name': 'Banana Chips',
      'image': 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
      'price': 119,
      'story': 'Thinly sliced raw bananas fried in cold-pressed coconut oil and sprinkled with sea salt & black pepper.',
      'since': '1998',
      'ingredients': [
        {'name': 'Raw Banana', 'image': 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg'},
        {'name': 'Coconut Oil', 'image': 'assets/images/good_food_text.png'},
        {'name': 'Sea Salt', 'image': 'assets/images/uppava_traditional_salted_pickle.jpg'},
      ],
    },
  ];

  static final List<Map<String, dynamic>> _defaultSpecialsLightData = <Map<String, dynamic>>[
    {'id': 'gongura_pickle', 'name': 'Gongura Pickle', 'image': 'assets/images/special_gongura_pickle.png'},
    {'id': 'tomato_pickle', 'name': 'Tomato Pickle', 'image': 'assets/images/special_tomato_pickle.png'},
    {'id': 'kandi_podi', 'name': 'Kandi Podi', 'image': 'assets/images/special_kandi_podi.png'},
    {'id': 'chekkalu', 'name': 'Chekkalu', 'image': 'assets/images/special_chekkalu.png'},
    {'id': 'ariselu', 'name': 'Ariselu', 'image': 'assets/images/special_ariselu.png'},
    {'id': 'kaju_mixture', 'name': 'Kaju Mixture', 'image': 'assets/images/special_kaju_mixture.png'},
  ];

  static final List<Map<String, dynamic>> _defaultPairingsData = [
    {
      'id': 'breakfast',
      'kicker': 'BREAKFAST',
      'title': "Dosa's Best Friends",
      'desc': 'Karam Podi + Avakaya',
      'price': 379,
      'imageA': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
      'imageB': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      'colors': ['#5C0A0D', '#7A0F12', '#9B1D22'],
      'pairs': [
        {
          'id': 'br1',
          'tag': '',
          'imageA': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
          'imageB': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
          'name': 'Karam Podi + Avakaya',
          'bestWith': 'Dosa · Idli',
          'price': 379,
        },
        {
          'id': 'br2',
          'tag': '',
          'imageA': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
          'imageB': 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg',
          'name': 'Karam Podi + Masala Peanuts',
          'bestWith': 'Dosa · Idli',
          'price': 299,
        },
        {
          'id': 'br3',
          'tag': '',
          'imageA': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
          'imageB': 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg',
          'name': 'Avakaya + Masala Peanuts',
          'bestWith': 'Dosa · Upma',
          'price': 329,
        },
      ],
    },
    {
      'id': 'evening_tea',
      'kicker': 'EVENING TEA',
      'title': "Chai's Crunchy Partners",
      'desc': 'Murukku + Banana Chips',
      'price': 299,
      'imageA': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
      'imageB': 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
      'colors': ['#18453B', '#235D4E', '#2E7563'],
      'pairs': [
        {
          'id': 'et1',
          'tag': '',
          'imageA': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
          'imageB': 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
          'name': 'Murukku + Banana Chips',
          'bestWith': 'Evening tea',
          'price': 299,
        },
        {
          'id': 'et2',
          'tag': '',
          'imageA': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
          'imageB': 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg',
          'name': 'Spicy Mixture + Masala Peanuts',
          'bestWith': 'Evening tea',
          'price': 279,
        },
        {
          'id': 'et3',
          'tag': '',
          'imageA': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
          'imageB': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
          'name': 'Murukku + Spicy Mixture',
          'bestWith': 'Evening tea',
          'price': 319,
        },
      ],
    },
    {
      'id': 'after_meals',
      'kicker': 'AFTER MEALS',
      'title': 'Sweet Endings',
      'desc': 'Sunnunda Laddu + Murukku',
      'price': 399,
      'imageA': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
      'imageB': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
      'colors': ['#8B4513', '#A0522D', '#B8860B'],
      'pairs': [
        {
          'id': 'am1',
          'tag': '',
          'imageA': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
          'imageB': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
          'name': 'Sunnunda Laddu + Murukku',
          'bestWith': 'After meals · Gifting',
          'price': 399,
        },
        {
          'id': 'am2',
          'tag': '',
          'imageA': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
          'imageB': 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
          'name': 'Sunnunda Laddu + Banana Chips',
          'bestWith': 'After meals · Gifting',
          'price': 379,
        },
        {
          'id': 'am3',
          'tag': '',
          'imageA': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
          'imageB': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
          'name': 'Sunnunda Laddu + Spicy Mixture',
          'bestWith': 'After meals · Gifting',
          'price': 389,
        },
      ],
    },
  ];

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
    // no heavy default video: wait for the real settings from the server
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

  static final Map<String, dynamic> _defaultReviewsData = {
    'settings': {
      'enabled': true,
      'eyebrow': 'LETTERS FROM HOME',
      'title': 'What families',
      'titleAccent': 'write to Amma',
      'subtitle': 'Real notes from real kitchens 💌',
      'seeAllLabel': 'See all',
      'writeLabel': '✍️ Write to Amma',
      'ringText': '★ 1.2k REVIEWS ★ MADE WITH LOVE ★ ',
      'wallTop': '#1F6B55',
      'wallMid': '#0F3F33',
      'wallBottom': '#082520',
      'accent': '#FFD58A',
      'gold': '#E9C46A',
      'autoplayMs': 4200
    },
    'summary': {
      'average': 4.9,
      'count': 1248
    },
    'reviews': [
      {
        'id': 'r1',
        'productId': 'p1',
        'productName': 'Avakaya Pickle',
        'text': 'Dear Amma, the Avakaya pickle tastes exactly like my grandmother used to make in Vijayawada. It brought back so many childhood memories!',
        'name': 'Siri M.',
        'meta': 'Verified Purchaser · Hyderabad',
        'photoUrl': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
        'photoCaption': 'Opened today! 🏺',
        'stars': 5,
        'verified': true,
        'tagBg': '#FDE8EA',
        'tagFg': '#C2273A'
      },
      {
        'id': 'r2',
        'productId': 'p2',
        'productName': 'Idli Karam Podi',
        'text': 'The aroma of roasted chana dal and garlic when I opened the pouch was amazing. Eating hot idlis with ghee and this Podi every morning!',
        'name': 'Rajesh V.',
        'meta': 'Verified Purchaser · Bengaluru',
        'photoUrl': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
        'photoCaption': 'Perfect breakfast 😋',
        'stars': 5,
        'verified': true,
        'tagBg': '#FFF0E0',
        'tagFg': '#D2691E'
      },
      {
        'id': 'r3',
        'productId': 'p3',
        'productName': 'Sunnunda Laddu',
        'text': 'The pure cow ghee aroma and crunch of roasted urad dal laddus are unmatchable. My children finish the whole box in two days!',
        'name': 'Ananya K.',
        'meta': 'Verified Purchaser · Chennai',
        'photoUrl': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
        'photoCaption': 'Kids loved it! 🎁',
        'stars': 5,
        'verified': true,
        'tagBg': '#FEF3C7',
        'tagFg': '#B45309'
      }
    ]
  };

  static final Map<String, dynamic> _defaultPicklesData = {
    'settings': {
      'enabled': true,
      'eyebrow': 'HAND-MIXED · SUN-CURED',
      'title': 'Amma\'s Pickles',
      'viewAllLabel': 'View all →',
      'addLabel': 'Add to cart',
      'chilliIcon': 'assets/images/chilli.png'
    },
    'pickles': [
      {
        'productId': 'mango_avakaya',
        'variantId': '500g',
        'name': 'Mango Avakaya',
        'tag': 'Best Seller',
        'description': 'Sun-dried raw mangoes with Guntur chillies & cold-pressed sesame oil.',
        'cureNote': '3-week sun cured',
        'thumb': 'assets/images/mango_close.jpg',
        'spice': 4,
        'price': 349,
        'mrp': 399,
        'theme': {
          'c1': '#C2273A',
          'c2': '#7A0F12',
          'accent': '#FFD58A',
          'accent2': '#E9C46A',
          'glow': '#FFB450'
        },
        'shots': [
          {'url': 'assets/images/mango_bowl.jpg', 'caption': 'Tossed by hand in small batches', 'scaleFrom': 1.15, 'scaleTo': 1.0, 'ms': 3500},
          {'url': 'assets/images/mango_jar.jpg', 'caption': 'Preserved in traditional bharanis', 'scaleFrom': 1.1, 'scaleTo': 1.1, 'panXFrom': 0, 'panXTo': 0.08, 'ms': 2500},
          {'url': 'assets/images/mango_spoon.jpg', 'caption': 'Pairs perfectly with hot rice & ghee', 'scaleFrom': 1.0, 'scaleTo': 1.12, 'ms': 3000}
        ]
      },
      {
        'productId': 'lemon_pickle',
        'variantId': '250g',
        'name': 'Lemon Pickle',
        'tag': 'Ammamma\'s Recipe',
        'description': 'Juicy lemons aged with rock salt and roasted fenugreek.',
        'cureNote': '1-year aged',
        'thumb': 'assets/images/lemon_close.jpg',
        'spice': 2,
        'price': 149,
        'mrp': 175,
        'theme': {
          'c1': '#D4AF37',
          'c2': '#8A5A19',
          'accent': '#FFF3E0',
          'accent2': '#FFE0B2',
          'glow': '#FFD54F'
        },
        'shots': [
          {'url': 'assets/images/lemon_bowl.jpg', 'caption': 'Freshly squeezed lemons', 'scaleFrom': 1.1, 'scaleTo': 1.0, 'ms': 3000},
          {'url': 'assets/images/lemon_jar.jpg', 'caption': 'Aged to perfection', 'scaleFrom': 1.0, 'scaleTo': 1.1, 'panYFrom': 0, 'panYTo': 0.05, 'ms': 2800},
          {'url': 'assets/images/lemon_spoon.jpg', 'caption': 'Tangy, spicy, and irresistible', 'scaleFrom': 1.05, 'scaleTo': 1.15, 'ms': 3200}
        ]
      },
      {
        'productId': 'gongura_pickle',
        'variantId': '250g',
        'name': 'Gongura Pickle',
        'tag': 'Andhra Special',
        'description': 'Hand-picked sorrel leaves cooked with red chillies & garlic.',
        'cureNote': 'Wood-fired',
        'thumb': 'assets/images/gongura_close.jpg',
        'spice': 5,
        'price': 179,
        'mrp': 210,
        'theme': {
          'c1': '#1F5A1E',
          'c2': '#0B2E0B',
          'accent': '#C5E1A5',
          'accent2': '#9CCC65',
          'glow': '#AED581'
        },
        'shots': [
          {'url': 'assets/images/gongura_bowl.jpg', 'caption': 'Farm fresh Gongura leaves', 'scaleFrom': 1.2, 'scaleTo': 1.0, 'ms': 3200},
          {'url': 'assets/images/gongura_jar.jpg', 'caption': 'The authentic taste of Andhra', 'scaleFrom': 1.0, 'scaleTo': 1.05, 'panXFrom': -0.05, 'panXTo': 0.05, 'ms': 2500},
          {'url': 'assets/images/gongura_spoon.jpg', 'caption': 'A burst of tangy heat', 'scaleFrom': 1.0, 'scaleTo': 1.1, 'ms': 3300}
        ]
      },
      {
        'productId': 'garlic_pickle',
        'variantId': '250g',
        'name': 'Garlic Pickle',
        'tag': 'Immunity Booster',
        'description': 'Peeled garlic cloves roasted in mustard oil with traditional spices.',
        'cureNote': 'Slow-roasted',
        'thumb': 'assets/images/garlic_close.jpg',
        'spice': 3,
        'price': 199,
        'mrp': 240,
        'theme': {
          'c1': '#8A4A1C',
          'c2': '#3A1A05',
          'accent': '#FFCC80',
          'accent2': '#FFA726',
          'glow': '#FFB74D'
        },
        'shots': [
          {'url': 'assets/images/garlic_bowl.jpg', 'caption': 'Hand-peeled garlic cloves', 'scaleFrom': 1.15, 'scaleTo': 1.05, 'ms': 2800},
          {'url': 'assets/images/garlic_jar.jpg', 'caption': 'Infused with aromatic spices', 'scaleFrom': 1.05, 'scaleTo': 1.15, 'panYFrom': 0.05, 'panYTo': -0.05, 'ms': 2800},
          {'url': 'assets/images/garlic_spoon.jpg', 'caption': 'Healthy and deeply flavorful', 'scaleFrom': 1.0, 'scaleTo': 1.1, 'ms': 3400}
        ]
      }
    ]
  };

  static final Map<String, dynamic> _defaultTrustData = {
    'enabled': true,
    'eyebrow': 'THE AMBHUJAKSHI PROMISE',
    'heading': 'Everything we make comes',
    'headingAccent': 'four promises',
    'ribbon': 'SINCE 1982',
    'logo': 'assets/images/AMBHUJAKSHI  logo.png',
    'rating': '4.9',
    'footer': 'Loved by 12,000+ families',
    'tags': [
      {'title': '100%\nNatural', 'sub': 'No preservatives', 'icon': 'leaf', 'color1': '#3FA34D', 'color2': '#1F7A35'},
      {'title': 'Amma\'s\nRecipe', 'sub': 'Authentic taste', 'icon': 'home', 'color1': '#E96446', 'color2': '#C23A22'},
      {'title': 'Fast\nDelivery', 'sub': 'Freshness intact', 'icon': 'truck', 'color1': '#4A90E2', 'color2': '#2A64B2'},
      {'title': 'Secure\nPacking', 'sub': 'No leaks or spills', 'icon': 'shield', 'color1': '#9B59B6', 'color2': '#7A2C9B'}
    ],
    'shelf': [
      {'label': 'Pickles', 'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', 'category': 'Pickles'},
      {'label': 'Powders', 'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg', 'category': 'Powders'},
      {'label': 'Sweets', 'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg', 'category': 'Sweets'},
      {'label': 'Snacks', 'image': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg', 'category': 'Snacks'},
      {'label': 'Gifts', 'image': 'assets/images/good_food_text.png', 'category': 'Gifts'}
    ]
  };

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

  // 21. Featured Video Showcase (After Royal Collections, Admin Controlled)
  static Map<String, dynamic> _inMemoryFeaturedVideoConfig = {};

  Stream<Map<String, dynamic>> getFeaturedVideoConfigStream() async* {
    if (_inMemoryFeaturedVideoConfig.isNotEmpty) {
      yield _inMemoryFeaturedVideoConfig;
    } else {
      yield _defaultFeaturedVideoData;
    }
    try {
      Map<String, dynamic> combined = {};
      for (var id in ['sector_2', 'sector2', 'after_header_video', 'snacks_video', 'royal_recipes', 'featured_video_section', 'royal_collection', 'royal_video', 'ambhu_jakshi_royal', 'featured_video']) {
        final data = await ApiService.getAppConfig(id);
        if (data.isNotEmpty) {
          combined.addAll(data);
          final foundUrl = data['video_url']?.toString() ??
                           data['url']?.toString() ??
                           data['video']?.toString() ??
                           data['link']?.toString() ??
                           data['media_url']?.toString() ??
                           data['file']?.toString() ??
                           data['path']?.toString() ??
                           data['royal_collection_video']?.toString();
          if (foundUrl != null && foundUrl.isNotEmpty) {
            _inMemoryFeaturedVideoConfig = combined;
            yield combined;
            break;
          }
        }
      }
      if (combined.isNotEmpty && !_inMemoryFeaturedVideoConfig.containsKey('video_url')) {
        _inMemoryFeaturedVideoConfig = combined;
        yield combined;
      }
    } catch (_) {}
  }

  Future<bool> saveFeaturedVideoConfig(Map<String, dynamic> videoData) async {
    _inMemoryFeaturedVideoConfig = videoData;
    try {
      return await ApiService.saveAppConfig('featured_video_section', videoData);
    } catch (e) {
      debugPrint('Error saving featured video config: $e');
      return true;
    }
  }

  static final Map<String, dynamic> _defaultFeaturedVideoData = {
    'enabled': true,
    'tag': 'HERITAGE IN MOTION',
    'title': 'Behind the Craft: Our Sun-Dried Tradition',
    'subtitle': 'Watch how our 40-year-old authentic recipes come to life.',
    'video_url': 'assets/images/ambhujakshi-all.mp4',
  };

  // 22. Tab Transition Video Overlay (Admin Controlled)
  static Map<String, dynamic> _inMemoryTabTransitionConfig = {};

  Stream<Map<String, dynamic>> getTabTransitionConfigStream() async* {
    if (_inMemoryTabTransitionConfig.isNotEmpty) {
      yield _inMemoryTabTransitionConfig;
    } else {
      yield _defaultTabTransitionData;
    }
    try {
      final data = await ApiService.getAppConfig('tab_transition_video');
      if (data.isNotEmpty) {
        _inMemoryTabTransitionConfig = data;
        yield data;
      }
    } catch (_) {}
  }

  Future<bool> saveTabTransitionConfig(Map<String, dynamic> configData) async {
    _inMemoryTabTransitionConfig = configData;
    try {
      return await ApiService.saveAppConfig('tab_transition_video', configData);
    } catch (e) {
      debugPrint('Error saving tab transition config: $e');
      return true;
    }
  }

  static final Map<String, dynamic> _defaultTabTransitionData = {
    'enabled': true,
    'duration_ms': 1200,
    'video_url': 'assets/images/ambhujakshi-all.mp4',
    'caption': 'Swapping Heritage Kitchens...',
    'show_spinner': true,
  };
}
