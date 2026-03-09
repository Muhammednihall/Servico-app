import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final UserService _userService = UserService();
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _role;

  double? _latitude;
  double? _longitude;
  bool _isLocating = false;

  String? _selectedRegion;
  List<Map<String, String>> _allRegions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf6f6f8);

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadCitiesAndRegion(String? currentRegionKey) async {
    try {
      final snapshot = await _firestore.collection('Locations').get();
      if (mounted) {
        List<Map<String, String>> allRegionsList = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['regions'] != null) {
            final regionsMap = data['regions'] as Map<String, dynamic>;
            regionsMap.forEach((key, value) {
              final rawName = value['regionName'] as String? ?? key;
              final formattedName = rawName
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((word) => word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                      : '')
                  .join(' ');
              
              allRegionsList.add({
                'id': key,
                'name': formattedName,
              });
            });
          }
        }
        
        // Sort regions alphabetically for better UX
        allRegionsList.sort((a, b) => a['name']!.compareTo(b['name']!));

        setState(() {
          _allRegions = allRegionsList;
          if (currentRegionKey != null && currentRegionKey.isNotEmpty && allRegionsList.any((r) => r['id'] == currentRegionKey)) {
            _selectedRegion = currentRegionKey;
          }
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userService.getUserProfile();
      if (profile != null) {
        final role = profile['role'];
        if (role == 'worker') {
            await _loadCitiesAndRegion(profile['serviceArea']);
        }
        setState(() {
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _addressController.text = profile['address'] ?? '';
          _role = role;
          _latitude = (profile['latitude'] as num?)?.toDouble() ?? (profile['lat'] as num?)?.toDouble();
          _longitude = (profile['longitude'] as num?)?.toDouble() ?? (profile['lng'] as num?)?.toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully'), backgroundColor: Color(0xFF10b981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_role == 'worker' && _selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a region'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _userService.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _role == 'customer' ? _addressController.text.trim() : null,
        serviceArea: _role == 'worker' ? _selectedRegion : null,
        latitude: _latitude,
        longitude: _longitude,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Color(0xFF1e293b), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1e293b), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2463eb)),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: _backgroundLight,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(Icons.person, size: 60, color: Color(0xFF94a3b8)),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInputField(
                      label: 'Full Name',
                      controller: _nameController,
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildInputField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Please enter your phone number' : null,
                    ),
                    if (_role == 'customer') ...[
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'Address',
                        controller: _addressController,
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                        validator: (v) => v!.isEmpty ? 'Please enter your address' : null,
                      ),
                    ] else if (_role == 'worker') ...[
                      const SizedBox(height: 20),
                      _buildRegionDropdown(),
                      const SizedBox(height: 24),
                      _buildLocationPicker(),
                    ],
                    const SizedBox(height: 40),
                    const Text(
                      'Tip: Make sure your contact information is up to date so service providers can reach you easily.',
                      style: TextStyle(color: Color(0xFF64748b), fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1e293b),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _primaryColor, size: 20),
            filled: true,
            fillColor: _backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRegionDropdown() {
    final isEnabled = _allRegions.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                'Region',
                style: TextStyle(
                  color: Color(0xFF1e293b),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        DropdownMenu<String>(
          enabled: isEnabled,
          initialSelection: _selectedRegion,
          onSelected: (String? value) {
            setState(() {
              _selectedRegion = value;
            });
          },
          dropdownMenuEntries: _allRegions.map((region) {
            return DropdownMenuEntry(value: region['id']!, label: region['name']!);
          }).toList(),
          width: double.infinity,
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            prefixIconColor: isEnabled
                ? _primaryColor
                : Colors.grey.shade400,
            filled: true,
            fillColor: isEnabled ? _backgroundLight : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          leadingIcon: Icon(
            Icons.location_on_outlined,
            color: isEnabled ? _primaryColor : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Precise Location',
          style: TextStyle(
            color: Color(0xFF1e293b),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _backgroundLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on, color: _primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _latitude != null && _longitude != null
                          ? 'Coordinates Saved'
                          : 'Location Not Set',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        fontSize: 15,
                      ),
                    ),
                    if (_latitude != null && _longitude != null)
                      Text(
                        '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      )
                    else
                      Text(
                        'Set location for distance calculation',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isLocating ? null : _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLocating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Set Current', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
