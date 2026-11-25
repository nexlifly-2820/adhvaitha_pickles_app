// combo_shared.dart — models, API and the 3D kraft box painter used by
//   combo_home_section.dart (home card) and combo_box_screen.dart (full screen).
// Data comes from combo_box_backend.js → GET /api/combo-box (managed in admin_combo_box.html)
//
// pubspec.yaml:  http: ^1.2.0   google_fonts: ^6.2.1

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api_service.dart';

// ───────────────────────── models ─────────────────────────
class ComboPrice {
  final String variantId;
  final double price, mrp;
  final bool inStock;
  ComboPrice(this.variantId, this.price, this.mrp, this.inStock);
}

class ComboProduct {
  final String id, productId, name, image, category;
  final Map<String, ComboPrice> prices;
  ComboProduct(this.id, this.productId, this.name, this.image, this.category, this.prices);
}

class ComboTier {
  final int jars;
  final double percent;
  ComboTier(this.jars, this.percent);
}

class ComboSettings {
  bool enabled = true;
  String eyebrow = 'BUILD YOUR BOX', titleStart = "Amma's", titleAccent = 'Combo Box';
  String boxLabel = "Amma's Combo", lidText = 'Made with love, packed by Amma', tagText = 'For you, with love';
  String homeLine = 'pick any 4 jars, Amma packs them', homeTitle = 'Fill the box,', homeAccent = 'save more';
  String homeButton = 'Start building your box';
  int jars = 4;
  List<String> sizes = <String>['250 g', '500 g', '1 kg'];
  List<String> categories = <String>['Pickles', 'Podis', 'Snacks', 'Sweets'];
  List<ComboTier> tiers = <ComboTier>[ComboTier(2, 5), ComboTier(3, 10), ComboTier(4, 15)];
  double get maxPercent => tiers.isEmpty ? 0.0 : tiers.map((ComboTier t) => t.percent).reduce(math.max);
  double percentFor(int n) {
    double p = 0.0;
    for (final ComboTier t in tiers) {
      if (n >= t.jars) p = t.percent;
    }
    return p;
  }
}

class ComboData {
  final ComboSettings settings;
  final List<ComboProduct> products;
  ComboData(this.settings, this.products);
}

double _n(dynamic v) => (v is num) ? v.toDouble() : (double.tryParse('$v') ?? 0.0);
String comboRs(double v) => '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';
String comboPct(double v) => '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)}%';

String _abs(String apiBase, String u) {
  if (u.isEmpty || u.startsWith('http') || u.startsWith('assets/')) return u;
  final String origin = apiBase.replaceAll(RegExp(r'/api/?$'), '');
  return u.startsWith('/') ? '$origin$u' : '$origin/$u';
}

ComboData? _parseCombo(Map<String, dynamic> j, String apiBase) {
  final Map<String, dynamic> s = j['settings'] is Map ? Map<String, dynamic>.from(j['settings'] as Map) : <String, dynamic>{};
  final ComboSettings st = ComboSettings();
  st.enabled = s['enabled'] != false;
  String str(String k, String d) => (s[k] == null || '${s[k]}'.isEmpty) ? d : '${s[k]}';
  st.eyebrow = str('eyebrow', st.eyebrow);
  st.titleStart = str('titleStart', st.titleStart);
  st.titleAccent = str('titleAccent', st.titleAccent);
  st.boxLabel = str('boxLabel', st.boxLabel);
  st.lidText = str('lidText', st.lidText).replaceAll('\n', ' ');
  st.tagText = str('tagText', st.tagText);
  st.homeLine = str('homeLine', st.homeLine);
  st.homeTitle = str('homeTitle', st.homeTitle);
  st.homeAccent = str('homeAccent', st.homeAccent);
  st.homeButton = str('homeButton', st.homeButton);
  st.jars = math.max(2, math.min(4, _n(s['jars']).toInt() == 0 ? 4 : _n(s['jars']).toInt()));
  final List<dynamic> sz = (s['sizes'] as List?) ?? <dynamic>[];
  if (sz.isNotEmpty) st.sizes = sz.map((dynamic e) => '$e').where((String e) => e.trim().isNotEmpty).toList();
  final List<dynamic> cats = (s['categories'] as List?) ?? <dynamic>[];
  if (cats.isNotEmpty) st.categories = cats.map((dynamic e) => '$e').where((String e) => e.trim().isNotEmpty).toList();
  final List<dynamic> tr = (s['tiers'] as List?) ?? <dynamic>[];
  if (tr.isNotEmpty) {
    st.tiers = tr.whereType<Map>().map((Map m) => ComboTier(_n(m['jars']).toInt(), _n(m['percent'])))
        .where((ComboTier t) => t.jars > 0 && t.percent > 0).toList()
      ..sort((ComboTier a, ComboTier b) => a.jars.compareTo(b.jars));
  }
  final List<ComboProduct> ps = <ComboProduct>[];
  for (final dynamic raw in (j['products'] as List?) ?? <dynamic>[]) {
    if (raw is! Map) continue;
    final Map<String, dynamic> m = Map<String, dynamic>.from(raw);
    if (m['enabled'] == false || '${m['name'] ?? ''}'.trim().isEmpty) continue;
    final Map<String, ComboPrice> prices = <String, ComboPrice>{};
    final Map<String, dynamic> pm = m['prices'] is Map ? Map<String, dynamic>.from(m['prices'] as Map) : <String, dynamic>{};
    pm.forEach((String k, dynamic v) {
      if (v is! Map) return;
      final double price = _n(v['price']);
      if (price <= 0) return;
      prices[k] = ComboPrice('${v['variantId'] ?? k}', price, _n(v['mrp']), v['inStock'] != false);
    });
    if (prices.isEmpty) continue;
    ps.add(ComboProduct('${m['id']}', '${m['productId'] ?? ''}', '${m['name'] ?? ''}', _abs(apiBase, '${m['image'] ?? ''}'), '${m['category'] ?? ''}', prices));
  }
  if (ps.isEmpty) return null;
  return ComboData(st, ps);
}

