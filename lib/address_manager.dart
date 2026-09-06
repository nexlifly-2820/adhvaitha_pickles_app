import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "demo_user_123";
    
    try {
      final rawAddresses = await ApiService.getUserAddresses(uid);
      if (rawAddresses.isNotEmpty) {
        _addresses.clear();
        for (var data in rawAddresses) {
          _addresses.add(SavedAddress(
            id: data['id']?.toString() ?? DateTime.now().toString(),
            title: data['title']?.toString() ?? 'Address',
            fullAddress: data['fullAddress']?.toString() ?? data['full_address']?.toString() ?? '',
            isDefault: data['isDefault'] == true,
          ));
        }
        notifyListeners();
      }
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
