import 'package:flutter/material.dart';
import 'api_service.dart';
import 'models.dart';

class ProductRepository {

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

  static final List<Product> recentlyViewed = [];

  static void addToRecentlyViewed(Product product) {
    if (recentlyViewed.contains(product)) {
      recentlyViewed.remove(product);
    }
    recentlyViewed.insert(0, product);
    if (recentlyViewed.length > 10) recentlyViewed.removeLast();
  }

  static void refreshRecentlyViewed(List<Product> latestProducts) {
    for (int i = 0; i < recentlyViewed.length; i++) {
      try {
        final latest = latestProducts.firstWhere((p) => p.name == recentlyViewed[i].name);
        recentlyViewed[i] = latest;
      } catch (e) {
        // Product no longer exists
      }
    }
  }

  static final List<Product> allProducts = [
    // PICKLES
    Product(
      name: 'Bellam Avakaya', 
      description: 'The King of Pickles crafted from premium sun-dried mango chunks.\nPreserved in wood-pressed oils with organic jaggery and secret spices.\nDelivers an unforgettable sweet and tangy traditional Andhra taste.', 
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
      stockCount: 8,
      sommelierPairings: [
        SommelierPairing(title: 'Artisanal Sourdough', description: 'The tangy crust of a fresh sourdough complements the sweet-spicy notes of Bellam Avakaya perfectly.', icon: Icons.bakery_dining_rounded),
        SommelierPairing(title: 'Aged Cheddar Cheese', description: 'The sharpness of cheddar cuts through the jaggery sweetness, creating a unique global-fusion snack.', icon: Icons.lunch_dining_rounded),
      ],
    ),
    Product(
      name: 'Allam Velluli Pickle', 
      description: 'A spicy and aromatic ginger-garlic pickle with an instant flavor explosion.\nCrushed in traditional stone mortars with pure tamarind and cold-pressed oils.\nPerfect for adding bold, sharp, and authentic flavor to every meal.', 
      weightPriceMap: {'250g': 120, '500g': 220, '1kg': 420},
      rating: 4.9, image: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg', 
      color: const Color(0xFF18453B), category: 'Pickles', isBestSeller: true, reviews: _mockReviews,
      pairings: ['Bundhi', 'Gondh Laddu', 'Sambar Masala Powder'],
      ingredients: ['Fresh Ginger', 'Garlic Cloves', 'Tamarind', 'Cold-Pressed Oil', 'Red Chilli', 'Turmeric', 'Sea Salt'],
      preparationMethod: 'Ginger and Garlic are crushed using a traditional stone mortar. Tamarind pulp is reduced slowly to concentrate flavors. No water added.',
      servingSuggestion: 'Best enjoyed with Curd Rice, Pesarattu, or as a side for hot Parathas.',
      secretIngredient: _secretGarlic,
      canRequestTempering: true,
      stockCount: 5,
      sommelierPairings: [
        SommelierPairing(title: 'Grilled King Prawns', description: 'Use as a high-impact marinade or a side dip for seafood to elevate the umami of the ocean.', icon: Icons.set_meal_rounded),
        SommelierPairing(title: 'Creamy Avocado Toast', description: 'The creamy fats of avocado neutralize the ginger heat, resulting in a balanced gourmet breakfast.', icon: Icons.breakfast_dining_rounded),
      ],
    ),
    Product(
      name: 'Usiri Pickle', 
      description: 'A traditional Amla gooseberry pickle rich in vitamin C and antioxidants.\nSourced from wild forests and sun-dried to perfection for an authentic tangy kick.\nProvides an unforgettable traditional flavor that elevates hot rice and ghee.', 
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
      description: 'A classic traditional salted raw mango pickle aged gracefully in brine.\nCrafted using time-honored family methods for an unmatched village taste.\nBrings the nostalgic, authentic flavor of coastal Andhra kitchens to your table.', 
      weightPriceMap: {'250g': 100, '500g': 180, '1kg': 340},
      rating: 4.7, image: 'assets/images/uppava_traditional_salted_pickle.jpg', 
      color: const Color(0xFF18453B), category: 'Pickles', reviews: _mockReviews,
      pairings: ['Allu Chips', 'Sweet Chekki', 'Haldi Powder'],
      secretIngredient: _secretOil,
    ),

    // SNACKS
    Product(
      name: 'Chakinalu', 
      description: 'Crunchy traditional Sankranti spiral snacks crafted from 12-month aged rice flour.\nDeep-fried in small batches with fragrant carom seeds and pure oils.\nProvides an addictive savory crunch that makes every tea time special.', 
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
      description: 'Crispy, spiced gram flour droplets fried golden and seasoned with fresh curry leaves.\nAn irresistible tea-time companion packed with authentic homemade flavors.\nOffers a light, savory crunch that pairs wonderfully with meals and snacks.', 
      weightPriceMap: {'250g': 45, '500g': 80, '1kg': 150},
      rating: 4.6, image: 'assets/images/bundhi_crispy_spiced_gram_flour_droplets.jpg',
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Gondh Laddu'],
      secretIngredient: _secretOil,
    ),
    Product(
      name: 'Allu Chips', 
      description: 'Thinly sliced Indian potato chips fried golden and sprinkled with special spices.\nCrispy, light, and perfectly salted for your daily snacking cravings.\nPrepared with utmost hygiene and care using premium farm potatoes.', 
      weightPriceMap: {'250g': 55, '500g': 99, '1kg': 190},
      rating: 4.7, image: 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Uppava', 'Sweet Chekki'],
      secretIngredient: _secretOil,
    ),
    Product(
      name: 'Karam Janthukalu', 
      description: 'Crispy spiral murukku strings made with rice flour and roasted gram.\nInfused with fiery red chilli and cumin for a delightful traditional crunch.\nA classic festival snack loved by spice enthusiasts of all ages.', 
      weightPriceMap: {'250g': 90, '500g': 160, '1kg': 300},
      rating: 4.8, image: 'assets/images/karam_janthukalu_murukku_strings_snack.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Palli Patti'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Khara Mixture', 
      description: 'An assorted crunchy savory mix of fried lentils, sev, peanuts, and curry leaves.\nTossed in authentic spices for a satisfying medley of textures and flavors.\nThe ultimate snack mix to elevate your evening tea or family gatherings.', 
      weightPriceMap: {'250g': 70, '500g': 120, '1kg': 230},
      rating: 4.7, image: 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Dry Fruits Laddu'],
      secretIngredient: _secretOil,
    ),
    Product(
      name: 'Nuvvula Papad', 
      description: 'Crispy sun-dried papads generously coated with unhulled black sesame seeds.\nOffers a robust nutty aroma and superior crunch when roasted or fried.\nAn exceptional traditional accompaniment for rice, dal, and authentic meals.', 
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
      description: 'Crisp, savory wheel snacks flavored with rich onion extracts and mild spices.\nDelightfully light and crunchy, making them a favorite across all age groups.\nCrafted in small batches to ensure consistent texture and superior taste.', 
      weightPriceMap: {'200g': 80, '400g': 150, '1kg': 350},
      rating: 4.5, image: 'assets/images/onion_whills_onion_flavored_crisp_wheels.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Kova Gulam Jamun'],
      secretIngredient: _secretOil,
    ),
    Product(
      name: 'Rice Papad', 
      description: 'Traditional crispy rice flour papadums sun-dried under peak weather conditions.\nExpands beautifully when fried, providing a light and crunchy accompaniment.\nMade with pure rice batter and traditional sun-drying techniques.', 
      weightPriceMap: {'250g': 60, '500g': 100, '1kg': 190},
      rating: 4.6, image: 'assets/images/rice_papad_crispy_rice_flour_papadums.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Sunnunda Laddu'],
      secretIngredient: _secretMango,
    ),
    Product(
      name: 'Tomato Chilli Papad', 
      description: 'Sun-dried papadums infused with tangy tomato pulp and fiery green chillies.\nDelivers a burst of lip-smacking flavor and crispiness with every bite.\nA vibrant twist on traditional papads that excites your palate instantly.', 
      weightPriceMap: {'250g': 70, '500g': 120, '1kg': 230},
      rating: 4.6, image: 'assets/images/tomato_chilli_papad_tangy_and_spicy_papads.jpg', 
      color: const Color(0xFF18453B), category: 'Snacks', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Thill Patti'],
      secretIngredient: _secretSpices,
    ),

    // SPICES
    Product(
      name: 'Allam Velluli Karam Podi', 
      description: 'A robust ginger garlic spice powder ground with roasted lentils and red chillies.\nBest enjoyed mixed with hot rice and a generous pour of desi ghee.\nProvides a warming, aromatic spice kick that comforts the soul.', 
      weightPriceMap: {'250g': 149, '500g': 280, '1kg': 540},
      rating: 4.8, image: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Rice Papad'],
      secretIngredient: _secretGarlic,
    ),
    Product(
      name: 'Chicken Masala Powder', 
      description: 'An aromatic chicken curry spice blend crafted from whole roasted spices.\nElevates home-cooked chicken dishes with restaurant-quality depth and aroma.\nImparts a rich gravy texture and authentic traditional flavor profile.', 
      weightPriceMap: {'100g': 120, '250g': 280, '500g': 540},
      rating: 4.7, image: 'assets/images/chicken_masala_powder_chicken_curry_spice_blend.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Chakinalu'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Daniya Powder', 
      description: 'Freshly ground coriander powder produced from bright green seeds of Kurnool.\nAdds an earthy fragrance and a delicate body to traditional Indian curries.\nGround with precision to retain natural essential oils and vibrant color.', 
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
      description: 'A traditional warm spice blend combining cardamom, cloves, cinnamon, and nutmeg.\nImparts an exquisite aroma and deep flavorful complexity to every dish.\nExpertly proportioned for authentic homemade culinary excellence.', 
      weightPriceMap: {'100g': 150, '250g': 360, '500g': 680},
      rating: 4.8, image: 'assets/images/garam_masala_powder_traditional_warm_spice_blend.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Chakinalu'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Haldi Powder', 
      description: 'Pure, unadulterated Salem turmeric powder with over 5% natural curcumin.\nRenowned for its vibrant golden hue, earthy aroma, and wellness properties.\nSourced directly from trusted farmers and ground without additives.', 
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
      description: 'Fragrant curry leaves powder made from tender, pesticide-free foliage.\nPacked with iron and antioxidants, perfect for idlis, dosas, and rice.\nBrings the goodness of fresh green herbs straight to your dining table.', 
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
      description: 'Finely ground roasted fenugreek powder with a distinct bitter-sweet profile.\nAn essential spice for authentic pickle making and digestive health benefits.\nRoasted to perfection to eliminate bitterness and unlock nutty aromas.', 
      weightPriceMap: {'200g': 110, '500g': 260, '1kg': 500},
      rating: 4.6, image: 'assets/images/menthi_podi_fenugreek_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Tomato Chilli Papad'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Munagaku Karam Podi', 
      description: 'Nutrient-dense Moringa leaves spice powder shade-dried for rich green color.\nA powerhouse of vitamins and minerals to boost your daily family meals.\nCrafted with care to preserve maximum nutritional value and taste.', 
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
      description: 'A robust, heavy-duty spice blend specially formulated for rich mutton curries.\nFeatures coarsely ground whole spices that lock in deep savory flavor.\nGuarantees tender, aromatic, and restaurant-style meat preparations at home.', 
      weightPriceMap: {'100g': 160, '250g': 380, '500g': 720},
      rating: 4.8, image: 'assets/images/mutton_masala_powder_mutton_recipe_spice_blend.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Karam Janthukalu'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Putnala Karam Podi', 
      description: 'Smooth roasted gram spice powder blended with garlic and dried red chillies.\nA comforting accompaniment for soft idlis, dosas, and hot steamed rice.\nDelivers a smooth, protein-rich nutty flavor in every spoonful.', 
      weightPriceMap: {'250g': 110, '500g': 200, '1kg': 380},
      rating: 4.7, image: 'assets/images/putnala_karam_podi_roasted_gram_spice_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Bundhi'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Sambhar Masala Powder', 
      description: 'Authentic sambhar spice blend crafted with roasted lentils and fenugreek.\nDelivers the quintessential South Indian restaurant flavor profile at home.\nTransforms ordinary lentil stews into aromatic, restaurant-grade feasts.', 
      weightPriceMap: {'200g': 140, '500g': 330, '1kg': 640},
      rating: 4.8, image: 'assets/images/sambhar_masala_powder_authentic_sambhar_spice_blend.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Rice Papad'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Special Idli Karam Podi', 
      description: 'Legendary gun powder spice mix for idlis and dosas with chana dal and garlic.\nBest served bubbling hot with a generous puddle of sesame oil or ghee.\nAn essential morning staple for every traditional South Indian breakfast.', 
      weightPriceMap: {'250g': 150, '500g': 280, '1kg': 540},
      rating: 4.9, image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Chakinalu'],
      secretIngredient: _secretSpices,
    ),
    Product(
      name: 'Special Kura Karam Podi', 
      description: 'Versatile all-purpose curry powder designed to elevate everyday vegetable stir-fries.\nBrings an instant burst of homemade spice, warmth, and rich aroma.\nSimplifies cooking while delivering authentic, traditional flavors.', 
      weightPriceMap: {'250g': 180, '500g': 340, '1kg': 650},
      rating: 4.8, image: 'assets/images/special_kura_karam_podi_all-purpose_curry_powder.jpg', 
      color: const Color(0xFF18453B), category: 'Spices', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Rice Papad'],
      secretIngredient: _secretSpices,
    ),

    // SWEETS
    Product(
      name: 'Dry Fruits Laddu', 
      description: 'A luxurious energy-dense laddu packed with almonds, cashews, and pistachios.\nBound together with pure desi cow ghee without any added refined sugar.\nProvides sustained natural vitality and rich artisanal sweetness.', 
      weightPriceMap: {'250g': 240, '500g': 450, '1kg': 880},
      rating: 5.0, image: 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Bundhi'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Gondh Laddu', 
      description: 'Traditional edible gum (gondh) laddu roasted in pure desi cow ghee and wheat.\nExcellent for winter nourishment, bone strength, and sustained natural energy.\nCrafted using ancestral recipes for authentic health and taste.', 
      weightPriceMap: {'250g': 200, '500g': 380, '1kg': 740},
      rating: 5.0, image: 'assets/images/gondh_laddu_edible_gum_laddu.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', isBestSeller: true, reviews: _mockReviews,
      pairings: ['Allam Velluli Pickle', 'Khara Mixture'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Kova Gulam Jamun', 
      description: 'Rich, succulent gulab jamuns made from pure milk khoya and sugar syrup.\nMelts instantly in your mouth with exquisite royal sweetness and aroma.\nThe ultimate dessert centerpiece for celebrations and festive gatherings.', 
      weightPriceMap: {'250g': 150, '500g': 280, '1kg': 540},
      rating: 4.9, image: 'assets/images/kova_gulam_jamun_rich_gulab_jamun_sweet.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Onion Whills'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Millets Laddu', 
      description: 'Wholesome multi-millet laddu crafted from nutrient-rich ragi and jowar flours.\nSweetened naturally with organic jaggery and enriched with cow ghee.\nA nutritious superfood sweet that delights children and adults alike.', 
      weightPriceMap: {'250g': 190, '500g': 350, '1kg': 680},
      rating: 4.9, image: 'assets/images/millets_laddu_wholesome_multi-millet_laddu.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Tomato Chilli Papad'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Palli Patti', 
      description: 'Crunchy peanut and jaggery chikki made from farm-fresh roasted peanuts.\nA traditional high-protein snack loaded with nostalgic sweet and nutty flavor.\nBoiled to a crisp perfection for an unforgettable snacking experience.', 
      weightPriceMap: {'250g': 65, '500g': 120, '1kg': 230},
      rating: 4.8, image: 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Karam Janthukalu'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Sunnunda Laddu', 
      description: 'Classic Andhra roasted urad dal laddu bound with organic jaggery and ghee.\nPacked with plant protein and rich caramel undertones in every single bite.\nA legendary festive sweet cherished across generations in Andhra families.', 
      weightPriceMap: {'250g': 170, '500g': 320, '1kg': 620},
      rating: 4.9, image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Bellam Avakaya', 'Chakinalu'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Sweet Chekki', 
      description: 'Traditional sweet brittle crafted with crunchy nuts and caramelized sugar syrup.\nOffers a satisfying snap and a rich buttery sweetness that lingers.\nA classic heritage confection made with pure ingredients and love.', 
      weightPriceMap: {'250g': 55, '500g': 100, '1kg': 190},
      rating: 4.7, image: 'assets/images/sweet_chekki_traditional_sweet_brittle.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Uppava', 'Allu Chips'],
      secretIngredient: _secretGhee,
    ),
    Product(
      name: 'Thill Patti', 
      description: 'Wholesome sesame seed and jaggery brittle packed with calcium and warmth.\nA traditional winter delicacy offering a delightful and nutritious nutty crunch.\nExpertly crafted for clean, wholesome, and authentic sweet indulgence.', 
      weightPriceMap: {'250g': 70, '500g': 130, '1kg': 250},
      rating: 4.8, image: 'assets/images/thill_patti_sesame_seed_and_jaggery_sweet.jpg', 
      color: const Color(0xFF18453B), category: 'Sweets', reviews: _mockReviews,
      pairings: ['Usiri Pickle', 'Tomato Chilli Papad'],
      secretIngredient: _secretGhee,
    ),
  ];

  Stream<List<Product>> getProductsStream() async* {
    yield allProducts; // Instant render
    try {
      final list = await ApiService.getProducts();
      if (list.isNotEmpty) {
        yield list.map((item) => _mapToProduct(item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      debugPrint('Error loading products stream: $e');
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final list = await ApiService.getProducts();
      if (list.isNotEmpty) {
        return list.map((item) => _mapToProduct(item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      debugPrint('DEBUG: Error fetching products (Future): $e');
    }
    return allProducts; // Fallback to local data
  }

  Product _mapToProduct(Map<String, dynamic> data) {
    // 1. SAFE WEIGHT MAP PARSING
    Map<String, double> safeWeightMap = {};
    if (data['weightPriceMap'] != null && data['weightPriceMap'] is Map) {
      (data['weightPriceMap'] as Map).forEach((k, v) {
        safeWeightMap[k.toString()] = (v as num).toDouble();
      });
    }
    if (safeWeightMap.isEmpty) {
      // Find local product to get actual weights
      final localProduct = allProducts.where((p) => p.name == (data['name']?.toString() ?? '')).firstOrNull;
      if (localProduct != null) {
        safeWeightMap = localProduct.weightPriceMap;
      } else {
        safeWeightMap = {"250g": 180.0, "500g": 350.0, "1kg": 680.0};
      }
    }

    // 2. SAFE SOMMELIER PAIRINGS
    List<SommelierPairing> safePairings = [];
    if (data['sommelierPairings'] != null && data['sommelierPairings'] is List) {
      for (var p in (data['sommelierPairings'] as List)) {
        if (p is Map) {
          safePairings.add(SommelierPairing(
            title: p['title']?.toString() ?? '',
            description: p['description']?.toString() ?? '',
            icon: _getIconData(p['icon']?.toString() ?? 'help_outline'),
          ));
        }
      }
    }

    // 3. SAFE RECIPES
    List<Map<String, String>> safeRecipes = [];
    if (data['recipes'] != null && data['recipes'] is List) {
      for (var r in (data['recipes'] as List)) {
        if (r is Map) {
          safeRecipes.add({
            'title': r['title']?.toString() ?? '',
            'instruction': r['instruction']?.toString() ?? '',
          });
        }
      }
    }

    return Product(
      name: data['name']?.toString() ?? 'Royal Pickle',
      description: data['description']?.toString() ?? '',
      weightPriceMap: safeWeightMap,
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      image: data['image']?.toString() ?? 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
      color: Color(int.tryParse(data['color']?.toString() ?? '0xFF18453B') ?? 0xFF18453B),
      category: data['category']?.toString() ?? 'Pickles',
      isBestSeller: data['isBestSeller'] == true,
      isOutOfStock: data['isOutOfStock'] == true,
      stockCount: (data['stockCount'] as num?)?.toInt() ?? 100,
      isVeg: data['isVeg'] != false, // Default to true unless explicitly false
      subCategory: data['subCategory']?.toString() ?? 'Classic',
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 42,
      purchaseCount: (data['purchaseCount'] as num?)?.toInt() ?? 15,
      trustBadges: List<String>.from(data['trustBadges'] as List? ?? ['Zero Preservatives', 'Sun-Dried', 'Hand-Sorted', 'Stone-Pounded']),
      artisanName: data['artisanName']?.toString() ?? 'Smt. Annapurna',
      artisanImage: data['artisanImage']?.toString() ?? 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      artisanDescription: data['artisanDescription']?.toString() ?? 'Our Master Pickle Maker with over 40 years of experience.',
      recipes: safeRecipes,
      pairings: List<String>.from(data['pairings'] as List? ?? []),
      origin: data['origin']?.toString() ?? 'Coastal Andhra, India',
      ingredients: List<String>.from(data['ingredients'] as List? ?? []),
      preparationMethod: data['preparationMethod']?.toString() ?? '',
      shelfLife: data['shelfLife']?.toString() ?? '',
      storageInstructions: data['storageInstructions']?.toString() ?? '',
      servingSuggestion: data['servingSuggestion']?.toString() ?? '',
      canRequestTempering: data['canRequestTempering'] == true,
      secretIngredient: IngredientDetail(
        name: data['secretIngredient']?['name']?.toString() ?? 'Royal Spices',
        description: data['secretIngredient']?['description']?.toString() ?? 'Secret blend of heritage spices.',
        image: data['secretIngredient']?['image']?.toString() ?? 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
      ),
      sommelierPairings: safePairings,
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
      'stockCount': p.stockCount,
      'isVeg': p.isVeg,
      'subCategory': p.subCategory,
      'viewCount': p.viewCount,
      'purchaseCount': p.purchaseCount,
      'trustBadges': p.trustBadges,
      'artisanName': p.artisanName,
      'artisanImage': p.artisanImage,
      'artisanDescription': p.artisanDescription,
      'recipes': p.recipes,
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