// Built-in combo: every product as a brass bowl. Used until the admin saves the Combo Box tab.
final Map<String, dynamic> _comboFallback = <String, dynamic>{
    "settings": {
      "enabled": true,
      "eyebrow": "BUILD YOUR BOX",
      "titleStart": "Amma's",
      "titleAccent": "Combo Box",
      "boxLabel": "Amma's Combo",
      "lidText": "Made with love, packed by Amma",
      "tagText": "For you, with love",
      "homeLine": "pick any 4 jars, Amma packs them",
      "homeTitle": "Fill the box,",
      "homeAccent": "save more",
      "homeButton": "Start building your box",
      "jars": 4,
      "sizes": [
        "250g",
        "500g",
        "1kg"
      ],
      "categories": [
        "Pickles",
        "Podis",
        "Snacks",
        "Sweets"
      ],
      "tiers": [
        {
          "jars": 2,
          "percent": 10
        },
        {
          "jars": 3,
          "percent": 15
        },
        {
          "jars": 4,
          "percent": 25
        }
      ]
    },
    "products": [
      {
        "id": "bellam_avakaya",
        "productId": "bellam_avakaya",
        "name": "Bellam Avakaya",
        "category": "Pickles",
        "image": "assets/images/loved_bellam_avakaya.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 219,
            "mrp": 252,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 416,
            "mrp": 479,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 788,
            "mrp": 907,
            "inStock": true
          }
        }
      },
      {
        "id": "gongura_pickle",
        "productId": "gongura_pickle",
        "name": "Gongura Pickle",
        "category": "Pickles",
        "image": "assets/images/loved_gongura_pickle.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 189,
            "mrp": 217,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 359,
            "mrp": 412,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 680,
            "mrp": 781,
            "inStock": true
          }
        }
      },
      {
        "id": "allam_velluli_pickle",
        "productId": "allam_velluli_pickle",
        "name": "Allam Velluli Pickle",
        "category": "Pickles",
        "image": "assets/images/pickle_allam_velluli.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 199,
            "mrp": 229,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 378,
            "mrp": 435,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 716,
            "mrp": 824,
            "inStock": true
          }
        }
      },
      {
        "id": "usiri_pickle",
        "productId": "usiri_pickle",
        "name": "Usiri Pickle",
        "category": "Pickles",
        "image": "assets/images/pickle_usirikaya.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 179,
            "mrp": 206,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 340,
            "mrp": 391,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 644,
            "mrp": 742,
            "inStock": true
          }
        }
      },
      {
        "id": "uppava",
        "productId": "uppava",
        "name": "Uppava",
        "category": "Pickles",
        "image": "assets/images/cb_uppava.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 159,
            "mrp": 183,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 302,
            "mrp": 348,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 572,
            "mrp": 659,
            "inStock": true
          }
        }
      },
      {
        "id": "special_idli_karam_podi",
        "productId": "special_idli_karam_podi",
        "name": "Special Idli Karam Podi",
        "category": "Podis",
        "image": "assets/images/loved_idli_karam_podi.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 139,
            "mrp": 160,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 264,
            "mrp": 304,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 500,
            "mrp": 576,
            "inStock": true
          }
        }
      },
      {
        "id": "allam_velluli_karam_podi",
        "productId": "allam_velluli_karam_podi",
        "name": "Allam Velluli Karam Podi",
        "category": "Podis",
        "image": "assets/images/best_allam_karam_podi.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 145,
            "mrp": 167,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 276,
            "mrp": 317,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 522,
            "mrp": 601,
            "inStock": true
          }
        }
      },
      {
        "id": "karvepaku_karam_podi",
        "productId": "karvepaku_karam_podi",
        "name": "Karvepaku Karam Podi",
        "category": "Podis",
        "image": "assets/images/best_karvepaku_podi.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 135,
            "mrp": 155,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 256,
            "mrp": 294,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 486,
            "mrp": 558,
            "inStock": true
          }
        }
      },
      {
        "id": "putnala_karam_podi",
        "productId": "putnala_karam_podi",
        "name": "Putnala Karam Podi",
        "category": "Podis",
        "image": "assets/images/fest_putnala_podi.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 129,
            "mrp": 148,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 245,
            "mrp": 281,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 464,
            "mrp": 533,
            "inStock": true
          }
        }
      },
      {
        "id": "munagaku_karam_podi",
        "productId": "munagaku_karam_podi",
        "name": "Munagaku Karam Podi",
        "category": "Podis",
        "image": "assets/images/cb_munagaku_karam_podi.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 149,
            "mrp": 171,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 283,
            "mrp": 325,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 536,
            "mrp": 616,
            "inStock": true
          }
        }
      },
      {
        "id": "special_kura_karam_podi",
        "productId": "special_kura_karam_podi",
        "name": "Special Kura Karam Podi",
        "category": "Podis",
        "image": "assets/images/cb_kura_karam_podi.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 139,
            "mrp": 160,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 264,
            "mrp": 304,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 500,
            "mrp": 576,
            "inStock": true
          }
        }
      },
      {
        "id": "menthi_podi",
        "productId": "menthi_podi",
        "name": "Menthi Podi",
        "category": "Podis",
        "image": "assets/images/cb_menthi_podi.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 129,
            "mrp": 148,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 245,
            "mrp": 281,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 464,
            "mrp": 533,
            "inStock": true
          }
        }
      },
      {
        "id": "sambhar_masala_powder",
        "productId": "sambhar_masala_powder",
        "name": "Sambhar Masala Powder",
        "category": "Podis",
        "image": "assets/images/cb_sambhar_masala.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 139,
            "mrp": 160,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 264,
            "mrp": 304,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 500,
            "mrp": 576,
            "inStock": true
          }
        }
      },
      {
        "id": "garam_masala_powder",
        "productId": "garam_masala_powder",
        "name": "Garam Masala Powder",
        "category": "Podis",
        "image": "assets/images/cb_garam_masala.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 159,
            "mrp": 183,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 302,
            "mrp": 348,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 572,
            "mrp": 659,
            "inStock": true
          }
        }
      },
      {
        "id": "chicken_masala_powder",
        "productId": "chicken_masala_powder",
        "name": "Chicken Masala Powder",
        "category": "Podis",
        "image": "assets/images/cb_chicken_masala.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 149,
            "mrp": 171,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 283,
            "mrp": 325,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 536,
            "mrp": 616,
            "inStock": true
          }
        }
      },
      {
        "id": "mutton_masala_powder",
        "productId": "mutton_masala_powder",
        "name": "Mutton Masala Powder",
        "category": "Podis",
        "image": "assets/images/cb_mutton_masala.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 159,
            "mrp": 183,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 302,
            "mrp": 348,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 572,
            "mrp": 659,
            "inStock": true
          }
        }
      },
      {
        "id": "daniya_powder",
        "productId": "daniya_powder",
        "name": "Daniya Powder",
        "category": "Podis",
        "image": "assets/images/cb_daniya_powder.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 99,
            "mrp": 114,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 188,
            "mrp": 217,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 356,
            "mrp": 410,
            "inStock": true
          }
        }
      },
      {
        "id": "haldi_powder",
        "productId": "haldi_powder",
        "name": "Haldi Powder",
        "category": "Podis",
        "image": "assets/images/cb_haldi_powder.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 99,
            "mrp": 114,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 188,
            "mrp": 217,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 356,
            "mrp": 410,
            "inStock": true
          }
        }
      },
      {
        "id": "chakinalu",
        "productId": "chakinalu",
        "name": "Chakinalu",
        "category": "Snacks",
        "image": "assets/images/best_chakinalu.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 139,
            "mrp": 160,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 264,
            "mrp": 304,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 500,
            "mrp": 576,
            "inStock": true
          }
        }
      },
      {
        "id": "khara_mixture",
        "productId": "khara_mixture",
        "name": "Khara Mixture",
        "category": "Snacks",
        "image": "assets/images/best_khara_mixture.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 149,
            "mrp": 171,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 283,
            "mrp": 325,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 536,
            "mrp": 616,
            "inStock": true
          }
        }
      },
      {
        "id": "karam_janthukalu",
        "productId": "karam_janthukalu",
        "name": "Karam Janthukalu",
        "category": "Snacks",
        "image": "assets/images/cb_karam_janthukalu.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 129,
            "mrp": 148,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 245,
            "mrp": 281,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 464,
            "mrp": 533,
            "inStock": true
          }
        }
      },
      {
        "id": "allu_chips",
        "productId": "allu_chips",
        "name": "Allu Chips",
        "category": "Snacks",
        "image": "assets/images/cb_allu_chips.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 119,
            "mrp": 137,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 226,
            "mrp": 260,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 428,
            "mrp": 493,
            "inStock": true
          }
        }
      },
      {
        "id": "bundhi",
        "productId": "bundhi",
        "name": "Bundhi",
        "category": "Snacks",
        "image": "assets/images/cb_bundhi.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 119,
            "mrp": 137,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 226,
            "mrp": 260,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 428,
            "mrp": 493,
            "inStock": true
          }
        }
      },
      {
        "id": "nuvvula_papad",
        "productId": "nuvvula_papad",
        "name": "Nuvvula Papad",
        "category": "Snacks",
        "image": "assets/images/cb_nuvvula_papad.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 109,
            "mrp": 125,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 207,
            "mrp": 238,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 392,
            "mrp": 450,
            "inStock": true
          }
        }
      },
      {
        "id": "onion_whills",
        "productId": "onion_whills",
        "name": "Onion Whills",
        "category": "Snacks",
        "image": "assets/images/cb_onion_whills.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 119,
            "mrp": 137,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 226,
            "mrp": 260,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 428,
            "mrp": 493,
            "inStock": true
          }
        }
      },
      {
        "id": "rice_papad",
        "productId": "rice_papad",
        "name": "Rice Papad",
        "category": "Snacks",
        "image": "assets/images/cb_rice_papad.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 99,
            "mrp": 114,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 188,
            "mrp": 217,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 356,
            "mrp": 410,
            "inStock": true
          }
        }
      },
      {
        "id": "tomato_chilli_papad",
        "productId": "tomato_chilli_papad",
        "name": "Tomato Chilli Papad",
        "category": "Snacks",
        "image": "assets/images/cb_tomato_chilli_papad.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 109,
            "mrp": 125,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 207,
            "mrp": 238,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 392,
            "mrp": 450,
            "inStock": true
          }
        }
      },
      {
        "id": "sunnunda_laddu",
        "productId": "sunnunda_laddu",
        "name": "Sunnunda Laddu",
        "category": "Sweets",
        "image": "assets/images/loved_sunnunda_laddu.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 199,
            "mrp": 229,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 378,
            "mrp": 435,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 716,
            "mrp": 824,
            "inStock": true
          }
        }
      },
      {
        "id": "dry_fruits_laddu",
        "productId": "dry_fruits_laddu",
        "name": "Dry Fruits Laddu",
        "category": "Sweets",
        "image": "assets/images/best_dry_fruits_laddu.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 299,
            "mrp": 344,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 568,
            "mrp": 654,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 1076,
            "mrp": 1238,
            "inStock": true
          }
        }
      },
      {
        "id": "gondh_laddu",
        "productId": "gondh_laddu",
        "name": "Gondh Laddu",
        "category": "Sweets",
        "image": "assets/images/sweet_gondh_laddu.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 249,
            "mrp": 286,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 473,
            "mrp": 543,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 896,
            "mrp": 1030,
            "inStock": true
          }
        }
      },
      {
        "id": "kova_gulab_jamun",
        "productId": "kova_gulab_jamun",
        "name": "Kova Gulab Jamun",
        "category": "Sweets",
        "image": "assets/images/sweet_gulab_jamun.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 229,
            "mrp": 263,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 435,
            "mrp": 500,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 824,
            "mrp": 947,
            "inStock": true
          }
        }
      },
      {
        "id": "millets_laddu",
        "productId": "millets_laddu",
        "name": "Millets Laddu",
        "category": "Sweets",
        "image": "assets/images/cb_millets_laddu.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 219,
            "mrp": 252,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 416,
            "mrp": 479,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 788,
            "mrp": 907,
            "inStock": true
          }
        }
      },
      {
        "id": "palli_patti",
        "productId": "palli_patti",
        "name": "Palli Patti",
        "category": "Sweets",
        "image": "assets/images/cb_palli_patti.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 149,
            "mrp": 171,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 283,
            "mrp": 325,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 536,
            "mrp": 616,
            "inStock": true
          }
        }
      },
      {
        "id": "sweet_chekki",
        "productId": "sweet_chekki",
        "name": "Sweet Chekki",
        "category": "Sweets",
        "image": "assets/images/cb_sweet_chekki.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 149,
            "mrp": 171,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 283,
            "mrp": 325,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 536,
            "mrp": 616,
            "inStock": true
          }
        }
      },
      {
        "id": "thill_patti",
        "productId": "thill_patti",
        "name": "Thill Patti",
        "category": "Sweets",
        "image": "assets/images/cb_thill_patti.png",
        "enabled": true,
        "prices": {
          "250g": {
            "variantId": "250g",
            "price": 149,
            "mrp": 171,
            "inStock": true
          },
          "500g": {
            "variantId": "500g",
            "price": 283,
            "mrp": 325,
            "inStock": true
          },
          "1kg": {
            "variantId": "1kg",
            "price": 536,
            "mrp": 616,
            "inStock": true
          }
        }
      }
    ]
  };

