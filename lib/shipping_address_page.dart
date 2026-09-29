import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'address_manager.dart';
import 'cloud_function_manager.dart';

class ShippingAddressPage extends StatefulWidget {
  const ShippingAddressPage({super.key});

  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AddressManager().fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5E8),
      body: Stack(
        children: [
          // 1. Full-screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/addressbook_book_screen.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/images/addressbook_bg_screen.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (c, e, s) => Container(
                  color: const Color(0xFFFFF8E8),
                ),
              ),
            ),
          ),

          // 2. Main Content Area inside SafeArea
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Top Header Bar: Back Button (Left) & Centered Title / Subtitle
                _buildHeaderBar(context)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.2, end: 0),

                // Expanded Middle Body (Empty state or Saved Address list)
                Expanded(
                  child: ListenableBuilder(
                    listenable: AddressManager(),
                    builder: (context, _) {
                      final addresses = AddressManager().addresses;
                      if (addresses.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 16,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: addresses.length,
                        itemBuilder: (context, index) =>
                            _AddressCard(address: addresses[index]),
                      );
                    },
                  ),
                ),

                // Bottom "ADD NEW DESTINATION" Button
                _buildAddButton(context)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBar(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Title & Subtitle
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ADDRESS BOOK',
                style: GoogleFonts.philosopher(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D3823),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'YOUR DELIVERY ADDRESSES',
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D3823).withValues(alpha: 0.8),
                  letterSpacing: 2.2,
                ),
              ),
            ],
          ),

          // White Circular Back Button on Top Left
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: Color(0xFF0D3823),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'No Saved Addresses Yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.philosopher(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D3823),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your delivery address to enjoy\na faster and smoother checkout experience.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF5C5046),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Decorative Gold Line with Leaf Accent
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 1,
                color: const Color(0xFFC59B27).withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.eco_outlined,
                size: 16,
                color: Color(0xFF0D3823),
              ),
              const SizedBox(width: 8),
              Container(
                width: 50,
                height: 1,
                color: const Color(0xFFC59B27).withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF0D3823),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D3823).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              HapticFeedback.lightImpact();
              _showAddAddressDialog(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_location_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'ADD NEW DESTINATION',
                  style: GoogleFonts.philosopher(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext outerContext) {
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (dialogContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(dialogContext).size.height * 0.65,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8E8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'NEW ADDRESS',
                  style: GoogleFonts.philosopher(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0D3823),
                  ),
                ),
                const SizedBox(height: 24),
                _buildField('Address Title (e.g. Home, Office)', titleController),
                const SizedBox(height: 16),
                _buildField('Full Address Details', addressController, maxLines: 3),
                const Spacer(),
                Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D3823),
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (titleController.text.isNotEmpty &&
                                addressController.text.isNotEmpty) {
                              setSheetState(() => isLoading = true);
                              final messenger = ScaffoldMessenger.of(dialogContext);
                              final navigator = Navigator.of(dialogContext);
                              final success =
                                  await CloudFunctionManager().saveAddress(
                                title: titleController.text,
                                fullAddress: addressController.text,
                              );
                              setSheetState(() => isLoading = false);

                              if (!dialogContext.mounted) return;

                              if (success) {
                                navigator.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Address saved successfully!',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF0D3823),
                                  ),
                                );
                              } else {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Failed to save address. Please try again.',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'SAVE ADDRESS',
                            style: GoogleFonts.philosopher(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6D5), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2D1B12),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final SavedAddress address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D3823).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: address.isDefault
              ? const Color(0xFFD4AF37)
              : const Color(0xFFEFE6D5),
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                address.title.toUpperCase(),
                style: GoogleFonts.philosopher(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0D3823),
                  letterSpacing: 1.8,
                  fontSize: 14,
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF0D3823),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.fullAddress,
            style: GoogleFonts.poppins(
              color: const Color(0xFF5C5046),
              height: 1.5,
              fontSize: 13.5,
            ),
          ),
          const Divider(height: 28, color: Color(0xFFEFE6D5)),
          Row(
            children: [
              if (!address.isDefault)
                _ActionBtn(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Set Default',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    AddressManager().setDefault(address.id);
                  },
                ),
              if (!address.isDefault) const SizedBox(width: 20),
              _ActionBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Remove',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  AddressManager().removeAddress(address.id);
                },
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: const Color(0xFF0D3823),
            ),
          ),
        ],
      ),
    );
  }
}
