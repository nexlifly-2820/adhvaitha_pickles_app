import 'package:flutter/material.dart';

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

  final List<SavedAddress> _addresses = [
    SavedAddress(id: '1', title: 'Home', fullAddress: 'Plot 42, Hitech City, Hyderabad, Telangana - 500081', isDefault: true),
    SavedAddress(id: '2', title: 'Office', fullAddress: 'Madhapur Road, Jubilee Hills, Hyderabad, Telangana - 500033', isDefault: false),
  ];

  List<SavedAddress> get addresses => _addresses;

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
