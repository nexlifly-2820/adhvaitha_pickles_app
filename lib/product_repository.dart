import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

class ProductRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final List<Review> _mockReviews = [
    Review(userName: 'Srinivas R.', comment: 'Authentic Andhra taste! Reminds me of home.', rating: 5.0, date: '2 days ago'),
    Review(userName: 'Lakshmi K.', comment: 'High quality spices. Very aromatic.', rating: 5.0, date: '5 days ago'),
    Review(userName: 'Rahul M.', comment: 'Perfect snacks for tea time. Very fresh.', rating: 4.5, date: '1 week ago'),
  ];

  // Unique Secret Ingredients
  static final _secretMango = IngredientDetail(
    name: 'Sun-Dried King Mangoes',
    description: 'We use only the "King of Mangoes" from Guntur, hand-cut and dried under the peak coastal sun for 48 hours to lock in the intense natural tartness.',
    image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
  );

  static final _secretGarlic = IngredientDetail(
    name: 'Desi Small Garlic',
    description: 'Unlike industrial garlic, we source small-clove Desi garlic which is hand-peeled. It has 3x the pungency and therapeutic properties of standard varieties.',
    image: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
  );

  static final _secretOil = IngredientDetail(
    name: 'Cold-Pressed Peanut Oil',
    description: 'We never use refined oils. Our pickles are preserved in wood-pressed (Kacchi Ghani) peanut oil, which adds a nutty depth and remains healthy for months.',
    image: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
  );

  static final _secretSpices = IngredientDetail(
    name: 'Stone-Ground Guntur Chillies',
    description: 'Our red chilli powder is not bought from markets. We sun-dry Guntur Sannam chillies and stone-grind them in our own kitchen for that vibrant red color.',
    image: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg',
  );

  static final _secretGhee = IngredientDetail(
    name: 'Pure Desi Cow Ghee',
    description: 'The secret to our melt-in-the-mouth sweets is pure, hand-churned Desi Cow Ghee, prepared using the traditional Bilona method for peak aroma.',
    image: 'assets/images/gondh_laddu_edible_gum_laddu.jpg',
  );

  static final List<Product> allProducts = [
    // PICKLES
    Product(
      name: 'Bellam Avakaya', 
      description: 'The King of Pickles. A sweet and tangy masterpiece made with premium mango chunks, high-quality jaggery, and our secret spice blend.', 
      weightPriceMap: {'250g': 140, '500g': 260, '1kg': 500},
      rating: 4.9, image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', 
      color: const Color(0xFF18453B), category: 'Pickles', isBestSeller: true, reviews: _mockReviews,
      pairings: ['Chakinalu', 'Sunnunda Laddu', 'Garam Masala'],
      ingredients: ['Premium Mango', 'Pure Jaggery', 'Cold-Pressed Peanut Oil', 'Mustard Seeds', 'Fenugreek', 'Red Chilli Powder', 'Sea Salt'],
      preparationMethod: 'Mangoes are hand-cut and sun-dried for 48 hours. Spices are stone-ground to retain aroma. Mixed in small batches and aged for 15 days.',
      storageInstructions: 'Keep in an airtight glass jar. Always use a dry spoon. Ensure mango pieces are submerged in oil to prevent spoilage.',
      servingSuggestion: 'Pairs best with steaming hot rice and a dollop of ghee. Also complements breakfast items like Idli and Dosa.',
      secretIngredient: IngredientDetail(
        name: 'Organic Palm Jaggery',
        description: 'Our secret sweetness comes from organic palm jaggery sourced from local farmers in Andhra, providing a deep caramel note without being cloying.',
        image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      ),
      canRequestTempering: true,
      sommelierPairings: [
        SommelierPairing(title: 'Artisanal Sourdough', description: 'The tangy crust of a fresh sourdough complements the sweet-spicy notes of Bellam Avakaya perfectly.', icon: Icons.bakery_dining_rounded),
        SommelierPairing(title: 'Aged Cheddar Cheese', description: 'The sharpness of cheddar cuts through the jaggery sweetness, creating a unique global-fusion snack.', icon: Icons.lunch_dining_rounded),
      ],
    ),
    Product(
      name: 'Allam Velluli Pickle', 
      description: 'A spicy and aromatic ginger-garlic pickle that provides an instant flavor explosion. Perfect for those who love bold, sharp tastes.', 
      weightPriceMap: {'250g': 120, '500g': 220, '1kg': 420},
      rating: 4.9, image: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg', 
      color: const Color(0xFF18453B), category: 'Pickles', isBestSeller: true, reviews: _mockReviews,
      pairings: ['Bundhi', 'Gondh Laddu', 'Sambar Masala Powder'],
      ingredients: ['Fresh Ginger', 'Garlic Cloves', 'Tamarind', 'Cold-Pressed Oil', 'Red Chilli', 'Turmeric', 'Sea Salt'],
      preparationMethod: 'Ginger and Garlic are crushed using a traditional stone mortar. Tamarind pulp is reduced slowly to concentrate flavors. No water added.',
      servingSuggestion: 'Best enjoyed with Curd Rice, Pesarattu, or as a side for hot Parathas.',
      secretIngredient: _secretGarlic,
      canRequestTempering: true,
      sommelierPairings: [
        SommelierPairing(title: 'Grilled King Prawns', description: 'Use as a high-impact marinade or a side dip for seafood to elevate the umami of the ocean.', icon: Icons.set_meal_rounded),
        SommelierPairing(title: 'Creamy Avocado Toast', description: 'The creamy fats of avocado neutralize the ginger heat, resulting in a balanced gourmet breakfast.', icon: Icons.breakfast_dining_rounded),
      ],
    ),
    Product(
      name: 'Usiri Pickle', 
      description: 'Amla gooseberry pickle', 
      weightPriceMap: {'250g': 130, '500g': 240, '1kg': 450},
      rating: 4.9, image: 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg', 
      color: const Color(0xFF18453B), category: 'Pickles', reviews: _mockReviews,
      pairings: ['Rice Papad', 'Millets Laddu', 'Daniya Powder'],
      secretIngredient: IngredientDetail(
        name: 'Wild Forest Amla',
        description: 'We source small, vitamin-rich wild amla from forest-dwelling communities. These are much more potent and tart than farm-grown varieties.',
        image: 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg',
      ),
    ),
    Product(
      name: 'Uppava', 
      description: 'Traditional salted pickle', 
      weightPriceMap: {'250g': 100, '500g': 180, '1kg': 340},
      rating: 4.7, image: 'assets/images/uppava_traditional_salted_pickle.jpg', 
      color: const Color(0xFF18453B), category: 'Pickles', reviews: _mockReviews,
      pairings: ['Allu Chips', 'Sweet Chekki', 'Haldi Powder'],
      secretIngredient: _secretOil,
    ),

    // SNACKS
    Product(
      name: 'Chakinalu', 
      description: 'Traditional spiral snacks', 
      weightPriceMap: {'250g': 100, '500g': 180, '1kg': 350},
      rating: 4.8, image: 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Sunnunda Laddu'],
      secretIngredient: IngredientDetail(
        name: 'Aged Rice Flour',
        description: 'Our Chakinalu use flour from rice aged for 12 months, which absorbs less oil and results in that signature traditional crunch.',
        image: 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg',
      ),
    ),
    Product(
      name: 'Bundhi', 
      description: 'Crispy gram flour droplets', 
      weightPriceMap: {'250g': 45, '500g': 80, '1kg': 150},
      rating: 4.6, image: 'assets/images/bundhi_crispy_spiced_gram_flour_droplets.jpg',
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Gondh Laddu'],
      secretIngredient: _secretOil,
    ),
    Product(
      name: 'Allu Chips', 
      description: 'Indian potato chips', 
      weightPriceMap: {'250g': 55, '500g': 99, '1kg': 190},
      rating: 4.7, image: 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Uppava', 'Sweet Chekki'],
      secretIngredient: _secretOil,
    ),
    Product(
      name: 'Karam Janthukalu', 
      description: 'Murukku strings snack', 
      weightPriceMap: {'250g': 90, '500g': 160, '1kg': 300},
      rating: 4.8, image: 'assets/images/karam_janthukalu_murukku_strings_snack.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Palli Patti'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Khara Mixture', 
      description: 'Crunchy savory mix', 
      weightPriceMap: {'250g': 70, '500g': 120, '1kg': 230},
      rating: 4.7, image: 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Dry Fruits Laddu'],
      secretIngredient: _secretOil,
    ),
    Product(
      name: 'Nuvvula Papad', 
      description: 'Sesame coated papads', 
      weightPriceMap: {'250g': 80, '500g': 140, '1kg': 260},
      rating: 4.7, image: 'assets/images/nuvvula_papad_sesame_coated_crispy_papads.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Millets Laddu'],
      secretIngredient: IngredientDetail(
        name: 'Unhulled Black Sesame',
        description: 'We use unhulled black sesame seeds which have a stronger aroma and more calcium than the white variety found in stores.',
        image: 'assets/images/nuvvula_papad_sesame_coated_crispy_papads.jpg',
      ),
    ),
    Product(
      name: 'Onion Whills', 
      description: 'Onion flavored crisp wheels', 
      weightPriceMap: {'200g': 80, '400g': 150, '1kg': 350},
      rating: 4.5, image: 'assets/images/onion_whills_onion_flavored_crisp_wheels.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Kova Gulam Jamun'],
      secretIngredient: _secretOil,
    ),
    Product(
      name: 'Rice Papad', 
      description: 'Crispy rice flour papadums', 
      weightPriceMap: {'250g': 60, '500g': 100, '1kg': 190},
      rating: 4.6, image: 'assets/images/rice_papad_crispy_rice_flour_papadums.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Sunnunda Laddu'],
      secretIngredient: _secretMango,
    ),
    Product(
      name: 'Tomato Chilli Papad', 
      description: 'Tangy and spicy papads', 
      weightPriceMap: {'250g': 70, '500g': 120, '1kg': 230},
      rating: 4.6, image: 'assets/images/tomato_chilli_papad_tangy_and_spicy_papads.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Thill Patti'],
      secretIngredient: _secretSpices,
    ),

    // SPICES
    Product(
      name: 'Allam Velluli Karam Podi', 
      description: 'Ginger garlic spice powder', 
      weightPriceMap: {'250g': 149, '500g': 280, '1kg': 540},
      rating: 4.8, image: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Rice Papad'],
      secretIngredient: _secretGarlic,
    ),
    Product(
      name: 'Chicken Masala Powder', 
      description: 'Chicken curry spice blend', 
      weightPriceMap: {'100g': 120, '250g': 280, '500g': 540},
      rating: 4.7, image: 'assets/images/chicken_masala_powder_chicken_curry_spice_blend.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Chakinalu'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Daniya Powder', 
      description: 'Coriander powder', 
      weightPriceMap: {'200g': 80, '500g': 190, '1kg': 360},
      rating: 4.5, image: 'assets/images/daniya_powder_freshly_ground_coriander_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Bundhi'],
      secretIngredient: IngredientDetail(
        name: 'Whole Coriander Seeds',
        description: 'Our Daniya powder is ground from premium, bright green coriander seeds sourced from the fields of Kurnool for maximum aroma.',
        image: 'assets/images/daniya_powder_freshly_ground_coriander_powder.jpg',
      ),
    ),
    Product(
      name: 'Garam Masala', 
      description: 'Traditional warm spice blend', 
      weightPriceMap: {'100g': 150, '250g': 360, '500g': 680},
      rating: 4.8, image: 'assets/images/garam_masala_powder_traditional_warm_spice_blend.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Chakinalu'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Haldi Powder', 
      description: 'Pure turmeric powder', 
      weightPriceMap: {'250g': 90, '500g': 170, '1kg': 320},
      rating: 4.7, image: 'assets/images/haldi_powder_pure_turmeric_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Uppava', 'Rice Papad'],
      secretIngredient: IngredientDetail(
        name: 'High-Curcumin Turmeric',
        description: 'We source Salem turmeric with high curcumin levels (above 5%), providing intense color and medicinal benefits.',
        image: 'assets/images/haldi_powder_pure_turmeric_powder.jpg',
      ),
    ),
    Product(
      name: 'Karvepaku Karam Podi', 
      description: 'Curry leaves powder', 
      weightPriceMap: {'250g': 130, '500g': 240, '1kg': 460},
      rating: 4.9, image: 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Nuvvula Papad'],
      secretIngredient: IngredientDetail(
        name: 'Organic Curry Leaves',
        description: 'Only the tender, deep green leaves from our own pesticide-free trees are used to ensure the powder is fragrant and pure.',
        image: 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg',
      ),
    ),
    Product(
      name: 'Menthi Podi', 
      description: 'Fenugreek powder', 
      weightPriceMap: {'200g': 110, '500g': 260, '1kg': 500},
      rating: 4.6, image: 'assets/images/menthi_podi_fenugreek_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Tomato Chilli Papad'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Munagaku Karam Podi', 
      description: 'Moringa leaves spice powder', 
      weightPriceMap: {'250g': 160, '500g': 300, '1kg': 580},
      rating: 4.9, image: 'assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Rice Papad'],
      secretIngredient: IngredientDetail(
        name: 'Moringa Superfood',
        description: 'Sourced from drought-resistant Moringa trees, our leaves are shade-dried to preserve their intense nutritional profile and bright green hue.',
        image: 'assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg',
      ),
    ),
    Product(
      name: 'Mutton Masala Powder', 
      description: 'Mutton recipe spice blend', 
      weightPriceMap: {'100g': 160, '250g': 380, '500g': 720},
      rating: 4.8, image: 'assets/images/mutton_masala_powder_mutton_recipe_spice_blend.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Karam Janthukalu'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Putnala Karam Podi', 
      description: 'Roasted gram spice powder', 
      weightPriceMap: {'250g': 110, '500g': 200, '1kg': 380},
      rating: 4.7, image: 'assets/images/putnala_karam_podi_roasted_gram_spice_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Bundhi'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Sambhar Masala Powder', 
      description: 'Sambhar spice blend', 
      weightPriceMap: {'200g': 140, '500g': 330, '1kg': 640},
      rating: 4.8, image: 'assets/images/sambhar_masala_powder_authentic_sambhar_spice_blend.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Rice Papad'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Special Idli Karam Podi', 
      description: 'Gun powder spice for idlis', 
      weightPriceMap: {'250g': 150, '500g': 280, '1kg': 540},
      rating: 4.9, image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Chakinalu'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Special Kura Karam Podi', 
      description: 'All-purpose curry powder', 
      weightPriceMap: {'250g': 180, '500g': 340, '1kg': 650},
      rating: 4.8, image: 'assets/images/special_kura_karam_podi_all-purpose_curry_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Rice Papad'],
      secretIngredient: _secretSpices,
    ),

    // SWEETS
    Product(
      name: 'Dry Fruits Laddu', 
      description: 'Premium dry fruits laddu', 
      weightPriceMap: {'250g': 240, '500g': 450, '1kg': 880},
      rating: 5.0, image: 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Bundhi'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Gondh Laddu', 
      description: 'Edible gum laddu', 
      weightPriceMap: {'250g': 200, '500g': 380, '1kg': 740},
      rating: 5.0, image: 'assets/images/gondh_laddu_edible_gum_laddu.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', isBestSeller: true, reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Khara Mixture'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Kova Gulam Jamun', 
      description: 'Gulab jamun sweet', 
      weightPriceMap: {'250g': 150, '500g': 280, '1kg': 540},
      rating: 4.9, image: 'assets/images/kova_gulam_jamun_rich_gulab_jamun_sweet.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Onion Whills'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Millets Laddu', 
      description: 'Multi-millet laddu', 
      weightPriceMap: {'250g': 190, '500g': 350, '1kg': 680},
      rating: 4.9, image: 'assets/images/millets_laddu_wholesome_multi-millet_laddu.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Tomato Chilli Papad'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Palli Patti', 
      description: 'Peanut and jaggery chikki', 
      weightPriceMap: {'250g': 65, '500g': 120, '1kg': 230},
      rating: 4.8, image: 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Karam Janthukalu'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Sunnunda Laddu', 
      description: 'Roasted urad dal laddu', 
      weightPriceMap: {'250g': 170, '500g': 320, '1kg': 620},
      rating: 4.9, image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Chakinalu'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Sweet Chekki', 
      description: 'Traditional sweet brittle', 
      weightPriceMap: {'250g': 55, '500g': 100, '1kg': 190},
      rating: 4.7, image: 'assets/images/sweet_chekki_traditional_sweet_brittle.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Uppava', 'Allu Chips'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Thill Patti', 
      description: 'Sesame seed and jaggery sweet', 
      weightPriceMap: {'250g': 70, '500g': 130, '1kg': 250},
      rating: 4.8, image: 'assets/images/thill_patti_sesame_seed_and_jaggery_sweet.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Tomato Chilli Papad'],
      secretIngredient: _secretGhee,
    ),
  ];

  Stream<List<Product>> getProductsStream() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return allProducts;
      
      List<Product> products = [];
      for (var doc in snapshot.docs) {
        Product p = _mapToProduct(doc);
        // Fetch approved reviews for this product
        final reviewsSnap = await _firestore
            .collection('reviews')
            .where('productId', isEqualTo: p.name)
            .where('status', isEqualTo: 'approved')
            .get();
            
        final reviews = reviewsSnap.docs.map((r) => _mapToReview(r)).toList();
        products.add(p.copyWith(reviews: reviews));
      }
      return products;
    });
  }

  Review _mapToReview(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userName: data['userName'] ?? 'Anonymous',
      comment: data['comment'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      date: data['date'] ?? 'Recently',
      status: data['status'] ?? 'approved',
    );
  }

  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();
      if (snapshot.docs.isEmpty) {
        // If Firestore is empty, seed with local data for first run
        await seedProducts();
        return allProducts;
      }
      return snapshot.docs.map((doc) => _mapToProduct(doc)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return allProducts; // Fallback to local data
    }
  }

  Future<void> seedProducts() async {
    final batch = _firestore.batch();
    for (var product in allProducts) {
      final docRef = _firestore.collection('products').doc(product.name.replaceAll(' ', '_').toLowerCase());
      batch.set(docRef, _productToMap(product));
    }
    await batch.commit();
  }

  Product _mapToProduct(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // SAFE PARSING: Ensure we don't crash if data is missing or malformed
    Map<String, double> safeWeightMap = {};
    if (data['weightPriceMap'] != null && data['weightPriceMap'] is Map) {
      (data['weightPriceMap'] as Map).forEach((k, v) {
        safeWeightMap[k.toString()] = (v as num).toDouble();
      });
    } else {
      // Default fallback if map is missing
      safeWeightMap = {"250g": 180.0, "500g": 350.0};
    }

    return Product(
      name: data['name'] ?? 'Royal Pickle',
      description: data['description'] ?? '',
      weightPriceMap: safeWeightMap,
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      image: data['image'] ?? 'assets/images/logo.png',
      color: Color(int.tryParse(data['color']?.toString() ?? '0xFF18453B') ?? 0xFF18453B),
      category: data['category'] ?? 'Pickles',
      isBestSeller: data['isBestSeller'] ?? false,
      isOutOfStock: data['isOutOfStock'] ?? false,
      reviews: _mockReviews,
      pairings: List<String>.from(data['pairings'] ?? []),
      origin: data['origin'] ?? 'Coastal Andhra, India',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      preparationMethod: data['preparationMethod'] ?? '',
      shelfLife: data['shelfLife'] ?? '',
      storageInstructions: data['storageInstructions'] ?? '',
      servingSuggestion: data['servingSuggestion'] ?? '',
      canRequestTempering: data['canRequestTempering'] ?? false,
      secretIngredient: IngredientDetail(
        name: data['secretIngredient']?['name'] ?? 'Royal Spices',
        description: data['secretIngredient']?['description'] ?? 'Secret blend of heritage spices.',
        image: data['secretIngredient']?['image'] ?? 'assets/images/logo.png',
      ),
      sommelierPairings: (data['sommelierPairings'] as List? ?? []).map((p) => SommelierPairing(
        title: p['title'] ?? '',
        description: p['description'] ?? '',
        icon: _getIconData(p['icon'] ?? 'help_outline'),
      )).toList(),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'bakery_dining': return Icons.bakery_dining_rounded;
      case 'lunch_dining': return Icons.lunch_dining_rounded;
      case 'set_meal': return Icons.set_meal_rounded;
      case 'breakfast_dining': return Icons.breakfast_dining_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  Map<String, dynamic> _productToMap(Product p) {
    return {
      'name': p.name,
      'description': p.description,
      'weightPriceMap': p.weightPriceMap,
      'rating': p.rating,
      'image': p.image,
      'color': p.color.value,
      'category': p.category,
      'isBestSeller': p.isBestSeller,
      'isOutOfStock': p.isOutOfStock,
      'pairings': p.pairings,
      'origin': p.origin,
      'ingredients': p.ingredients,
      'preparationMethod': p.preparationMethod,
      'shelfLife': p.shelfLife,
      'storageInstructions': p.storageInstructions,
      'servingSuggestion': p.servingSuggestion,
      'canRequestTempering': p.canRequestTempering,
      'secretIngredient': {
        'name': p.secretIngredient.name,
        'description': p.secretIngredient.description,
        'image': p.secretIngredient.image,
      },
      'sommelierPairings': p.sommelierPairings.map((s) => {
        'title': s.title,
        'description': s.description,
        'icon': s.icon.toString(), // Simplified for seeding, dashboard should use names
      }).toList(),
    };
  }
}
