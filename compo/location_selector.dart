import 'package:flutter/material.dart';
import '../../../utils/helpers.dart';
import '../../../config/app_colors.dart';

class LocationSelector extends StatefulWidget {
  const LocationSelector({Key? key}) : super(key: key);

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  String _selectedLocation = 'Ramanattukara';

  @override
  void initState() {
    super.initState();
    _loadSelectedLocation();
  }

  _loadSelectedLocation() async {
    final location = await Helpers.getSelectedLocation();
    if (mounted) {
      setState(() {
        _selectedLocation = location;
      });
    }
  }

  _saveSelectedLocation(String location) async {
    await Helpers.saveSelectedLocation(location);
    if (mounted) {
      setState(() {
        _selectedLocation = location;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: _saveSelectedLocation,
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'Ramanattukara',
            child: Text('Ramanattukara'),
          ),
          const PopupMenuItem<String>(
            value: 'Narikkuni',
            child: Text('Narikkuni'),
          ),
          const PopupMenuItem<String>(
            value: 'Edarikode',
            child: Text('Edarikode'),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppColors.silverGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.silver.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              _selectedLocation,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}