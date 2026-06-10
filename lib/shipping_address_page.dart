import 'package:flutter/material.dart';
import 'checkout_page.dart'; // To reuse some logic or styles if needed

class ShippingAddressPage extends StatefulWidget {
  const ShippingAddressPage({super.key});

  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  // Mock data for saved addresses
  final List<Map<String, String>> _addresses = [
    {
      'title': 'Home',
      'address': 'Plot No. 42, Hitech City, Hyderabad, Telangana - 500081',
      'isDefault': 'true',
    },
    {
      'title': 'Office',
      'address': 'Madhapur Road, Jubilee Hills, Hyderabad, Telangana - 500033',
      'isDefault': 'false',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('SHIPPING ADDRESSES', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saved Addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutPage())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add New'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFD35400)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ..._addresses.map((addr) => _AddressCard(
                  title: addr['title']!,
                  address: addr['address']!,
                  isDefault: addr['isDefault'] == 'true',
                )),
            const SizedBox(height: 30),
            
            // Innovative "Quick Add" using GPS
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2C3E50), const Color(0xFF1A1A1A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2C3E50).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.location_searching_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    'Add New Address via GPS',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use your current location for faster delivery setup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutPage())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD35400),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('DETECT CURRENT LOCATION', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String title;
  final String address;
  final bool isDefault;

  const _AddressCard({required this.title, required this.address, required this.isDefault});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDefault ? const Color(0xFFD35400) : Colors.grey.shade100, width: isDefault ? 2 : 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD35400).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(title == 'Home' ? Icons.home_rounded : Icons.work_rounded, color: const Color(0xFFD35400), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFD35400), borderRadius: BorderRadius.circular(6)),
                        child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildActionButton('Edit', Icons.edit_outlined, () {}),
                    const SizedBox(width: 20),
                    _buildActionButton('Delete', Icons.delete_outline_rounded, () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
