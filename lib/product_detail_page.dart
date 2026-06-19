import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'cart_manager.dart';
import 'wishlist_manager.dart';
import 'checkout_page.dart';
import 'navigation_util.dart';
import 'product_repository.dart';
import 'cloud_function_manager.dart';
import 'main.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final List<Product> allProducts;
  const ProductDetailPage({super.key, required this.product, this.allProducts = const []});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  late String selectedWeight;
  bool isTemperingRequested = false;
  final TextEditingController _chefNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedWeight = widget.product.defaultWeight;
    ProductRepository.addToRecentlyViewed(widget.product);
  }

  @override
  void dispose() {
    _chefNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistManager();
    final bool isFav = wishlist.isFavorite(widget.product);

    final productPool = widget.allProducts.isNotEmpty ? widget.allProducts : ProductRepository.allProducts;
    final recommendations = productPool.where((p) =>
      widget.product.pairings.contains(p.name)).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: const Color(0xFFFFF8E8),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: Hero(
                  tag: widget.product.name,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.05), width: 1.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        widget.product.image, 
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.grey))
                      ),
                    ),
                  ),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF18453B), size: 18),
                ),
              ),
            ),
            toolbarHeight: 70, // Buffer to eliminate 14px overflow
            actions: [
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  radius: 18,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      wishlist.toggleFavorite(widget.product);
                      setState(() {});
                    },
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Colors.red : const Color(0xFF18453B),
                      size: 18,
                    ),
                  ),
                ),
              ),
              GlobalCartBadge(),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: (widget.product.isOutOfStock ? Colors.red : const Color(0xFF18453B)).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          (widget.product.isOutOfStock ? 'OUT OF STOCK' : widget.product.category).toUpperCase(), 
                          style: TextStyle(color: widget.product.isOutOfStock ? Colors.red : const Color(0xFF18453B), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 20),
                          Text(' ${widget.product.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(' (120+ Reviews)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(widget.product.name, style: GoogleFonts.philosopher(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF18453B))),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.product.getPriceForWeight(selectedWeight), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFFD4AF37))),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('DESCRIPTION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                      GestureDetector(
                        onTap: _showSecretIngredient,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD4AF37)),
                              SizedBox(width: 6),
                              Text('SECRET INGREDIENT', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(widget.product.description, style: TextStyle(fontSize: 15, color: const Color(0xFF2D1B12).withOpacity(0.7), height: 1.6)),
                  
                  const SizedBox(height: 30),
                  const Text('SELECT WEIGHT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 12,
                    children: widget.product.weightPriceMap.keys.map<Widget>((w) => _WeightOption(
                      label: w, 
                      isSelected: selectedWeight == w, 
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => selectedWeight = w);
                      }
                    )).toList(),
                  ),

                  if (widget.product.canRequestTempering) ...[
                    const SizedBox(height: 35),
                    _buildChefCustomization(),
                  ],

                  const SizedBox(height: 40),
                  ListenableBuilder(
                    listenable: CartManager(),
                    builder: (context, _) {
                      final cart = CartManager();
                      final currentQty = cart.getProductQuantity(widget.product.name, selectedWeight);
                      final isOut = widget.product.isOutOfStock;
                      
                      return Row(
                        children: [
                          // SMALL BUY NOW BUTTON
                          GestureDetector(
                            onTap: isOut ? null : () {
                              HapticFeedback.heavyImpact();
                              if (currentQty == 0) {
                                cart.addToCart(
                                  widget.product, 
                                  quantity: quantity, 
                                  weight: selectedWeight,
                                  isTemperingRequested: isTemperingRequested,
                                  chefNote: isTemperingRequested ? _chefNoteController.text : null,
                                );
                              }
                              AppNavigator.push(context, const CheckoutPage());
                            },
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: isOut ? Colors.grey : const Color(0xFF18453B),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: isOut ? [] : [BoxShadow(color: const Color(0xFF18453B).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isOut ? 'NOT AVAILABLE' : 'BUY NOW', 
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // DYNAMIC ADD / QUANTITY BUTTON
                          Expanded(
                            child: (currentQty == 0 || isOut) ? 
                              GestureDetector(
                                onTap: isOut ? null : () {
                                  HapticFeedback.mediumImpact();
                                  cart.addToCart(
                                    widget.product, 
                                    quantity: quantity, 
                                    weight: selectedWeight,
                                    isTemperingRequested: isTemperingRequested,
                                    chefNote: isTemperingRequested ? _chefNoteController.text : null,
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: isOut 
                                      ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
                                      : const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFE5C76B)]),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: isOut ? [] : [BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    isOut ? 'OUT OF STOCK' : 'ADD TO CART', 
                                    style: TextStyle(color: isOut ? Colors.grey.shade700 : const Color(0xFF18453B), fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11)
                                  ),
                                ),
                              ) : 
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: const Color(0xFF18453B), width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        final item = cart.items.firstWhere((i) => i.product.name == widget.product.name && i.weight == selectedWeight);
                                        cart.updateQuantity(item, -1);
                                      }, 
                                      icon: const Icon(Icons.remove, size: 20, color: Color(0xFF18453B))
                                    ),
                                    Text('$currentQty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF18453B))),
                                    IconButton(
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        final item = cart.items.firstWhere((i) => i.product.name == widget.product.name && i.weight == selectedWeight);
                                        cart.updateQuantity(item, 1);
                                      }, 
                                      icon: const Icon(Icons.add, size: 20, color: Color(0xFF18453B))
                                    ),
                                  ],
                                ),
                              ),
                          ),
                        ],
                      );
                    },
                  ),

                  if (recommendations.isNotEmpty) ...[
                    const SizedBox(height: 45),
                    const Text('EXQUISITE PAIRINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final p = recommendations[index];
                          return GestureDetector(
                            onTap: () => AppNavigator.push(context, ProductDetailPage(product: p)),
                            child: Container(
                              width: 250,
                              margin: const EdgeInsets.only(right: 15),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(p.image, width: 80, height: 80, fit: BoxFit.cover),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Text(p.defaultPrice, style: const TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  if (widget.product.sommelierPairings.isNotEmpty) ...[
                    const SizedBox(height: 45),
                    const Text('THE SOMMELIER GUIDE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                    const SizedBox(height: 20),
                    ...widget.product.sommelierPairings.map<Widget>((pairing) => _buildSommelierCard(pairing)),
                  ],

                  const SizedBox(height: 40),
                  const Text('INGREDIENTS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 10,
                    children: widget.product.ingredients.map<Widget>((i) => Chip(
                      label: Text(i, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: const Color(0xFF18453B).withOpacity(0.1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )).toList(),
                  ),

                  const SizedBox(height: 45),
                  const Text('BEHIND THE JAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFF18453B).withOpacity(0.05)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      children: [
                        _BehindItem(icon: Icons.place_rounded, title: 'Origin', value: widget.product.origin),
                        const Divider(height: 40),
                        _BehindItem(icon: Icons.auto_awesome, title: 'Process', value: widget.product.preparationMethod),
                        const Divider(height: 40),
                        _BehindItem(icon: Icons.inventory_2_outlined, title: 'Storage', value: widget.product.storageInstructions),
                        const Divider(height: 40),
                        _BehindItem(icon: Icons.restaurant_menu_rounded, title: 'Serving', value: widget.product.servingSuggestion),
                        const Divider(height: 40),
                        _BehindItem(icon: Icons.hourglass_bottom_rounded, title: 'Shelf Life', value: widget.product.shelfLife),
                      ],
                    ),
                  ),
                  const SizedBox(height: 45),
                  _buildReviewHeader(),
                  const SizedBox(height: 20),
                  _buildReviewsList(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('USER REVIEWS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
        TextButton.icon(
          onPressed: _showReviewDialog,
          icon: const Icon(Icons.rate_review_outlined, size: 16, color: Color(0xFFD4AF37)),
          label: const Text('WRITE A REVIEW', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    if (widget.product.reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
        ),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 32).animate(onPlay: (c) => c.repeat()).shimmer(),
            const SizedBox(height: 20),
            Text('Awaiting Your Royalty', style: GoogleFonts.philosopher(color: const Color(0xFF18453B), fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Be the first to leave a mark on our heritage.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 11, letterSpacing: 0.5)),
          ],
        ),
      );
    }

    return Column(
      children: widget.product.reviews.take(10).toList().asMap().entries.map<Widget>((entry) {
        return RoyalReviewCard(review: entry.value, index: entry.key);
      }).toList(),
    );
  }

  void _showSecretIngredient() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF8E8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Text('THE SECRET BEHIND THE JAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 25),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(widget.product.secretIngredient.image, height: 250, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 30),
                    Text(widget.product.secretIngredient!.name, textAlign: TextAlign.center, style: GoogleFonts.philosopher(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF18453B))),
                    const SizedBox(height: 15),
                    Text(
                      widget.product.secretIngredient!.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: const Color(0xFF2D1B12).withOpacity(0.7), height: 1.8),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: const Color(0xFF18453B).withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: Color(0xFF18453B)),
                          SizedBox(width: 15),
                          Expanded(child: Text('This ingredient is sourced personally by our family for purity.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF18453B)))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChefCustomization() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.soup_kitchen_rounded, color: Color(0xFFD4AF37), size: 24),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('REQUEST THE CHEF', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF18453B), letterSpacing: 1)),
                    Text('Freshly tempered before packing', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Switch(
                value: isTemperingRequested, 
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    isTemperingRequested = v;
                    if (!v) _chefNoteController.clear();
                  });
                },
                activeTrackColor: const Color(0xFF18453B).withValues(alpha: 0.2),
                activeThumbColor: const Color(0xFF18453B),
              ),
            ],
          ),
          if (isTemperingRequested) ...[
            const Padding(
              padding: EdgeInsets.only(top: 15),
              child: Text(
                '• Added fresh curry leaves, mustard seeds & dry chillies.',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _chefNoteController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Add a note (e.g., Extra spicy, less salt...)',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF18453B), size: 20),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade100),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF18453B), width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSommelierCard(SommelierPairing pairing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(pairing.icon, color: const Color(0xFFD4AF37), size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pairing.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(pairing.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog() {
    int selectedStars = 5;
    final TextEditingController reviewController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFFFF8E8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: const Text('Rate this Flavor', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  onPressed: () => setDialogState(() => selectedStars = i + 1),
                  icon: Icon(Icons.star_rounded, size: 32, color: i < selectedStars ? const Color(0xFFD4AF37) : Colors.grey.shade300),
                )),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the taste...',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                final bool success = await CloudFunctionManager().submitReview(
                  productId: widget.product.name,
                  userName: user?.displayName ?? 'Anonymous',
                  rating: selectedStars.toDouble(),
                  comment: reviewController.text,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success ? 'Review submitted for royal approval!' : 'Failed to submit review.'),
                    backgroundColor: const Color(0xFF18453B),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF18453B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }

}

