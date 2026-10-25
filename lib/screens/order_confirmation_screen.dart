import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order_item.dart';
import '../models/order_result.dart';
import '../services/order_service.dart';
import '../utils/cloudinary.dart';
import '../widgets/order_processing_view.dart';
import '../widgets/order_placed_view.dart';
import '../cart_manager.dart';
import '../order_manager.dart';
import '../main.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String? orderId;
  final List<OrderItem> cartItems;
  final double total;
  final String shippingAddress;
  final String paymentMethod;
  final bool isDemo;
  final bool simulateError;

  const OrderConfirmationScreen({
    super.key,
    this.orderId,
    required this.cartItems,
    required this.total,
    required this.shippingAddress,
    required this.paymentMethod,
    this.isDemo = false,
    this.simulateError = false,
  });

  factory OrderConfirmationScreen.demo({
    int itemCount = 4,
    bool simulateError = false,
  }) {
    final sampleProducts = [
      const OrderItem(
        productId: '1',
        name: 'Amla Pickle',
        category: 'Pickles',
        weight: '500g',
        qty: 1,
        price: 299,
        imageUrl:
            'https://res.cloudinary.com/adhvaitha/image/upload/v1234/products/amla_pickle.png',
      ),
      const OrderItem(
        productId: '2',
        name: 'Mango Avakaya Pickle',
        category: 'Pickles',
        weight: '500g',
        qty: 1,
        price: 349,
        imageUrl:
            'https://res.cloudinary.com/adhvaitha/image/upload/v1234/products/mango_avakaya.png',
      ),
      const OrderItem(
        productId: '3',
        name: 'Gulab Jamun',
        category: 'Sweets',
        weight: '500g',
        qty: 1,
        price: 249,
        imageUrl:
            'https://res.cloudinary.com/adhvaitha/image/upload/v1234/products/gulab_jamun.png',
      ),
      const OrderItem(
        productId: '4',
        name: 'Spicy Mixture',
        category: 'Snacks',
        weight: '250g',
        qty: 1,
        price: 149,
        imageUrl:
            'https://res.cloudinary.com/adhvaitha/image/upload/v1234/products/spicy_mixture.png',
      ),
      const OrderItem(
        productId: '5',
        name: 'Kandi Podi',
        category: 'Podis',
        weight: '250g',
        qty: 1,
        price: 179,
        imageUrl:
            'https://res.cloudinary.com/adhvaitha/image/upload/v1234/products/kandi_podi.png',
      ),
      const OrderItem(
        productId: '6',
        name: 'Sunnundalu',
        category: 'Sweets',
        weight: '500g',
        qty: 1,
        price: 299,
        imageUrl:
            'https://res.cloudinary.com/adhvaitha/image/upload/v1234/products/sunnundalu.png',
      ),
    ];

    final selectedItems =
        sampleProducts.take(math.min(itemCount, sampleProducts.length)).toList();
    final double calcTotal =
        selectedItems.fold(0.0, (sum, i) => sum + (i.price * i.qty));

    return OrderConfirmationScreen(
      cartItems: selectedItems,
      total: calcTotal,
      shippingAddress: 'Main Road, Srikakulam - 532404',
      paymentMethod: 'UPI (Google Pay / PhonePe)',
      isDemo: true,
      simulateError: simulateError,
    );
  }

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final OrderService _orderService = OrderService();

  bool _isApiLoading = true;
  bool _animFinished = false;
  OrderResult? _orderResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final fallingCount = math.min(widget.cartItems.length, 4);
    final totalDurationMs = 300 + (fallingCount * 750) + 1400;

    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDurationMs),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _animFinished = true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startFlow();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _startFlow() async {
    await precacheOrderImages(
      context,
      widget.cartItems.map((i) => i.imageUrl).toList(),
    );

    if (!mounted) return;

    if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
      _animController.value = 1.0;
      _animFinished = true;
    } else {
      _animController.forward(from: 0.0);
    }

    _executeOrderApi();
  }

  Future<void> _executeOrderApi() async {
    setState(() {
      _isApiLoading = true;
      _errorMessage = null;
    });

    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      setState(() {
        _orderResult = OrderResult(
          status: 'success',
          orderId: widget.orderId!,
          deliveryDate: 'Fri, 9 Oct',
          total: widget.total,
          items: widget.cartItems,
        );
        _isApiLoading = false;
      });
      return;
    }

    try {
      final result = await _orderService.placeOrder(
        items: widget.cartItems,
        total: widget.total,
        shippingAddress: widget.shippingAddress,
        paymentMethod: widget.paymentMethod,
        simulateError: widget.simulateError,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() {
          _orderResult = result;
          _isApiLoading = false;
        });

        CartManager().clearCart();
        OrderManager().fetchOrders();
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Couldn\'t place your order';
          _isApiLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isApiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildCurrentPhase(),
        ),
      ),
    );
  }

  Widget _buildCurrentPhase() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_animFinished && !_isApiLoading && _orderResult != null) {
      return OrderPlacedView(
        key: const ValueKey('OrderPlacedView'),
        orderResult: _orderResult!,
        onTrackOrder: () {
          final mainScreen = MainScreen.of(context);
          Navigator.popUntil(context, (route) => route.isFirst);
          mainScreen?.setIndex(3);
        },
        onContinueShopping: () {
          final mainScreen = MainScreen.of(context);
          Navigator.popUntil(context, (route) => route.isFirst);
          mainScreen?.setIndex(0);
        },
      );
    }

    return OrderProcessingView(
      key: const ValueKey('OrderProcessingView'),
      items: widget.cartItems,
      animationController: _animController,
      isApiLoading: _isApiLoading,
    );
  }

  Widget _buildErrorView() {
    return Center(
      key: const ValueKey('ErrorView'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFFFEDD5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Color(0xFFC2410C),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Couldn\'t place your order',
              style: GoogleFonts.baloo2(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF7C2D12),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Network error. Please try again.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: const Color(0xFF6B4A36),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  _executeOrderApi();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2410C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Retry Order',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Back to Cart',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7C2D12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