Future<ComboData?> fetchCombo(String apiBase, Map<String, String>? headers) async {
  // What the admin "Combo Box" tab saved (version 2) wins; older data is ignored.
  try {
    final Map<String, dynamic> d = await ApiService.getAppConfig('combo_box');
    if ('${d['version'] ?? ''}' == '2') {
      final ComboData? c = _parseCombo(d, apiBase);
      if (c != null) return c;
    }
  } catch (_) {}
  return _parseCombo(_comboFallback, apiBase);
}

Widget comboImage(String url, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
  final Widget err = SizedBox(width: width, height: height);
  if (url.isEmpty) return err;
  if (url.startsWith('assets/')) {
    return Image.asset(url, width: width, height: height, fit: fit, errorBuilder: (BuildContext c, Object e, StackTrace? s) => err);
  }
  return Image.network(url, width: width, height: height, fit: fit, gaplessPlayback: true, errorBuilder: (BuildContext c, Object e, StackTrace? s) => err);
}

double lerpD(double a, double b, double t) => a + (b - a) * t;

final Map<String, double> _aspectCache = <String, double>{};
Future<double> imageAspect(String url) async {
  if (url.isEmpty) return 1.3;
  final double? c = _aspectCache[url];
  if (c != null) return c;
  final ImageProvider<Object> prov = url.startsWith('assets/') ? AssetImage(url) as ImageProvider<Object> : NetworkImage(url) as ImageProvider<Object>;
  final ImageStream stream = prov.resolve(ImageConfiguration.empty);
  double a = 1.3;
  final Completer<void> done = Completer<void>();
  late ImageStreamListener l;
  l = ImageStreamListener((ImageInfo info, bool sync) {
    a = info.image.width / math.max(1, info.image.height);
    if (!done.isCompleted) done.complete();
  }, onError: (Object e, StackTrace? st) {
    if (!done.isCompleted) done.complete();
  });
  stream.addListener(l);
  try {
    await done.future.timeout(const Duration(seconds: 10));
  } catch (_) {}
  stream.removeListener(l);
  _aspectCache[url] = a;
  return a;
}

