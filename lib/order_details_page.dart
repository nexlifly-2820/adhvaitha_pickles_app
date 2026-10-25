import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'batch_genealogy_page.dart';
import 'cart_manager.dart';
import 'product_manager.dart';
import 'user_manager.dart';
import 'navigation_util.dart';
import 'main.dart';

class OrderDetailsPage extends StatefulWidget {
  final Order order;
  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  int _userRating = 0;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    const primaryColor = Color(0xFF0F382C);
    const accentGold = Color(0xFFD4AF37);
    const bgLight = Color(0xFFFFF8E8);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ORDER DETAILS',
          style: GoogleFonts.philosopher(
            fontWeight: FontWeight.w900,
            color: primaryColor,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: primaryColor),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderIdCard(order, primaryColor, accentGold),
            const SizedBox(height: 24),

            _buildSectionHeader('ORDER STATUS'),
            const SizedBox(height: 10),
            _buildStatusTimelineCard(order, primaryColor),
            const SizedBox(height: 16),

            _buildCourierTrackingCard(order, primaryColor),
            const SizedBox(height: 24),

            _buildSectionHeader('ITEMS ORDERED (${order.items.length})'),
            const SizedBox(height: 10),
            ...order.items.map((item) => _buildItemCard(item, primaryColor)),
            const SizedBox(height: 24),

            _buildSectionHeader('CARE & SHELF LIFE'),
            const SizedBox(height: 10),
            _buildCareAndShelfLifeCard(primaryColor),
            const SizedBox(height: 24),

            _buildSectionHeader('DELIVERY ADDRESS'),
            const SizedBox(height: 10),
            _buildDeliveryAddressCard(order, primaryColor),
            const SizedBox(height: 24),

            _buildSectionHeader('PAYMENT & BILL'),
            const SizedBox(height: 10),
            _buildPaymentAndBillCard(order, primaryColor),
            const SizedBox(height: 24),

            _buildSectionHeader('BATCH HERITAGE'),
            const SizedBox(height: 10),
            _buildBatchHeritageCard(order, primaryColor, accentGold),
            const SizedBox(height: 24),

            if (order.items.isNotEmpty) ...[
              _buildRatingCard(order.items.first.product.name, primaryColor),
              const SizedBox(height: 24),
            ],

            _buildPairsWellWithSection(primaryColor),
            const SizedBox(height: 28),

