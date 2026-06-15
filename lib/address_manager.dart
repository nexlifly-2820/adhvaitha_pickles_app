import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  final String id;
  final String title;
  final String fullAddress;
  final bool isDefault;

  SavedAddress({required this.id, required this.title, required this.fullAddress, this.isDefault = false});
}

class AddressManager extends ChangeNotifier {
  static final AddressManager _instance = AddressManager._internal();
  factory AddressManager() => _instance;
  AddressManager._internal();

  final List<SavedAddress> _addresses = [];
  List<SavedAddress> get addresses => _addresses;

  Future<void> fetchAddresses() async {
    // In a real app, use auth: const uid = FirebaseAuth.instance.currentUser?.uid;
    const uid = "demo_user_123";
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .orderBy('createdAt', descending: true)
          .get();

      _addresses.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _addresses.add(SavedAddress(
          id: doc.id,
          title: data['title'] ?? 'Address',
          fullAddress: data['fullAddress'] ?? '',
          isDefault: data['isDefault'] ?? false,
        ));
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching addresses: $e');
    }
  }

  void addAddress(String title, String fullAddress) {
    _addresses.add(SavedAddress(
      id: DateTime.now().toString(),
      title: title,
      fullAddress: fullAddress,
    ));
    notifyListeners();
  }

  void removeAddress(String id) {
    _addresses.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void setDefault(String id) {
    for (int i = 0; i < _addresses.length; i++) {
      if (_addresses[i].id == id) {
        _addresses[i] = SavedAddress(id: _addresses[i].id, title: _addresses[i].title, fullAddress: _addresses[i].fullAddress, isDefault: true);
      } else {
        _addresses[i] = SavedAddress(id: _addresses[i].id, title: _addresses[i].title, fullAddress: _addresses[i].fullAddress, isDefault: false);
      }
    }
    notifyListeners();
  }
}
