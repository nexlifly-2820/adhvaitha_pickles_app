import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountDeletionPage extends StatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  State<AccountDeletionPage> createState() => _AccountDeletionPageState();
}

class _AccountDeletionPageState extends State<AccountDeletionPage> {
  bool _confirmed = false;
  final TextEditingController _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      appBar: AppBar(
        title: Text('DELETE ACCOUNT', style: GoogleFonts.philosopher(fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
                  const SizedBox(height: 20),
                  const Text(
                    'WE ARE SORRY TO SEE YOU GO',
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Deleting your account is permanent. All your royal coins, order history, and saved addresses will be removed from our records instantly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade900, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text('TELL US WHY (OPTIONAL)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 15),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your feedback...',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Checkbox(
                  value: _confirmed, 
                  onChanged: (v) => setState(() => _confirmed = v!),
                  activeColor: const Color(0xFF18453B),
                ),
                const Expanded(
                  child: Text(
                    'I understand that this action is irreversible and my data will be permanently deleted.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: !_confirmed ? null : () {
                HapticFeedback.heavyImpact();
                _showFinalConfirmation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text('DELETE MY ROYAL ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('KEEP MY ACCOUNT', style: TextStyle(color: Color(0xFF18453B), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinalConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text('Last Step', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you absolutely sure? This will erase your 450 Royal Coins forever.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close page
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion request received.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('YES, DELETE'),
          ),
        ],
      ),
    );
  }
}