class RoyalReviewCard extends StatelessWidget {
  final Review review;
  final int index;
  const RoyalReviewCard({super.key, required this.review, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. The Main Luxury Card
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(50),
                bottomLeft: Radius.circular(50),
                topLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF18453B).withOpacity(0.06),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                )
              ],
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: List.generate(5, (i) => Icon(
                        Icons.star_rounded, 
                        size: 14, 
                        color: i < review.rating ? const Color(0xFFD4AF37) : Colors.grey.shade100
                      )),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18453B).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('VERIFIED', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Color(0xFF18453B), letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  review.comment, 
                  style: GoogleFonts.poppins(
                    fontSize: 14, 
                    fontStyle: FontStyle.italic, 
                    color: const Color(0xFF2D1B12), 
                    height: 1.7, 
                    fontWeight: FontWeight.w400
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF18453B), Color(0xFF276357)]),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        review.userName.isEmpty ? '?' : review.userName[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName.toUpperCase(), 
                          style: GoogleFonts.philosopher(fontWeight: FontWeight.w900, fontSize: 12, color: const Color(0xFF18453B), letterSpacing: 0.5)
                        ),
                        const Text(
                          'HONORED GUEST',
                          style: TextStyle(fontSize: 7, color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 2. The Floating Badge
          Positioned(
            left: -8, top: -8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
              child: const Icon(Icons.format_quote_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 150).ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _WeightOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _WeightOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18453B) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isSelected ? const Color(0xFF18453B) : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _BehindItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _BehindItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF18453B).withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D1B12), height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
