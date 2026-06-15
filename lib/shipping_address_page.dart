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
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: Text('ADDRESS BOOK', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900)),
      ),
      body: ListenableBuilder(
        listenable: AddressManager(),
        builder: (context, _) {
          final addresses = AddressManager().addresses;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) => _AddressCard(address: addresses[index]),
                ),
              ),
              _buildAddButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddAddressDialog(context);
        },
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('ADD NEW DESTINATION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF18453B),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: const Color(0xFF18453B).withOpacity(0.3),
        ),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context) {
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(color: Color(0xFFFFF8E8), borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
          padding: const EdgeInsets.all(30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 30),
              Text('NEW ADDRESS', style: GoogleFonts.philosopher(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF18453B))),
              const SizedBox(height: 30),
              _buildField('Address Title (e.g. Home, Office)', titleController),
              const SizedBox(height: 20),
              _buildField('Full Address Details', addressController, maxLines: 3),
              const Spacer(),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (titleController.text.isNotEmpty && addressController.text.isNotEmpty) {
                    setSheetState(() => isLoading = true);
                    final success = await CloudFunctionManager().saveAddress(
                      title: titleController.text, 
                      fullAddress: addressController.text
                    );
                    setSheetState(() => isLoading = false);
                    
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved to cloud!')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save address. Please try again.'), backgroundColor: Colors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF18453B),
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF18453B), strokeWidth: 2))
                  : const Text('SAVE ADDRESS', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(20),
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
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: address.isDefault ? const Color(0xFFD4AF37) : Colors.grey.shade100, width: address.isDefault ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(address.title.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18453B), letterSpacing: 2, fontSize: 12)),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Text('DEFAULT', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.bold, fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(address.fullAddress, style: TextStyle(color: Colors.grey.shade700, height: 1.6, fontSize: 14)),
          const Divider(height: 40),
          Row(
            children: [
              if (!address.isDefault)
                _ActionBtn(icon: Icons.check_circle_outline_rounded, label: 'Set Default', onTap: () {
                  HapticFeedback.lightImpact();
                  AddressManager().setDefault(address.id);
                }),
              if (!address.isDefault) const SizedBox(width: 25),
              _ActionBtn(icon: Icons.delete_outline_rounded, label: 'Remove', onTap: () {
                HapticFeedback.mediumImpact();
                AddressManager().removeAddress(address.id);
              }),
            ],
          )
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF18453B))),
        ],
      ),
    );
  }
}
