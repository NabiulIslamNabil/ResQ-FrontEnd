import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
  connectionError,
}

class User {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.role,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? 'CITIZEN',
    );
  }
}

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _refreshToken;
  User? _user;
  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _city;
  double? _latitude;
  double? _longitude;

  // Base API URL - Updated to use 10.0.2.2 for Android emulator
  final String _baseUrl = 'http://10.0.2.2:8000/api';

  // Helper method to construct API URLs
  String _buildUrl(String endpoint) {
    return '$_baseUrl/${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}';
  }

  // Getters
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  User? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get errorMessage => _errorMessage;
  String? get city => _city;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  // Set user location
  void setUserLocation(String? city, double? latitude, double? longitude) {
    _city = city;
    _latitude = latitude;
    _longitude = longitude;
    notifyListeners();
  }

  // Login method
  Future<bool> login(String username, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse(_buildUrl('users/login/')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _token = data['access'];
        _refreshToken = data['refresh'];
        _user = User.fromJson(data['user']);
        _status = AuthStatus.authenticated;

        // Check if location data is available in the response
        if (data['user'] != null && data['user']['location'] != null) {
          final location = data['user']['location'];
          if (location['city'] != null) {
            _city = location['city'];
          }
          if (location['latitude'] != null) {
            _latitude = location['latitude'];
          }
          if (location['longitude'] != null) {
            _longitude = location['longitude'];
          }
        }

        notifyListeners();
        return true;
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        final data = json.decode(response.body);
        _errorMessage = data['detail'] ?? 'Authentication failed';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Server error, please try again later';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: ${e.toString()}';
      _status = AuthStatus.connectionError;
      notifyListeners();
      return false;
    }
  }

  // Register method
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final requestBody = {
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'role': role,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
        },
      };

      print('Registration request: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse(_buildUrl('users/register/')),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Log the response for debugging
      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);

        _token = data['access'];
        _refreshToken = data['refresh'];
        _user = User.fromJson(data['user']);
        _status = AuthStatus.authenticated;

        notifyListeners();
        return true;
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        final data = json.decode(response.body);
        _errorMessage = _formatErrorMessage(data);
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Server error, please try again later';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: ${e.toString()}';
      _status = AuthStatus.connectionError;
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Refresh user profile
  Future<bool> refreshUserProfile() async {
    if (_token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse(_buildUrl('users/me/')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _user = User.fromJson(data);
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else if (response.statusCode == 401) {
        // Token expired
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Session expired, please login again';
        notifyListeners();
        return false;
      } else {
        _errorMessage = 'Failed to load profile';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error: ${e.toString()}';
      _status = AuthStatus.connectionError;
      notifyListeners();
      return false;
    }
  }

  // Retry connection
  Future<void> retryConnection() async {
    if (_status == AuthStatus.connectionError) {
      _status = AuthStatus.loading;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));

      if (_token != null) {
        await refreshUserProfile();
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    }
  }

  // Add a getter to easily access the user role
  String? get userRole => user?.role;

  // Get the dashboard data using emergency reports endpoint
  Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      if (user == null) return null;

      final response = await http.get(
        Uri.parse(_buildUrl('emergency/reports/')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final reports = jsonDecode(response.body);

        // Count status occurrences
        int pending = 0;
        int responding = 0;
        int onScene = 0;

        for (final report in reports) {
          final status = report['status'] ?? 'PENDING';
          if (status == 'PENDING') pending++;
          if (status == 'RESPONDING') responding++;
          if (status == 'ON_SCENE') onScene++;
        }

        // Format data to match expected dashboard structure
        return {
          'current_status': {
            'pending': pending,
            'responding': responding,
            'on_scene': onScene,
          },
          'pending_emergencies':
              reports.where((r) => r['status'] == 'PENDING').toList(),
        };
      } else {
        _errorMessage = 'Failed to get emergency reports';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return null;
    }
  }

  // Update emergency status
  Future<Map<String, dynamic>?> updateEmergencyStatus(
    String emergencyId,
    String status,
  ) async {
    try {
      // Correct API endpoint format: emergency/reports/{id}/
      final response = await http.patch(
        Uri.parse(_buildUrl('emergency/reports/$emergencyId/')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _errorMessage =
            'Failed to update emergency status: ${response.statusCode}';
        debugPrint('Error response: ${response.body}');
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
      return null;
    }
  }

  // Format error message from response data
  String _formatErrorMessage(Map<String, dynamic> data) {
    if (data.containsKey('detail')) {
      return data['detail'];
    }

    // Handle validation errors
    final errors = <String>[];
    data.forEach((key, value) {
      if (value is List) {
        errors.add('$key: ${value.join(', ')}');
      } else {
        errors.add('$key: $value');
      }
    });

    return errors.isNotEmpty ? errors.join('\n') : 'Registration failed';
  }
}