double easeInOut(double t) => t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2).toDouble() / 2;
double backOut(double t) {
  const double c1 = 1.4, c3 = 2.4;
  return 1 + c3 * math.pow(t - 1, 3).toDouble() + c1 * math.pow(t - 1, 2).toDouble();
}

class BoxGeo {
  static const double w = 390, h = 250;
  static const double by = 84, fy = 190, bh = 54, bx0 = 104, bx1 = 322, fx0 = 34, fx1 = 300, sd = 0.78;
  static const double ib0 = bx0 + 9, ib1 = bx1 - 8, iby = by + 6, if0 = fx0 + 10, if1 = fx1 - 8, ify = fy - 4;
  static const double lb0 = bx0 + 16, lb1 = bx1 - 12, lby = by + 34, lf0 = if0 + 4, lf1 = if1 - 2, lfy = ify;
  static double tOf(double y) => (y - lby) / (lfy - lby);
  static double xa(double y, bool left) => left ? lerpD(lb0, lf0, tOf(y)) : lerpD(lb1, lf1, tOf(y));
  static double get my => lerpD(lby, lfy, 0.48);
  static double cx(double t) => lerpD((lb0 + lb1) / 2, (lf0 + lf1) / 2, t);

  static List<Offset> comp(int k) {
    final int r = k >> 1, c = k & 1;
    final double y0 = r == 1 ? my : lby, y1 = r == 1 ? lfy : my;
    final Offset tl = c == 1 ? Offset(cx(tOf(y0)), y0) : Offset(xa(y0, true), y0);
    final Offset tr = c == 1 ? Offset(xa(y0, false), y0) : Offset(cx(tOf(y0)), y0);
    final Offset br = c == 1 ? Offset(xa(y1, false), y1) : Offset(cx(tOf(y1)), y1);
    final Offset bl = c == 1 ? Offset(cx(tOf(y1)), y1) : Offset(xa(y1, true), y1);
    return <Offset>[tl, tr, br, bl];
  }

