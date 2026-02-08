import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _cachedPosition;
  String? _cachedAddress;

  /// Check if location services are enabled
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  /// Request permission and return true if granted
  Future<bool> requestAndCheckPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || 
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await requestAndCheckPermission();
      if (!hasPermission) return null;

      _cachedPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return _cachedPosition;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get cached position or fetch new one
  Future<Position?> getPosition() async {
    if (_cachedPosition != null) {
      return _cachedPosition;
    }
    return await getCurrentPosition();
  }

  /// Get coordinates as Map for Firebase
  Future<Map<String, double>?> getCoordinatesMap() async {
    final position = await getPosition();
    if (position == null) return null;
    
    return {
      'lat': position.latitude,
      'lng': position.longitude,
    };
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return null;
  }

  /// Get current address
  Future<String?> getCurrentAddress() async {
    if (_cachedAddress != null) return _cachedAddress;
    
    final position = await getPosition();
    if (position == null) return null;

    _cachedAddress = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    return _cachedAddress;
  }

  /// Generate Google Maps URL for directions
  String getGoogleMapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
  }

  /// Generate static map image URL (no API key needed for basic preview)
  String getStaticMapUrl(double lat, double lng, {int zoom = 15, int width = 400, int height = 200}) {
    // Using OpenStreetMap static image (free, no API key)
    return 'https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=$zoom&size=${width}x$height&markers=$lat,$lng,red-pushpin';
  }

  /// Clear cache (useful when user changes location)
  void clearCache() {
    _cachedPosition = null;
    _cachedAddress = null;
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }
}