            _buildBottomActionButtons(context, primaryColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderIdCard(Order order, Color primaryColor, Color accentGold) {
    final formattedDate = DateFormat('dd MMM yyyy, h:mm a').format(order.date);
    final expectedDeliveryDate = order.estimatedDelivery != null
        ? DateFormat('E, dd MMM').format(order.estimatedDelivery!)
        : 'Fri, 09 Oct';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER ID',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white60,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        order.id,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: accentGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: order.id));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order ID copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Icon(Icons.copy_rounded, color: accentGold, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accentGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Placed on', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
                  Text(formattedDate, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Expected delivery', style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60)),
                  Text(expectedDeliveryDate, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimelineCard(Order order, Color primaryColor) {
    const statuses = ['Placed', 'Packed', 'Shipped', 'Delivered'];
    int currentIndex = statuses.indexOf(order.status);
    if (currentIndex == -1) currentIndex = 0;

    final datePlaced = DateFormat('dd MMM, h:mm a').format(order.date);
    final expectedDelivery = order.estimatedDelivery != null
        ? DateFormat('E, dd MMM').format(order.estimatedDelivery!)
        : 'Fri, 09 Oct';

    final stepSubtitles = [
      datePlaced,
      'Freshly packed in our kitchen',
      'Expected 07 Oct',
      'Expected by $expectedDelivery',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(4, (index) {
          final isDone = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final isLast = index == 3;

          Color dotColor = Colors.grey.shade300;
          if (isDone) dotColor = const Color(0xFF16A34A);
          if (isCurrent && order.status != 'Delivered') dotColor = const Color(0xFFD4AF37);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? dotColor : Colors.white,
                      border: Border.all(color: dotColor, width: 2),
                    ),
                    child: isDone
                        ? Icon(
                            index < currentIndex ? Icons.check_rounded : Icons.circle_rounded,
                            size: 14,
                            color: isDone && index < currentIndex ? Colors.white : dotColor,
                          )
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 36,
                      color: index < currentIndex ? const Color(0xFF16A34A) : Colors.grey.shade200,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order ${statuses[index]}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                          color: isDone ? primaryColor : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stepSubtitles[index],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCourierTrackingCard(Order order, Color primaryColor) {
    final hasTracking = order.trackingId != null && order.trackingId!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F9F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCECE4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE2F0E8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_shipping_outlined, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Courier tracking',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  hasTracking
                      ? '${order.courierName ?? 'Courier'}: ${order.trackingId}'
                      : 'Tracking ID will appear once shipped',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(hasTracking
                      ? 'Tracking package ${order.trackingId}...'
                      : 'Package is being packed. Tracking will update soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'Track ›',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(CartItem item, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildProductImage(item.product.image),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.product.category.isNotEmpty ? item.product.category : 'Pickles'} · ${item.weight} · Qty ${item.quantity}',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    CartManager().addToCart(item.product, quantity: item.quantity, weight: item.weight);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.product.name} added to cart!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(
                    'Buy again',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(item.product.getRawPriceForWeight(item.weight) * item.quantity).toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareAndShelfLifeCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Best before',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '6 months',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _careInstructionItem(Icons.inventory_2_outlined, 'Transfer to a dry glass or ceramic jar'),
          const SizedBox(height: 12),
          _careInstructionItem(Icons.soup_kitchen_outlined, 'Always use a dry spoon — no water or moisture'),
          const SizedBox(height: 12),
          _careInstructionItem(Icons.wb_sunny_outlined, 'Keep away from sunlight; oil layer on top keeps it fresh'),
        ],
      ),
    );
  }

  Widget _careInstructionItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressCard(Order order, Color primaryColor) {
    final userName = UserManager().userName.isNotEmpty ? UserManager().userName : 'Valued Customer';
    final userPhone = UserManager().email.isNotEmpty ? UserManager().email : '+91 9876543210';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE2F0E8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on_outlined, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$userName · Home',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.shippingAddress.isNotEmpty
                      ? order.shippingAddress
                      : 'Sri Venkateshwara Nilayam, HSR Layout, Bengaluru, Karnataka – 560102',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  userPhone,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAndBillCard(Order order, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5C778)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFD4AF37), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.paymentMethod,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'Keep ₹${order.total.toStringAsFixed(0)} ready at delivery',
                        style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _billRow('Items subtotal', '₹${order.subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: 10),
          _billRow('Delivery charges', '₹${order.deliveryFee.toStringAsFixed(0)}'),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 10),
            _billRow('Coupon Discount', '- ₹${order.discountAmount.toStringAsFixed(0)}', isDiscount: true),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
              Text(
                '₹${order.total.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Free delivery on orders above ₹499',
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Downloading Invoice PDF...'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: Icon(Icons.download_rounded, size: 18, color: primaryColor),
              label: Text(
                'Download Invoice',
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryColor, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String val, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
        Text(
          val,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDiscount ? const Color(0xFF16A34A) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBatchHeritageCard(Order order, Color primaryColor, Color accentGold) {
    final batchId = order.batchId.isNotEmpty ? order.batchId : 'BCH-2026106';
    final preparedDate = order.preparationDate != null
        ? DateFormat('dd MMM yyyy').format(order.preparationDate!)
        : '05 Oct 2026';
    final spiceOrigin = order.spiceOrigin.isNotEmpty ? order.spiceOrigin : 'Guntur';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _metricBox('BATCH ID', batchId, primaryColor)),
              const SizedBox(width: 8),
              Expanded(child: _metricBox('PREPARED', preparedDate, primaryColor)),
              const SizedBox(width: 8),
              Expanded(child: _metricBox('SPICE ORIGIN', spiceOrigin, primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                AppNavigator.push(context, BatchGenealogyPage(order: order));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGold,
                foregroundColor: primaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'VIEW BATCH GENEALOGY →',
                style: GoogleFonts.philosopher(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(String productName, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'How was your $productName?',
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() => _userRating = starNumber);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you for rating $starNumber stars!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    starNumber <= _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFD4AF37),
                    size: 28,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'You can rate & review after delivery',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPairsWellWithSection(Color primaryColor) {
    final samplePairs = ProductManager().products.take(4).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PAIRS WELL WITH',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.2),
            ),
            GestureDetector(
              onTap: () {
                final mainScreen = MainScreen.of(context);
                Navigator.popUntil(context, (route) => route.isFirst);
                mainScreen?.setIndex(1);
              },
              child: Text(
                'See all',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: samplePairs.length,
            itemBuilder: (context, index) {
              final p = samplePairs[index];
              return Container(
                width: 125,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xFFFFF8E8),
                          child: _buildProductImage(p.image),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.name,
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${p.getRawPriceForWeight('500g').toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            CartManager().addToCart(p);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p.name} added to cart!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons(BuildContext context, Color primaryColor) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => _showHelpDialog(context),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: Text('Need Help?', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => _showCancelDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('Cancel Order', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You can cancel until your order is packed',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProductImage(String path) {
    if (path.isEmpty) {
      return Container(width: 50, height: 50, color: Colors.grey.shade50, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20));
    }
    if (path.startsWith('http')) {
      return Image.network(
        path, width: 50, height: 50, fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey.shade50, child: const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 20)),
      );
    }
    String assetPath = path;
    if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/$path';
    }
    return Image.asset(
      assetPath, width: 50, height: 50, fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Container(width: 50, height: 50, color: Colors.grey.shade50, child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 20)),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Royal Support', style: GoogleFonts.philosopher(fontWeight: FontWeight.bold)),
        content: Text('Our support team is available 24/7 to assist you with your order.', style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('Close', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connecting to Royal Support Chat...'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F382C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Chat Now', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cancel Order?', style: GoogleFonts.philosopher(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel this order?', style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('Keep Order', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order cancellation requested'), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Yes, Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