  static Rect jarRect(int k, double aspect) {
    final List<Offset> c = comp(k);
    final double x0 = math.min(c[0].dx, c[3].dx), x1 = math.max(c[1].dx, c[2].dx), y0 = c[0].dy, y1 = c[2].dy;
    final double hh = k < 2 ? 48.0 : 52.0;
    double ww = hh * aspect;
    final double maxW = (x1 - x0) * 0.74;
    double hgt = hh;
    if (ww > maxW) {
      ww = maxW;
      hgt = ww / aspect;
    }
    final double bottom = y1 - (y1 - y0) * (k < 2 ? 0.08 : 0.12);
    final double cxm = (x0 + x1) / 2;
    return Rect.fromLTWH(cxm - ww / 2, bottom - hgt, ww, hgt);
  }

  static Offset slotCenter(int k) {
    final List<Offset> c = comp(k);
    return Offset((c[0].dx + c[1].dx + c[2].dx + c[3].dx) / 4, (c[0].dy + c[2].dy) / 2);
  }
}

class BoxState {
  double th;
  bool tied;
  double bow;
  int next;
  String label;
  String lidText;
  BoxState({this.th = 1.0, this.tied = false, this.bow = 0.0, this.next = -1, this.label = "AMMA'S COMBO", this.lidText = 'Made with love, packed by Amma'});
}

enum BoxLayer { back, front, lid }

Path _poly(List<Offset> p) {
  final Path path = Path()..moveTo(p[0].dx, p[0].dy);
  for (int i = 1; i < p.length; i++) {
    path.lineTo(p[i].dx, p[i].dy);
  }
  return path..close();
}

void _flute(Canvas c, Offset a, Offset b, double hgt) {
  final Path base = _poly(<Offset>[a, b, b + Offset(0, hgt), a + Offset(0, hgt)]);
  c.drawPath(base, Paint()..color = const Color(0xFFC9965A));
  final double len = (b - a).distance;
  final Offset dir = (b - a) / len;
  final Path wave = Path();
  const double step = 3.5;
  wave.moveTo(a.dx, a.dy + hgt * 0.75);
  for (double d = 0; d < len; d += step) {
    final Offset p = a + dir * d;
    final Offset q = a + dir * math.min(len, d + step);
    final double up = ((d / step).floor() % 2 == 0) ? 0.1 : 0.75;
    wave.quadraticBezierTo((p.dx + q.dx) / 2, p.dy + hgt * up - (up < 0.5 ? 0.5 : -0.5), q.dx, q.dy + hgt * 0.75);
  }
  c.drawPath(wave, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = const Color(0xFF9C6A35));
}

