import 'package:flutter/material.dart';
import 'models.dart';
import 'cart_manager.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  String selectedWeight = '500g';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: widget.product.color.withOpacity(0.2),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.product.name,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.product.color.withOpacity(0.1),
                  ),
                  child: Image.asset(
                    widget.product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported_outlined, size: 100, color: Colors.grey),
                      );
                    },
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
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50)),
                        ),
                      ),
                      Text(
                        widget.product.price,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFD35400)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // SPICE LEVEL METER
                  const Text('Spice Level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      bool isActive = index < widget.product.spiceLevel;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.whatshot_rounded,
                          color: isActive ? Colors.red : Colors.grey.shade200,
                          size: 28,
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // PERFECT PAIRINGS
                  const Text('Best Paired With', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: widget.product.pairings.map((pair) {
                      return Chip(
                        label: Text(pair),
                        backgroundColor: Colors.orange.shade50,
                        labelStyle: const TextStyle(color: Color(0xFFD35400), fontWeight: FontWeight.bold),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        avatar: const Icon(Icons.restaurant_menu, size: 16, color: Color(0xFFD35400)),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                  const Text('Select Weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: ['250g', '500g', '1kg'].map((weight) {
                      bool isSelected = selectedWeight == weight;
                      return GestureDetector(
                        onTap: () => setState(() => selectedWeight = weight),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(weight, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text('About this Product', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'Handcrafted with love using traditional recipes. Our ${widget.product.name} ensures authentic taste and premium quality ingredients.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.6),
                  ),

                  const SizedBox(height: 32),

                  // CUSTOMER REVIEWS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${widget.product.reviews.length} Reviews',
                          style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (widget.product.reviews.isEmpty)
                    const Text('No reviews yet. Be the first to review!')
                  else
                    Column(
                      children: widget.product.reviews.map((review) => _ReviewCard(review: review)).toList(),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  IconButton(onPressed: () => setState(() { if(quantity > 1) quantity--; }), icon: const Icon(Icons.remove)),
                  Text('$quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  CartManager().addToCart(widget.product, quantity: quantity, weight: selectedWeight);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product.name} added to cart!'),
                      backgroundColor: const Color(0xFFD35400),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD35400),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('ADD TO CART', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(review.date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                size: 14,
                color: index < review.rating ? Colors.amber : Colors.grey.shade300,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}
