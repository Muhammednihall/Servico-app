import 'package:flutter/material.dart';

class ServiceAreaField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final String selectedCountry;

  const ServiceAreaField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    required this.selectedCountry,
  });

  @override
  State<ServiceAreaField> createState() => _ServiceAreaFieldState();
}

class _ServiceAreaFieldState extends State<ServiceAreaField> {
  final List<Map<String, String>> _indianCities = [
    {'city': 'Kozhikode', 'state': 'Kerala'},
    {'city': 'Kochi', 'state': 'Kerala'},
    {'city': 'Thiruvananthapuram', 'state': 'Kerala'},
    {'city': 'Kannur', 'state': 'Kerala'},
    {'city': 'Malappuram', 'state': 'Kerala'},
    {'city': 'Ernakulam', 'state': 'Kerala'},
    {'city': 'Bangalore', 'state': 'Karnataka'},
    {'city': 'Mysore', 'state': 'Karnataka'},
    {'city': 'Mangalore', 'state': 'Karnataka'},
    {'city': 'Pune', 'state': 'Maharashtra'},
    {'city': 'Mumbai', 'state': 'Maharashtra'},
    {'city': 'Nagpur', 'state': 'Maharashtra'},
    {'city': 'Delhi', 'state': 'Delhi'},
    {'city': 'Noida', 'state': 'Uttar Pradesh'},
    {'city': 'Gurgaon', 'state': 'Haryana'},
    {'city': 'Chennai', 'state': 'Tamil Nadu'},
    {'city': 'Coimbatore', 'state': 'Tamil Nadu'},
    {'city': 'Hyderabad', 'state': 'Telangana'},
    {'city': 'Kolkata', 'state': 'West Bengal'},
    {'city': 'Ahmedabad', 'state': 'Gujarat'},
    {'city': 'Jaipur', 'state': 'Rajasthan'},
    {'city': 'Lucknow', 'state': 'Uttar Pradesh'},
    {'city': 'Chandigarh', 'state': 'Chandigarh'},
    {'city': 'Indore', 'state': 'Madhya Pradesh'},
    {'city': 'Bhopal', 'state': 'Madhya Pradesh'},
  ];

  List<Map<String, String>> _filteredCities = [];
  bool _showSuggestions = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _showSuggestions) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _onTextChanged() {
    final query = widget.controller.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredCities = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _filteredCities = _indianCities
          .where((city) =>
              city['city']!.toLowerCase().contains(query) ||
              city['state']!.toLowerCase().contains(query))
          .toList();
      _showSuggestions = _filteredCities.isNotEmpty && _focusNode.hasFocus;
    });
  }

  void _selectCity(Map<String, String> city) {
    widget.controller.text = '${city['city']}, ${city['state']}';
    setState(() {
      _showSuggestions = false;
      _filteredCities = [];
    });
    _focusNode.unfocus();
  }

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
        Stack(
          children: [
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
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                style: const TextStyle(
                  color: Color(0xFF0e121b),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: const TextStyle(
                    color: Color(0xFF94a3b8),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF9ca3af),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: widget.validator,
              ),
            ),
            if (_showSuggestions && _filteredCities.isNotEmpty)
              Positioned(
                top: 56,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: const Color(0xFFe2e8f0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredCities.length,
                    itemBuilder: (context, index) {
                      final city = _filteredCities[index];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectCity(city),
                          hoverColor: const Color(0xFFf0f4f8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Text(
                              '${city['city']}, ${city['state']}',
                              style: const TextStyle(
                                color: Color(0xFF0e121b),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
