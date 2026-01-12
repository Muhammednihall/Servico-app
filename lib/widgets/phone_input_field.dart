import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final Function(String)? onCountryChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.onCountryChanged,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String _selectedCountry = 'IN';
  final Map<String, String> _countryCodes = {
    'IN': '+91',
    'US': '+1',
    'UK': '+44',
    'CA': '+1',
    'AU': '+61',
    'NZ': '+64',
    'SG': '+65',
    'MY': '+60',
    'PH': '+63',
    'TH': '+66',
  };

  final Map<String, int> _phoneDigits = {
    'IN': 10,
    'US': 10,
    'UK': 10,
    'CA': 10,
    'AU': 9,
    'NZ': 9,
    'SG': 8,
    'MY': 9,
    'PH': 10,
    'TH': 9,
  };

  final Map<String, String> _countryFlags = {
    'IN': '🇮🇳',
    'US': '🇺🇸',
    'UK': '🇬🇧',
    'CA': '🇨🇦',
    'AU': '🇦🇺',
    'NZ': '🇳🇿',
    'SG': '🇸🇬',
    'MY': '🇲🇾',
    'PH': '🇵🇭',
    'TH': '🇹🇭',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Color(0xFF0e121b),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFf8f9fc),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFe2e8f0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Country Code Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DropdownButton<String>(
                  value: _selectedCountry,
                  underline: const SizedBox(),
                  items: _countryCodes.keys.map((String country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Row(
                        children: [
                          Text(
                            _countryFlags[country] ?? '',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _countryCodes[country] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0e121b),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCountry = newValue;
                        widget.controller.clear();
                      });
                      widget.onCountryChanged?.call(newValue);
                    }
                  },
                ),
              ),
              // Divider
              Container(
                width: 1,
                height: 30,
                color: const Color(0xFFe2e8f0),
              ),
              // Phone Number Input
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  style: const TextStyle(
                    color: Color(0xFF0e121b),
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_phoneDigits[_selectedCountry] ?? 10),
                  ],
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF94a3b8),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (widget.validator != null) {
                      return widget.validator!(value);
                    }
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    final requiredDigits = _phoneDigits[_selectedCountry] ?? 10;
                    if (value.length != requiredDigits) {
                      return 'Phone number must be exactly $requiredDigits digits for $_selectedCountry';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}



