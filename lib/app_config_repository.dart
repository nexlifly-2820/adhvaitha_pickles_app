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

  static final List<Map<String, dynamic>> _defaultSpecialsLightData = [
    {
      'id': 'avakaya',
      'name': 'Avakaya',
      'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
    },
    {
      'id': 'karam_podi',
      'name': 'Karam Podi',
      'image': 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg',
    },
    {
      'id': 'murukku',
      'name': 'Murukku',
      'image': 'assets/images/karam_janthukalu_murukku_strings_snack.jpg',
    },
    {
      'id': 'sunnunda',
      'name': 'Sunnunda',
      'image': 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg',
    },
    {
      'id': 'mixture',
      'name': 'Mixture',
      'image': 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg',
    },
    {
      'id': 'banana_chips',
      'name': 'Banana Chips',
      'image': 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg',
    },
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

  // 21. Featured Video Showcase (After Royal Collections, Admin Controlled)
  static Map<String, dynamic> _inMemoryFeaturedVideoConfig = {};

  Stream<Map<String, dynamic>> getFeaturedVideoConfigStream() async* {
    if (_inMemoryFeaturedVideoConfig.isNotEmpty) {
      yield _inMemoryFeaturedVideoConfig;
    } else {
      yield _defaultFeaturedVideoData;
    }
    try {
      final data = await ApiService.getAppConfig('featured_video_section');
      if (data.isNotEmpty) {
        _inMemoryFeaturedVideoConfig = data;
        yield data;
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
