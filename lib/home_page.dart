import 'package:flutter/material.dart';
import 'product_detail_page.dart';
import 'cart_manager.dart';
import 'models.dart';
import 'main.dart'; // Import to access MainScreen

class WishlistManager extends ChangeNotifier {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal();

  final List<Product> _wishlist = [];
  List<Product> get items => _wishlist;

  void toggleFavorite(Product product) {
    if (_wishlist.contains(product)) {
      _wishlist.remove(product);
    } else {
      _wishlist.add(product);
    }
    notifyListeners();
  }

  bool isFavorite(Product product) => _wishlist.contains(product);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final List<Review> _mockReviews = [
    Review(userName: 'Rahul S.', comment: 'Amazing taste! Reminds me of my grandmother\'s handmade pickles.', rating: 5.0, date: '2 days ago'),
    Review(userName: 'Priya K.', comment: 'The spice level is perfect. Very authentic flavors.', rating: 4.5, date: '1 week ago'),
    Review(userName: 'Anish M.', comment: 'Fresh and high quality. Highly recommended!', rating: 5.0, date: '2 weeks ago'),
  ];

  final List<Product> allProducts = [
    Product(name: 'Allam Velluli Karam Podi', description: 'Ginger garlic spice powder', price: '₹149', weight: '250g', rating: 4.8, image: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg', color: const Color(0xFFD35400), category: 'Spices', spiceLevel: 4, pairings: ['Idli', 'Ghee Rice'], reviews: _mockReviews),
    Product(name: 'Allam Velluli Pickle', description: 'Ginger garlic pickle', price: '₹220', weight: '500g', rating: 4.9, image: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg', color: const Color(0xFFE67E22), category: 'Pickles', spiceLevel: 3, pairings: ['Curd Rice', 'Paratha'], reviews: _mockReviews, isBestSeller: true),
    Product(name: 'Allu Chips', description: 'Thinly sliced Indian potato chips', price: '₹99', weight: '200g', rating: 4.7, image: 'assets/images/allu_chips_thinly_sliced_indian_potato_chips.jpg', color: const Color(0xFFFFD93D), category: 'Snacks', spiceLevel: 2, pairings: ['Tea', 'Soft Drinks'], reviews: _mockReviews),
    Product(name: 'Bellam Avakaya', description: 'Sweet jaggery mango pickle', price: '₹260', weight: '500g', rating: 4.9, image: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', color: const Color(0xFFFFD93D), category: 'Pickles', spiceLevel: 2, pairings: ['Hot Rice', 'Puri'], reviews: _mockReviews, isBestSeller: true),
    Product(name: 'Bundhi', description: 'Crispy spiced gram flour droplets', price: '₹80', weight: '250g', rating: 4.6, image: 'assets/images/bundhi_crispy_spiced_gram_flour_droplets.jpg', color: const Color(0xFFF9D923), category: 'Snacks', spiceLevel: 3, pairings: ['Evening Tea', 'Mixture'], reviews: _mockReviews),
    Product(name: 'Chakinalu', description: 'Traditional Sankranti spiral snacks', price: '₹180', weight: '500g', rating: 4.8, image: 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg', color: const Color(0xFFF1F2F3), category: 'Snacks', spiceLevel: 1, pairings: ['Coffee', 'Pickle'], reviews: _mockReviews),
    Product(name: 'Chicken Masala Powder', description: 'Chicken curry spice blend', price: '₹120', weight: '100g', rating: 4.7, image: 'assets/images/chicken_masala_powder_chicken_curry_spice_blend.jpg', color: const Color(0xFFFF6B6B), category: 'Spices', spiceLevel: 5, pairings: ['Chicken Curry', 'Fry'], reviews: _mockReviews, isBestSeller: true),
    Product(name: 'Daniya Powder', description: 'Freshly ground coriander powder', price: '₹80', weight: '200g', rating: 4.5, image: 'assets/images/daniya_powder_freshly_ground_coriander_powder.jpg', color: const Color(0xFF6BCB77), category: 'Spices', spiceLevel: 1, pairings: ['All Veg Curries'], reviews: _mockReviews),
    Product(name: 'Dry Fruits Laddu', description: 'Premium dry fruits laddu', price: '₹450', weight: '500g', rating: 5.0, image: 'assets/images/dry_fruits_laddu_premium_dry_fruits_laddu.jpg', color: const Color(0xFFD35400), category: 'Sweets', spiceLevel: 0, pairings: ['Milk', 'Dessert'], reviews: _mockReviews),
    Product(name: 'Garam Masala Powder', description: 'Traditional warm spice blend', price: '₹150', weight: '100g', rating: 4.8, image: 'assets/images/garam_masala_powder_traditional_warm_spice_blend.jpg', color: const Color(0xFFD35400), category: 'Spices', spiceLevel: 4, pairings: ['Biryani', 'Masala Curry'], reviews: _mockReviews),
    Product(name: 'Gondh Laddu', description: 'Edible gum laddu', price: '₹380', weight: '500g', rating: 4.9, image: 'assets/images/gondh_laddu_edible_gum_laddu.jpg', color: const Color(0xFFE67E22), category: 'Sweets', spiceLevel: 0, pairings: ['Morning Snack'], reviews: _mockReviews, isBestSeller: true),
    Product(name: 'Haldi Powder', description: 'Pure turmeric powder', price: '₹90', weight: '250g', rating: 4.7, image: 'assets/images/haldi_powder_pure_turmeric_powder.jpg', color: const Color(0xFFF9D923), category: 'Spices', spiceLevel: 0, pairings: ['Daily Cooking'], reviews: _mockReviews),
    Product(name: 'Karam Janthukalu', description: 'Murukku strings snack', price: '₹160', weight: '500g', rating: 4.8, image: 'assets/images/karam_janthukalu_murukku_strings_snack.jpg', color: const Color(0xFFF1F2F3), category: 'Snacks', spiceLevel: 3, pairings: ['Tea time'], reviews: _mockReviews),
    Product(name: 'Karvepaku Karam Podi', description: 'Curry leaves powder', price: '₹130', weight: '250g', rating: 4.9, image: 'assets/images/karvepaku_karam_podi_curry_leaves_powder.jpg', color: const Color(0xFF6BCB77), category: 'Spices', spiceLevel: 3, pairings: ['Idli', 'Dosa'], reviews: _mockReviews),
    Product(name: 'Khara Mixture', description: 'Assorted crunchy savory mix', price: '₹120', weight: '400g', rating: 4.7, image: 'assets/images/khara_mixture_assorted_crunchy_savory_mix.jpg', color: const Color(0xFFF9D923), category: 'Snacks', spiceLevel: 4, pairings: ['Drinks', 'Tea'], reviews: _mockReviews),
    Product(name: 'Kova Gulam Jamun', description: 'Rich gulab jamun sweet', price: '₹280', weight: '500g', rating: 4.9, image: 'assets/images/kova_gulam_jamun_rich_gulab_jamun_sweet.jpg', color: const Color(0xFFD35400), category: 'Sweets', spiceLevel: 0, pairings: ['Party Dessert'], reviews: _mockReviews),
    Product(name: 'Menthi Podi', description: 'Fenugreek powder', price: '₹110', weight: '200g', rating: 4.6, image: 'assets/images/menthi_podi_fenugreek_powder.jpg', color: const Color(0xFF6BCB77), category: 'Spices', spiceLevel: 2, pairings: ['Dal', 'Sambar'], reviews: _mockReviews),
    Product(name: 'Millets Laddu', description: 'Wholesome multi-millet laddu', price: '₹350', weight: '500g', rating: 4.9, image: 'assets/images/millets_laddu_wholesome_multi-millet_laddu.jpg', color: const Color(0xFFE67E22), category: 'Sweets', spiceLevel: 0, pairings: ['Health Snack'], reviews: _mockReviews),
    Product(name: 'Munagaku Karam Podi', description: 'Moringa leaves spice powder', price: '₹160', weight: '250g', rating: 4.9, image: 'assets/images/munagaku_karam_podi_moringa_leaves_spice_powder.jpg', color: const Color(0xFF6BCB77), category: 'Spices', spiceLevel: 3, pairings: ['Hot Rice'], reviews: _mockReviews),
    Product(name: 'Mutton Masala Powder', description: 'Mutton recipe spice blend', price: '₹160', weight: '100g', rating: 4.8, image: 'assets/images/mutton_masala_powder_mutton_recipe_spice_blend.jpg', color: const Color(0xFFFF6B6B), category: 'Spices', spiceLevel: 5, pairings: ['Mutton Curry'], reviews: _mockReviews),
    Product(name: 'Nuvvula Papad', description: 'Sesame coated crispy papads', price: '₹140', weight: '250g', rating: 4.7, image: 'assets/images/nuvvula_papad_sesame_coated_crispy_papads.jpg', color: const Color(0xFFF1F2F3), category: 'Snacks', spiceLevel: 1, pairings: ['Lunch Side'], reviews: _mockReviews),
    Product(name: 'Onion Whills', description: 'Onion flavored crisp wheels', price: '₹80', weight: '200g', rating: 4.5, image: 'assets/images/onion_whills_onion_flavored_crisp_wheels.jpg', color: const Color(0xFFF1F2F3), category: 'Snacks', spiceLevel: 2, pairings: ['Movie Snack'], reviews: _mockReviews),
    Product(name: 'Palli Patti', description: 'Peanut and jaggery chikki', price: '₹120', weight: '300g', rating: 4.8, image: 'assets/images/palli_patti_peanut_and_jaggery_chikki.jpg', color: const Color(0xFFFFD93D), category: 'Sweets', spiceLevel: 0, pairings: ['Quick Energy'], reviews: _mockReviews),
    Product(name: 'Putnala Karam Podi', description: 'Roasted gram spice powder', price: '₹110', weight: '250g', rating: 4.7, image: 'assets/images/putnala_karam_podi_roasted_gram_spice_powder.jpg', color: const Color(0xFFD35400), category: 'Spices', spiceLevel: 3, pairings: ['Breakfast'], reviews: _mockReviews),
    Product(name: 'Rice Papad', description: 'Crispy rice flour papadums', price: '₹100', weight: '250g', rating: 4.6, image: 'assets/images/rice_papad_crispy_rice_flour_papadums.jpg', color: const Color(0xFFF1F2F3), category: 'Snacks', spiceLevel: 1, pairings: ['Pappu Charu'], reviews: _mockReviews),
    Product(name: 'Sambhar Masala Powder', description: 'Authentic sambhar spice blend', price: '₹140', weight: '200g', rating: 4.8, image: 'assets/images/sambhar_masala_powder_authentic_sambhar_spice_blend.jpg', color: const Color(0xFFFFD93D), category: 'Spices', spiceLevel: 3, pairings: ['Sambar Rice'], reviews: _mockReviews),
    Product(name: 'Special Idli Karam Podi', description: 'Gun powder spice for idlis', price: '₹150', weight: '250g', rating: 4.9, image: 'assets/images/special_idli_karam_podi_gun_powder_spice_for_idlis.jpg', color: const Color(0xFFD35400), category: 'Spices', spiceLevel: 4, pairings: ['Idli', 'Dosa'], reviews: _mockReviews),
    Product(name: 'Special Kura Karam Podi', description: 'All-purpose curry powder', price: '₹180', weight: '250g', rating: 4.8, image: 'assets/images/special_kura_karam_podi_all-purpose_curry_powder.jpg', color: const Color(0xFFFF6B6B), category: 'Spices', spiceLevel: 4, pairings: ['All Veg Fries'], reviews: _mockReviews),
    Product(name: 'Sunnunda Laddu', description: 'Roasted urad dal laddu', price: '₹320', weight: '500g', rating: 4.9, image: 'assets/images/sunnunda_laddu_roasted_urad_dal_laddu.jpg', color: const Color(0xFFE67E22), category: 'Sweets', spiceLevel: 0, pairings: ['Tradition Sweet'], reviews: _mockReviews),
    Product(name: 'Sweet Chekki', description: 'Traditional sweet brittle', price: '₹100', weight: '250g', rating: 4.7, image: 'assets/images/sweet_chekki_traditional_sweet_brittle.jpg', color: const Color(0xFFFFD93D), category: 'Sweets', spiceLevel: 0, pairings: ['Kids Snack'], reviews: _mockReviews),
    Product(name: 'Thill Patti', description: 'Sesame seed and jaggery sweet', price: '₹130', weight: '300g', rating: 4.8, image: 'assets/images/thill_patti_sesame_seed_and_jaggery_sweet.jpg', color: const Color(0xFFF9D923), category: 'Sweets', spiceLevel: 0, pairings: ['Winter Sweet'], reviews: _mockReviews),
    Product(name: 'Tomato Chilli Papad', description: 'Tangy and spicy papads', price: '₹120', weight: '250g', rating: 4.6, image: 'assets/images/tomato_chilli_papad_tangy_and_spicy_papads.jpg', color: const Color(0xFFFF6B6B), category: 'Snacks', spiceLevel: 3, pairings: ['Dal Rice'], reviews: _mockReviews),
    Product(name: 'Uppava', description: 'Traditional salted pickle', price: '₹180', weight: '500g', rating: 4.7, image: 'assets/images/uppava_traditional_salted_pickle.jpg', color: const Color(0xFFF1F2F3), category: 'Pickles', spiceLevel: 1, pairings: ['Plain Rice'], reviews: _mockReviews),
    Product(name: 'Usiri Pickle', description: 'Amla gooseberry pickle', price: '₹240', weight: '500g', rating: 4.9, image: 'assets/images/usiri_pickle_amlagooseberry_pickle.jpg', color: const Color(0xFF6BCB77), category: 'Pickles', spiceLevel: 3, pairings: ['Rice', 'Curd'], reviews: _mockReviews),
  ];

  final List<Map<String, String>> pickleBanners = [
    {
      'title': 'MONSOON SPECIAL',
      'subtitle': 'Extra 20% off on all Mango varieties',
      'image': 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg',
      'code': 'RAINY20',
    },
    {
      'title': 'GRANDMA\'S SECRET',
      'subtitle': 'Buy 2 Get 1 Free on Gongura Pickles',
      'image': 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg',
      'code': 'TRADITION',
    },
    {
      'title': 'SPICY CHICKEN FEST',
      'subtitle': 'Flat ₹150 OFF on Non-Veg Combo',
      'image': 'assets/images/chicken_masala_powder_chicken_curry_spice_blend.jpg',
      'code': 'SPICY150',
    },
  ];

  List<Product> displayedProducts = [];
  String searchQuery = "";
  String selectedCategory = "All";
  String currentSort = "Popularity";

  @override
  void initState() {
    super.initState();
    displayedProducts = List.from(allProducts);
    WishlistManager().addListener(() => setState(() {}));
  }

  void _filterAndSort() {
    setState(() {
      displayedProducts = allProducts.where((product) {
        bool matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                             product.description.toLowerCase().contains(searchQuery.toLowerCase());
        bool matchesCategory = selectedCategory == "All" || product.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();

      if (currentSort == "Price: Low to High") {
        displayedProducts.sort((a, b) => double.parse(a.price.replaceAll('₹', '')).compareTo(double.parse(b.price.replaceAll('₹', ''))));
      } else if (currentSort == "Price: High to Low") {
        displayedProducts.sort((a, b) => double.parse(b.price.replaceAll('₹', '')).compareTo(double.parse(a.price.replaceAll('₹', ''))));
      } else if (currentSort == "Spice Level") {
        displayedProducts.sort((a, b) => b.spiceLevel.compareTo(a.spiceLevel));
      } else if (currentSort == "Popularity") {
        displayedProducts.sort((a, b) => b.rating.compareTo(a.rating));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // CLEAN BRANDING HEADER
          SliverAppBar(
            floating: true,
            pinned: false,
            elevation: 0,
            backgroundColor: Colors.white,
            toolbarHeight: 70,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ADHVAITHA',
                  style: TextStyle(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => MainScreen.of(context)?.setIndex(2),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                        child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF2C3E50), size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => MainScreen.of(context)?.setIndex(3),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.shade100,
                        child: const Icon(Icons.person_rounded, color: Color(0xFF2C3E50), size: 20),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEARCH BAR (Swiggy Style)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        searchQuery = value;
                        _filterAndSort();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search "mango pickle" or "laddoo"',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD35400)),
                        suffixIcon: const Icon(Icons.mic_none_rounded, color: Color(0xFFD35400)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),

                if (searchQuery.isEmpty && selectedCategory == "All") ...[
                  // BANNERS (Full Width like Swiggy)
                  const SizedBox(height: 10),
                  SliverBannerSection(pickleBanners: pickleBanners),
                  
                  const SizedBox(height: 24),
                  
                  // CIRCULAR CATEGORIES (Swiggy Style)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('What\'s on your mind?', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        _CircularCategory(title: 'Pickles', icon: 'assets/images/bellam_avakaya_sweet_jaggery_mango_pickle.jpg', isSelected: selectedCategory == 'Pickles', onTap: () { selectedCategory = 'Pickles'; _filterAndSort(); }),
                        _CircularCategory(title: 'Snacks', icon: 'assets/images/chakinalu_traditional_sankranti_spiral_snacks.jpg', isSelected: selectedCategory == 'Snacks', onTap: () { selectedCategory = 'Snacks'; _filterAndSort(); }),
                        _CircularCategory(title: 'Spices', icon: 'assets/images/allam_velluli_karam_podi_ginger_garlic_spice_powder.jpg', isSelected: selectedCategory == 'Spices', onTap: () { selectedCategory = 'Spices'; _filterAndSort(); }),
                        _CircularCategory(title: 'Sweets', icon: 'assets/images/gondh_laddu_edible_gum_laddu.jpg', isSelected: selectedCategory == 'Sweets', onTap: () { selectedCategory = 'Sweets'; _filterAndSort(); }),
                        _CircularCategory(title: 'All', icon: 'assets/images/allam_velluli_pickle_ginger_garlic_pickle.jpg', isSelected: selectedCategory == 'All', onTap: () { selectedCategory = 'All'; _filterAndSort(); }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // TOP RATED (Like Zomato's "Top brands")
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Top Rated Pickles', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        _buildSortDropdown(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280, // Increased from 240 to prevent overflow
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 170, // Slightly wider for better proportion
                          margin: const EdgeInsets.only(right: 16),
                          child: AdvanceProductCard(product: allProducts[index]),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('All Pickles & Powders', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  ),
                ],
              ],
            ),
          ),

          // MAIN PRODUCT GRID (Zomato Style)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return AdvanceProductCard(product: displayedProducts[index]);
                },
                childCount: (searchQuery.isEmpty && selectedCategory == "All") ? 6 : displayedProducts.length,
              ),
            ),
          ),
          
          if (searchQuery.isEmpty && selectedCategory == "All")
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = "All";
                        searchQuery = "";
                        _filterAndSort();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      side: const BorderSide(color: Color(0xFFD35400), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('SEE FULL MENU', style: TextStyle(color: Color(0xFFD35400), fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        currentSort = value;
        _filterAndSort();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Text('Sort', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Icon(Icons.arrow_drop_down_rounded, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: "Popularity", child: Text("Popularity")),
        const PopupMenuItem(value: "Price: Low to High", child: Text("Price: Low to High")),
        const PopupMenuItem(value: "Price: High to Low", child: Text("Price: High to Low")),
        const PopupMenuItem(value: "Spice Level", child: Text("Spice Level")),
      ],
    );
  }
}

class SliverBannerSection extends StatelessWidget {
  final List<Map<String, String>> pickleBanners;
  const SliverBannerSection({super.key, required this.pickleBanners});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Example: Navigate to Pickles category
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Viewing Monsoon Specials!')));
      },
      child: SizedBox(
        height: 180,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.88),
          itemCount: pickleBanners.length,
          itemBuilder: (context, index) {
            final banner = pickleBanners[index];
            return Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(image: AssetImage(banner['image']!), fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(banner['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                    Text(banner['subtitle']!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CircularCategory extends StatelessWidget {
  final String title;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CircularCategory({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Container(
              height: 75,
              width: 75,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFD35400) : Colors.transparent, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: Image.asset(icon, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(title, 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class AdvanceProductCard extends StatelessWidget {
  final Product product;
  const AdvanceProductCard({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager();
    final bool isFav = wishlist.isFavorite(product);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailPage(product: product)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Hero(
                  tag: product.name,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(image: AssetImage(product.image), fit: BoxFit.cover),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => wishlist.toggleFavorite(product),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 15,
                      child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: isFav ? Colors.red : Colors.grey),
                    ),
                  ),
                ),
                if (product.isBestSeller)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD35400),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomLeft: Radius.circular(18)),
                      ),
                      child: const Text('BESTSELLER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(product.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.star_rounded, color: Colors.green, size: 16),
              Text(' ${product.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 2),
          Text(product.description, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(product.price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
              GestureDetector(
                onTap: () {
                  CartManager().addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.name} added!'), behavior: SnackBarBehavior.floating));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD35400)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('ADD', style: TextStyle(color: Color(0xFFD35400), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
