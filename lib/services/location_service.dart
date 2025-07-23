import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Singleton instance
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Location data
  Position? _currentPosition;
  String? _currentAddress;
  String? _city;
  bool _locationPermissionDenied = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  String? get city => _city;
  bool get locationPermissionDenied => _locationPermissionDenied;

  // Request permission and get location
  Future<bool> requestLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      _showLocationDialog(
        context,
        'Location services are disabled',
        'Please enable location services in your device settings to use this feature.',
      );
      return false;
    }

    // Check permission status
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied
        _locationPermissionDenied = true;
        _showLocationDialog(
          context,
          'Location permission denied',
          'To get your current location, please allow location access.',
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied
      _locationPermissionDenied = true;
      _showLocationDialog(
        context,
        'Location permissions permanently denied',
        'Please enable location permissions in app settings.',
        showSettings: true,
      );
      return false;
    }

    // Permission granted
    _locationPermissionDenied = false;
    return true;
  }

  // Get current location
  Future<Position?> getCurrentLocation(BuildContext context) async {
    try {
      final hasPermission = await requestLocationPermission(context);
      if (!hasPermission) return null;

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return _currentPosition;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Get address from location
  Future<String?> getAddressFromLatLng(BuildContext context) async {
    try {
      if (_currentPosition == null) {
        final position = await getCurrentLocation(context);
        if (position == null) return null;
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
        _city = place.locality; // Store city name
        return _currentAddress;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  // Get just the city name
  Future<String?> getCityName(BuildContext context) async {
    try {
      if (_currentPosition == null) {
        final position = await getCurrentLocation(context);
        if (position == null) return null;
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _city = place.locality;
        return _city;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting city: $e');
      return null;
    }
  }

  // Show location dialog
  void _showLocationDialog(
    BuildContext context,
    String title,
    String message, {
    bool showSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            if (showSettings)
              TextButton(
                child: const Text('Settings'),
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
              ),
            if (!showSettings)
              TextButton(
                child: const Text('Try Again'),
                onPressed: () {
                  Navigator.of(context).pop();
                  requestLocationPermission(context);
                },
              ),
          ],
        );
      },
    );
  }
}
