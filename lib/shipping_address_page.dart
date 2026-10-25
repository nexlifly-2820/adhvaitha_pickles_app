import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: _buildEmptyState(context),
                          ),
                        );
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Clean background card for text visibility
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEFE6D5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D3823).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8E7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    color: Color(0xFF0D3823),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
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
                  'Add your delivery address to enjoy a faster and smoother checkout experience.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
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
                      width: 40,
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
                      width: 40,
                      height: 1,
                      color: const Color(0xFFC59B27).withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0);
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
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final secondaryPhoneController = TextEditingController();
    final pincodeController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final houseController = TextEditingController();
    final areaController = TextEditingController();
    final titleController = TextEditingController(text: 'Home');
    String addressType = 'Home';
    bool isLoading = false;
    bool isLoadingLocation = false;

    showModalBottomSheet(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (dialogContext, setSheetState) {
          Future<void> getCurrentLocation() async {
            setSheetState(() => isLoadingLocation = true);
            try {
              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
              if (!serviceEnabled) {
                setSheetState(() => isLoadingLocation = false);
                return;
              }
              LocationPermission permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.denied) {
                permission = await Geolocator.requestPermission();
                if (permission == LocationPermission.denied) {
                  setSheetState(() => isLoadingLocation = false);
                  return;
                }
              }
              if (permission == LocationPermission.deniedForever) {
                setSheetState(() => isLoadingLocation = false);
                return;
              }
              Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
              List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
              if (placemarks.isNotEmpty) {
                Placemark place = placemarks[0];
                setSheetState(() {
                  pincodeController.text = place.postalCode ?? '';
                  cityController.text = place.locality ?? place.subAdministrativeArea ?? '';
                  stateController.text = place.administrativeArea ?? '';
                  houseController.text = place.name ?? place.street ?? '';
                  areaController.text = place.subLocality ?? place.thoroughfare ?? '';
                });
              }
            } catch (e) {
              print('Location error: $e');
            } finally {
              setSheetState(() => isLoadingLocation = false);
            }
          }

          final double keyboardHeight = MediaQuery.of(dialogContext).viewInsets.bottom;
          final double screenHeight = MediaQuery.of(dialogContext).size.height;
          final double computedMaxHeight = (screenHeight * 0.85) - keyboardHeight;
          final double maxHeight = computedMaxHeight > 250.0 ? computedMaxHeight : 250.0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: keyboardHeight,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF8E8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'ADD NEW DESTINATION',
                            style: GoogleFonts.philosopher(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0D3823),
                              letterSpacing: 0.6,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: GestureDetector(
                            onTap: isLoadingLocation ? null : getCurrentLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC8E6C9)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isLoadingLocation)
                                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)))
                                  else
                                    const Icon(Icons.my_location, size: 12, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      isLoadingLocation ? 'Locating...' : 'Use GPS',
                                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormField('Full Name', nameController, Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildFormField('Phone Number', phoneController, Icons.phone_android_rounded, keyboardType: TextInputType.phone)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildFormField('Alt Phone (Optional)', secondaryPhoneController, Icons.phone_android_rounded, required: false, keyboardType: TextInputType.phone)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildFormField('Pincode', pincodeController, Icons.pin_drop_outlined, keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildFormField('City', cityController, Icons.location_city_outlined)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFormField('State', stateController, Icons.map_outlined),
                    const SizedBox(height: 12),
                    _buildFormField('House No / Building Name', houseController, Icons.home_rounded),
                    const SizedBox(height: 12),
                    _buildFormField('Road Name / Area / Colony', areaController, Icons.edit_road_rounded),
                    const SizedBox(height: 16),
                    Text(
                      'Address Type',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0D3823)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _typeChip('Home', Icons.home_rounded, addressType, (t) {
                          setSheetState(() {
                            addressType = t;
                            titleController.text = t;
                          });
                        }),
                        const SizedBox(width: 8),
                        _typeChip('Office', Icons.work_rounded, addressType, (t) {
                          setSheetState(() {
                            addressType = t;
                            titleController.text = t;
                          });
                        }),
                        const SizedBox(width: 8),
                        _typeChip('Other', Icons.location_on_rounded, addressType, (t) {
                          setSheetState(() {
                            addressType = t;
                            titleController.text = t;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D3823),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (nameController.text.isNotEmpty &&
                                    phoneController.text.isNotEmpty &&
                                    pincodeController.text.isNotEmpty &&
                                    cityController.text.isNotEmpty &&
                                    houseController.text.isNotEmpty) {
                                  setSheetState(() => isLoading = true);
                                  final messenger = ScaffoldMessenger.of(dialogContext);
                                  final navigator = Navigator.of(dialogContext);

                                  final fullAddressStr = '${houseController.text}, ${areaController.text}, ${cityController.text}, ${stateController.text} - ${pincodeController.text}';
                                  final success = await CloudFunctionManager().saveAddress(
                                    title: titleController.text,
                                    fullAddress: fullAddressStr,
                                    fullName: nameController.text,
                                    phone: phoneController.text,
                                    secondaryPhone: secondaryPhoneController.text,
                                    pincode: pincodeController.text,
                                    city: cityController.text,
                                    state: stateController.text,
                                    houseNo: houseController.text,
                                    area: areaController.text,
                                    addressType: addressType,
                                  );
                                  setSheetState(() => isLoading = false);

                                  if (!dialogContext.mounted) return;

                                  if (success) {
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Address saved successfully!', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                        backgroundColor: const Color(0xFF0D3823),
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(content: Text('Failed to save address. Please try again.'), backgroundColor: Colors.red),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.orange),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        ),
                        child: isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'SAVE ADDRESS',
                                style: GoogleFonts.philosopher(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, IconData icon, {bool required = true, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2D1B12)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF0D3823)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEFE6D5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEFE6D5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF0D3823), width: 1.5)),
      ),
    );
  }

  Widget _typeChip(String type, IconData icon, String currentType, Function(String) onTap) {
    bool isSelected = currentType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D3823) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFF0D3823) : const Color(0xFFEFE6D5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                type,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF2D1B12)),
              ),
            ],
          ),
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
              Expanded(
                child: Text(
                  address.title.toUpperCase(),
                  style: GoogleFonts.philosopher(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0D3823),
                    letterSpacing: 1.5,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (address.isDefault) ...[
                const SizedBox(width: 8),
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
