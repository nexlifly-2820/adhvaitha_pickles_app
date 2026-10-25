import 'package:flutter/material.dart';
import 'api_service.dart';
import 'user_manager.dart';

class SavedAddress {
  final String id;
  final String title;
  final String fullName;
  final String phone;
  final String secondaryPhone;
  final String pincode;
  final String city;
  final String state;
  final String houseNo;
  final String area;
  final String addressType;
  final bool isDefault;
  final String fullAddress;

  SavedAddress({
    required this.id,
    required this.title,
    this.fullName = '',
    this.phone = '',
    this.secondaryPhone = '',
    this.pincode = '',
    this.city = '',
    this.state = '',
    this.houseNo = '',
    this.area = '',
    this.addressType = 'Home',
    this.isDefault = false,
    required this.fullAddress,
  });
}

class AddressManager extends ChangeNotifier {
  static final AddressManager _instance = AddressManager._internal();
  factory AddressManager() => _instance;
  AddressManager._internal();

  final List<SavedAddress> _addresses = [];
  List<SavedAddress> get addresses => _addresses;

  Future<void> fetchAddresses() async {
    final uid = UserManager().currentUserId;
    
    try {
      final rawAddresses = await ApiService.getUserAddresses(uid);
      if (rawAddresses.isNotEmpty) {
        _addresses.clear();
        for (var data in rawAddresses) {
          _addresses.add(SavedAddress(
            id: data['id']?.toString() ?? DateTime.now().toString(),
            title: data['title']?.toString() ?? 'Address',
            fullName: data['full_name']?.toString() ?? data['fullName']?.toString() ?? '',
            phone: data['phone']?.toString() ?? '',
            secondaryPhone: data['secondary_phone']?.toString() ?? data['secondaryPhone']?.toString() ?? '',
            pincode: data['pincode']?.toString() ?? '',
            city: data['city']?.toString() ?? '',
            state: data['state']?.toString() ?? '',
            houseNo: data['house_no']?.toString() ?? data['houseNo']?.toString() ?? '',
            area: data['area']?.toString() ?? '',
            addressType: data['address_type']?.toString() ?? data['addressType']?.toString() ?? 'Home',
            isDefault: data['isDefault'] == true || data['is_default'] == true,
            fullAddress: data['fullAddress']?.toString() ?? data['full_address']?.toString() ?? '',
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

  void addAddressObject(SavedAddress address) {
    _addresses.add(address);
    notifyListeners();
  }

  void removeAddress(String id) {
    _addresses.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void setDefault(String id) {
    for (int i = 0; i < _addresses.length; i++) {
      final a = _addresses[i];
      _addresses[i] = SavedAddress(
        id: a.id,
        title: a.title,
        fullName: a.fullName,
        phone: a.phone,
        secondaryPhone: a.secondaryPhone,
        pincode: a.pincode,
        city: a.city,
        state: a.state,
        houseNo: a.houseNo,
        area: a.area,
        addressType: a.addressType,
        fullAddress: a.fullAddress,
        isDefault: a.id == id,
      );
    }
    notifyListeners();
  }
}