void _text(Canvas c, String t, Offset center, TextStyle st, {double scaleY = 1.0}) {
  final TextPainter tp = TextPainter(text: TextSpan(text: t, style: st), textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout();
  c.save();
  c.translate(center.dx, center.dy);
  c.scale(1.0, scaleY);
  tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
  c.restore();
}

void paintBow(Canvas c, Offset at, double k) {
  if (k <= 0) return;
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(k, k);
  c.translate(-46, -44);
  final Paint a = Paint()..color = const Color(0xFFD7264A);
  final Paint b = Paint()..color = const Color(0xFFA3122F);
  c.drawPath(Path()
    ..moveTo(46, 40)
    ..cubicTo(30, 18, 6, 6, 4, 22)
    ..cubicTo(2, 38, 24, 44, 46, 40), a);
  c.drawPath(Path()
    ..moveTo(46, 40)
    ..cubicTo(62, 18, 86, 6, 88, 22)
    ..cubicTo(90, 38, 68, 44, 46, 40), a);
  c.drawPath(Path()
    ..moveTo(46, 40)
    ..cubicTo(34, 26, 16, 18, 14, 24)
    ..cubicTo(12, 30, 28, 38, 46, 40), b);
  c.drawPath(Path()
    ..moveTo(46, 40)
    ..cubicTo(58, 26, 76, 18, 78, 24)
    ..cubicTo(80, 30, 64, 38, 46, 40), b);
  c.drawPath(_poly(const <Offset>[Offset(40, 40), Offset(30, 56), Offset(38, 56), Offset(46, 44), Offset(54, 56), Offset(62, 56), Offset(52, 40)]),
      Paint()..color = const Color(0xFFB81A3A));
  c.drawCircle(const Offset(46, 38), 7, Paint()..color = const Color(0xFFE8395A));
  c.restore();
}

class KraftBoxPainter extends CustomPainter {
  final BoxLayer layer;
  final BoxState s;
  KraftBoxPainter(this.layer, this.s);

  static const Color _ribbon = Color(0xFFC21E3E);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / BoxGeo.w, size.height / BoxGeo.h);
    if (layer == BoxLayer.back) {
      _back(canvas);
      if (s.th > 0.62) _lid(canvas, false);
    } else if (layer == BoxLayer.front) {
      _front(canvas);
    } else {
      if (s.th <= 0.62) _lid(canvas, true);
    }
    canvas.restore();
  }

  void _back(Canvas c) {
    final Rect sh = Rect.fromCenter(center: const Offset((BoxGeo.fx0 + BoxGeo.bx1) / 2 + 10, BoxGeo.fy + BoxGeo.bh + 2), width: 400, height: 44);
    c.drawOval(sh, Paint()..shader = const RadialGradient(colors: <Color>[Color(0x73460A14), Color(0x00460A14)]).createShader(sh));
    c.drawPath(_poly(const <Offset>[Offset(BoxGeo.bx0, BoxGeo.by), Offset(BoxGeo.bx1, BoxGeo.by), Offset(BoxGeo.fx1, BoxGeo.fy), Offset(BoxGeo.fx0, BoxGeo.fy)]),
        Paint()..color = const Color(0xFFE8BE84));
    c.drawPath(_poly(const <Offset>[Offset(BoxGeo.ib0, BoxGeo.iby), Offset(BoxGeo.ib1, BoxGeo.iby), Offset(BoxGeo.lb1, BoxGeo.lby), Offset(BoxGeo.lb0, BoxGeo.lby)]),
        Paint()..color = const Color(0xFF7E5026));
    c.drawPath(_poly(const <Offset>[Offset(BoxGeo.ib0, BoxGeo.iby), Offset(BoxGeo.lb0, BoxGeo.lby), Offset(BoxGeo.lf0, BoxGeo.lfy), Offset(BoxGeo.if0, BoxGeo.ify)]),
        Paint()..color = const Color(0xFFB98247));
    c.drawPath(_poly(const <Offset>[Offset(BoxGeo.ib1, BoxGeo.iby), Offset(BoxGeo.if1, BoxGeo.ify), Offset(BoxGeo.lf1, BoxGeo.lfy), Offset(BoxGeo.lb1, BoxGeo.lby)]),
        Paint()..color = const Color(0xFF9A6A31));
    final Path floor = _poly(const <Offset>[Offset(BoxGeo.lb0, BoxGeo.lby), Offset(BoxGeo.lb1, BoxGeo.lby), Offset(BoxGeo.lf1, BoxGeo.lfy), Offset(BoxGeo.lf0, BoxGeo.lfy)]);
    final Rect fb = floor.getBounds();
    c.drawPath(floor, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFF4E8F3A), Color(0xFF3A7A2C), Color(0xFF2C6322)]).createShader(fb));
    c.save();
    c.clipPath(floor);
    final Paint vein = Paint()
      ..color = const Color(0x29D2F0B4)
      ..strokeWidth = 0.8;
    for (double x = fb.left - 120; x < fb.right + 40; x += 11) {
      c.drawLine(Offset(x, fb.bottom), Offset(x + 70, fb.top), vein);
    }
    c.restore();
    c.drawPath(_poly(const <Offset>[Offset(BoxGeo.lb0, BoxGeo.lby), Offset(BoxGeo.lb1, BoxGeo.lby), Offset(BoxGeo.lb1 - 6, BoxGeo.lby + 10), Offset(BoxGeo.lb0 + 6, BoxGeo.lby + 10)]),
        Paint()..color = const Color(0x38000000));
    c.drawPath(_poly(const <Offset>[Offset(BoxGeo.lb1, BoxGeo.lby), Offset(BoxGeo.lf1, BoxGeo.lfy), Offset(BoxGeo.lf1 - 12, BoxGeo.lfy), Offset(BoxGeo.lb1 - 6, BoxGeo.lby)]),
        Paint()..color = const Color(0x29000000));
    final Paint dv = Paint()
      ..color = const Color(0xFFC99558)
      ..strokeWidth = 5;
    final Paint hl = Paint()
      ..color = const Color(0x66FFF0D2)
      ..strokeWidth = 1.2;
    c.drawLine(Offset(BoxGeo.cx(0), BoxGeo.lby), Offset(BoxGeo.cx(1), BoxGeo.lfy), dv);
    c.drawLine(Offset(BoxGeo.cx(0) + 2, BoxGeo.lby), Offset(BoxGeo.cx(1) + 2, BoxGeo.lfy), hl);
    final double my = BoxGeo.my;
    c.drawLine(Offset(BoxGeo.xa(my, true), my), Offset(BoxGeo.xa(my, false), my), dv);
    c.drawLine(Offset(BoxGeo.xa(my, true), my - 2), Offset(BoxGeo.xa(my, false), my - 2), hl);
    if (s.next >= 0 && s.th > 0.9) {
      final Path p = _poly(BoxGeo.comp(s.next));
      c.drawPath(p, Paint()..color = const Color(0x2EFFE45C));
      c.drawPath(p, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFFFE45C));
    }
    _flute(c, const Offset(BoxGeo.bx0, BoxGeo.by), const Offset(BoxGeo.bx1, BoxGeo.by), 3);
  }

  void _front(Canvas c) {
    const Offset fl = Offset(BoxGeo.fx0, BoxGeo.fy), fr = Offset(BoxGeo.fx1, BoxGeo.fy);
    const Offset br = Offset(BoxGeo.bx1, BoxGeo.by);
    const Offset brB = Offset(BoxGeo.bx1, BoxGeo.by + BoxGeo.bh * BoxGeo.sd);
    const Offset frB = Offset(BoxGeo.fx1, BoxGeo.fy + BoxGeo.bh), flB = Offset(BoxGeo.fx0, BoxGeo.fy + BoxGeo.bh);
    final Path side = _poly(<Offset>[fr, br, brB, frB]);
    c.drawPath(side, Paint()..color = const Color(0xFFA86E35));
    _corrugate(c, side, 0.12);
    _flute(c, fr, br, 3);
    c.drawPath(_poly(<Offset>[frB, brB, brB + const Offset(0, 2), frB + const Offset(0, 2)]), Paint()..color = const Color(0x66321908));
    final Path front = _poly(<Offset>[fl, fr, frB, flB]);
    final Rect r = front.getBounds();
    c.drawPath(front, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xFFDCA868), Color(0xFFAD7437)]).createShader(r));
    _corrugate(c, front, 0.07);
    c.drawPath(front, Paint()
      ..shader = const LinearGradient(colors: <Color>[Color(0x383C1E08), Color(0x003C1E08), Color(0x003C1E08), Color(0x383C1E08)], stops: <double>[0.0, 0.18, 0.82, 1.0]).createShader(r));
    c.drawRect(Rect.fromLTWH(BoxGeo.fx1 - 14, BoxGeo.fy, 14, BoxGeo.bh), Paint()..color = const Color(0x2E3C1E08));
    _flute(c, fl, fr, 5);
    c.drawRect(Rect.fromLTWH(BoxGeo.fx0, BoxGeo.fy + BoxGeo.bh - 2, BoxGeo.fx1 - BoxGeo.fx0, 2), Paint()..color = const Color(0x59461E0A));
    final bool tiedShut = s.tied && s.th < 0.05;
    final double tx = tiedShut ? 110 : (BoxGeo.fx0 + BoxGeo.fx1) / 2;
    if (tiedShut) {
      c.drawRect(Rect.fromLTWH((BoxGeo.fx0 + BoxGeo.fx1) / 2 - 8, BoxGeo.fy, 16, BoxGeo.bh), Paint()..color = _ribbon);
      c.drawPath(
          _poly(<Offset>[
            const Offset(BoxGeo.fx1, BoxGeo.fy + BoxGeo.bh * 0.42),
            const Offset(BoxGeo.bx1, BoxGeo.by + BoxGeo.bh * BoxGeo.sd * 0.42),
            const Offset(BoxGeo.bx1, BoxGeo.by + BoxGeo.bh * BoxGeo.sd * 0.42 + 12),
            const Offset(BoxGeo.fx1, BoxGeo.fy + BoxGeo.bh * 0.42 + 14)
          ]),
          Paint()..color = const Color(0xFFB81A3A));
    }
    _text(c, 'AMBHUJAKSHI', Offset(tx, BoxGeo.fy + 22), GoogleFonts.playfairDisplay(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: const Color(0xC75A2A10)));
    _text(c, s.label.toUpperCase(), Offset(tx, BoxGeo.fy + 36), GoogleFonts.poppins(fontSize: 7.5, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: const Color(0xC76A3414)));
    const Offset st = Offset(BoxGeo.fx1 - 32, BoxGeo.fy + 26);
    c.drawCircle(st, 11, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = const Color(0x997A1426));
    _text(c, 'HAND', st + const Offset(0, -1), GoogleFonts.poppins(fontSize: 6, fontWeight: FontWeight.w700, color: const Color(0x997A1426)));
    _text(c, 'PACKED', st + const Offset(0, 6), GoogleFonts.poppins(fontSize: 4.4, fontWeight: FontWeight.w700, color: const Color(0x997A1426)));
  }

  void _corrugate(Canvas c, Path area, double alpha) {
    final Rect r = area.getBounds();
    c.save();
    c.clipPath(area);
    final Paint p = Paint()
      ..color = Color.fromRGBO(90, 50, 15, alpha)
      ..strokeWidth = 1;
    for (double x = r.left; x < r.right; x += 5) {
      c.drawLine(Offset(x, r.top), Offset(x, r.bottom), p);
    }
    c.restore();
  }

  void _lid(Canvas c, bool frontLayer) {
    final double a = s.th * math.pi / 2 * 1.04, co = math.cos(a), si = math.sin(a);
    const double e = 6, t = 9;
    const Offset bl = Offset(BoxGeo.bx0 - e, BoxGeo.by - 4), br = Offset(BoxGeo.bx1 + e, BoxGeo.by - 4);
    final Offset dl = Offset(BoxGeo.fx0 - e - bl.dx, BoxGeo.fy + 2 - bl.dy), dr = Offset(BoxGeo.fx1 + e - br.dx, BoxGeo.fy + 2 - br.dy);
    Offset up(Offset d) => Offset(d.dx * co * (1 - 0.05 * si), d.dy * co - (BoxGeo.fy - BoxGeo.by) * 0.86 * si);
    final Offset fl = bl + up(dl), fr = br + up(dr);
    final bool ins = fl.dy < bl.dy - 2;
    final Path top = _poly(<Offset>[bl, br, fr, fl]);
    final Rect tb = top.getBounds();
    if (!ins) {
      c.drawPath(_poly(<Offset>[fr, br, br + Offset(0, t * co), fr + const Offset(0, t)]), Paint()..color = const Color(0xFFA2692F));
      c.drawPath(_poly(<Offset>[fl, fr, fr + const Offset(0, t), fl + const Offset(0, t)]), Paint()..color = const Color(0xFFBE8546));
      _flute(c, fl, fr, 2);
    } else {
      c.drawPath(_poly(<Offset>[bl, br, br + const Offset(0, t), bl + const Offset(0, t)]), Paint()..color = const Color(0xFFA2692F));
    }
    c.drawPath(
        top,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: ins ? const <Color>[Color(0xFFEDCB98), Color(0xFFD3A469)] : const <Color>[Color(0xFFEAC28A), Color(0xFFC79053)])
              .createShader(tb));
    c.drawPath(top, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x59784620));
    final Offset mid = Offset((bl.dx + br.dx + fl.dx + fr.dx) / 4, (bl.dy + fl.dy) / 2);
    if (ins) {
      final double op = math.min(1.0, (bl.dy - fl.dy) / 50) * 0.85;
      _text(c, s.lidText, mid, GoogleFonts.playfairDisplay(fontSize: 13, fontStyle: FontStyle.italic, color: const Color(0xFF7A1426).withOpacity(op)));
      return;
    }
    c.drawPath(top, Paint()
      ..shader = const LinearGradient(colors: <Color>[Color(0x383C1E08), Color(0x003C1E08), Color(0x003C1E08), Color(0x383C1E08)], stops: <double>[0.0, 0.18, 0.82, 1.0]).createShader(tb));
    if (s.tied) {
      final Offset tbk = Offset((bl.dx + br.dx) / 2, bl.dy), tf = Offset((fl.dx + fr.dx) / 2, fl.dy);
      c.drawPath(_poly(<Offset>[tbk - const Offset(8, 0), tbk + const Offset(8, 0), tf + const Offset(8, 0), tf - const Offset(8, 0)]), Paint()..color = _ribbon);
      c.drawRect(Rect.fromLTWH(tf.dx - 8, tf.dy, 16, t), Paint()..color = const Color(0xFFB81A3A));
      final Offset ml = Offset((bl.dx + fl.dx) / 2, (bl.dy + fl.dy) / 2), mr = Offset((br.dx + fr.dx) / 2, (br.dy + fr.dy) / 2);
      c.drawPath(_poly(<Offset>[ml - Offset(0, 7 * co), mr - Offset(0, 7 * co), mr + Offset(0, 7 * co), ml + Offset(0, 7 * co)]), Paint()..color = const Color(0xFFD02646));
    } else if (co > 0.5) {
      c.save();
      c.translate(mid.dx, mid.dy);
      c.scale(1.0, co);
      final Paint st = Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xBF7A1426);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 108, height: 40), st..strokeWidth = 1.4);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 98, height: 32), st..strokeWidth = 0.7);
      _text(c, 'AMBHUJAKSHI', const Offset(0, -4), GoogleFonts.playfairDisplay(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xBF7A1426)));
      _text(c, 'made with love', const Offset(0, 8), GoogleFonts.playfairDisplay(fontSize: 8, fontStyle: FontStyle.italic, color: const Color(0xBF7A1426)));
      c.restore();
    }
    paintBow(c, mid, s.bow);
  }

  @override
  bool shouldRepaint(covariant KraftBoxPainter o) => true;
}

