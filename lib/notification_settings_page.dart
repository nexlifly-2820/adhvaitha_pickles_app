import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool pushEnabled = true;
  bool orderUpdates = true;
  bool offersEnabled = false;
  bool newsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(title: const Text('NOTIFICATIONS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NOTIFICATION PREFERENCES', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12, color: Color(0xFF18453B))),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
              child: Column(
                children: [
                  _buildSwitch('Enable Push Notifications', 'Get instant alerts on your device', pushEnabled, (v) => setState(() => pushEnabled = v)),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildSwitch('Order Updates', 'Track your delivery status', orderUpdates, (v) => setState(() => orderUpdates = v)),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildSwitch('Exclusive Offers', 'New deals and festive discounts', offersEnabled, (v) => setState(() => offersEnabled = v)),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildSwitch('New Product Alerts', 'Know when fresh batches arrive', newsEnabled, (v) => setState(() => newsEnabled = v)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String title, String sub, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      value: val,
      onChanged: onChanged,
      activeColor: const Color(0xFF18453B),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
    );
  }
}