class KraftBox extends StatelessWidget {
  final BoxState state;
  final List<String> jars;
  final List<double> aspects;
  final List<double> land;
  final bool hideJars;
  final List<Widget>? overlays;
  const KraftBox({super.key, required this.state, required this.jars, required this.aspects, required this.land, this.hideJars = false, this.overlays});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: BoxGeo.w,
        height: BoxGeo.h,
        child: Stack(clipBehavior: Clip.none, children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: KraftBoxPainter(BoxLayer.back, state))),
          for (int k = 0; k < jars.length && k < 4; k++)
            if (jars[k].isNotEmpty && !hideJars) _jar(k),
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: KraftBoxPainter(BoxLayer.front, state)))),
          ...?overlays,
          Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: KraftBoxPainter(BoxLayer.lid, state)))),
        ]),
      ),
    );
  }

  Widget _jar(int k) {
    final Rect r = BoxGeo.jarRect(k, aspects.length > k && aspects[k] > 0 ? aspects[k] : 1.3);
    final double t = land.length > k ? land[k] : 1.0;
    final double drop = t >= 1 ? 0.0 : -26.0 * (1 - backOut(t));
    final double sc = t >= 1 ? 1.0 : 1.08 - 0.08 * t;
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: Transform.translate(
        offset: Offset(0, drop),
        child: Transform.scale(
          scale: sc,
          alignment: Alignment.bottomCenter,
          child: Stack(clipBehavior: Clip.none, children: <Widget>[
            Positioned(
              left: r.width * 0.12,
              right: r.width * 0.12,
              bottom: -2,
              height: 8,
              child: DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.elliptical(r.width, 8)), color: const Color(0x52200A00))),
            ),
            comboImage(jars[k], width: r.width, height: r.height),
          ]),
        ),
      ),
    );
  }
}

class ComboConfetti extends CustomPainter {
  final double t;
  final List<List<double>> parts;
  final List<Color> colors;
  ComboConfetti(this.t, this.parts, this.colors);
  static List<List<double>> make(int n, int seed) {
    final math.Random r = math.Random(seed);
    return List<List<double>>.generate(n, (int k) {
      final double a = r.nextDouble() * math.pi * 2, d = 80 + r.nextDouble() * 130;
      return <double>[math.cos(a) * d, math.sin(a) * d - 40, r.nextDouble() * 12, (k % 5).toDouble()];
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final double e = const Cubic(0.1, 0.7, 0.3, 1.0).transform(t);
    for (final List<double> p in parts) {
      canvas.save();
      canvas.translate(p[0] * e, p[1] * e);
      canvas.rotate(p[2] * e);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -5, 7, 10), const Radius.circular(2)),
          Paint()..color = colors[p[3].toInt() % colors.length].withOpacity(1 - t));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ComboConfetti o) => o.t != t;
}
