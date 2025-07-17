import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_model.dart';
import '../models/user_model.dart';

class ApiService {
  // Change base URL to use 10.0.2.2 for Android emulator instead of localhost
  static const String baseUrl = 'http://10.0.2.2:8000/api';


  // Connection timeout values
  static const int connectionTimeout = 15; // seconds
  static const int receiveTimeout = 15; // seconds

  // Token storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Get stored token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(accessTokenKey);
  }

  // Save authentication data
  static Future<void> saveAuthData(AuthModel authData) async {
    final prefs = await SharedPreferences.getInstance();
    if (authData.accessToken != null) {
      await prefs.setString(accessTokenKey, authData.accessToken!);
    }
    if (authData.refreshToken != null) {
      await prefs.setString(refreshTokenKey, authData.refreshToken!);
    }
    if (authData.user != null) {
      await prefs.setString(userDataKey, jsonEncode(authData.user!.toJson()));
    }
  }

  // Clear authentication data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(userDataKey);
  }

  // Get stored user data
  static Future<User?> getStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(userDataKey);
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Create HTTP headers with authorization
  static Future<Map<String, String>> _getHeaders({
    bool requireAuth = true,
  }) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (requireAuth) {
      final token = await getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Helper method to handle common HTTP errors
  static Future<http.Response> _handleRequest(
    Future<http.Response> request,
  ) async {
    try {
      return await request.timeout(
        const Duration(seconds: connectionTimeout),
        onTimeout: () {
          throw TimeoutException(
            "Connection timed out. Please check your internet connection.",
          );
        },
      );
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 111) {
        throw const ConnectionRefusedException(
          "Could not connect to the server. Please make sure the API server is running.",
        );
      } else {
        throw NetworkException("Network error: ${e.message}");
      }
    } on HttpException catch (e) {
      throw NetworkException("HTTP error: ${e.message}");
    } on FormatException catch (e) {
      throw NetworkException("Invalid response format: ${e.message}");
    } catch (e) {
      if (e is TimeoutException ||
          e is ConnectionRefusedException ||
          e is NetworkException) {
        rethrow;
      }
      throw NetworkException("Unexpected error: $e");
    }
  }

  // Login user
  static Future<AuthModel> login(String username, String password) async {
    try {
      // Add debug printing to check what we're sending
      print("Attempting login with username: $username");
      print("Sending login to: $baseUrl/users/login/");
      print("🔥 API LOGIN URL → $baseUrl/users/login/");
      
      final response = await _handleRequest(
        http.post(
          Uri.parse('$baseUrl/users/login/'),
          headers: await _getHeaders(requireAuth: false),
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        ),
      );

      // Print response status code and body for debugging
      print("Login response status: ${response.statusCode}");
      print("Login response body: ${response.body}");

      if (response.statusCode == 200) {
        final authData = AuthModel.fromJson(jsonDecode(response.body));
        await saveAuthData(authData);
        return authData;
      } else if (response.statusCode == 401) {
        throw AuthException("Invalid username or password. Please check your credentials and try again.");
      } else {
        throw ApiException(
          "Login failed: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Login error: $e");
      if (e is TimeoutException ||
          e is ConnectionRefusedException ||
          e is NetworkException ||
          e is AuthException ||
          e is ApiException) {
        rethrow;
      }
      throw ApiException("Login failed: $e");
    }
  }

  // Register user
  static Future<AuthModel> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    required Map<String, dynamic> location,
  }) async {
    try {
      // Print request body for debugging
      final requestBody = {
        'username': username,
        'email': email,
        'password': password,  // Ensure password is included
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'role': role,
        'location': location,
      };
      
      print("Registration request: ${jsonEncode(requestBody)}");
      
      final response = await _handleRequest(
        http.post(
          Uri.parse('$baseUrl/users/'),
          headers: await _getHeaders(requireAuth: false),
          body: jsonEncode(requestBody),
        ),
      );

      // Print response for debugging
      print("Registration response status: ${response.statusCode}");
      print("Registration response body: ${response.body}");

      if (response.statusCode == 201) {
        final authData = AuthModel.fromJson(jsonDecode(response.body));
        await saveAuthData(authData);
        return authData;
      } else if (response.statusCode == 400) {
        // Handle validation errors
        final errorData = jsonDecode(response.body);
        throw ValidationException(
          "Registration failed: ${errorData.toString()}",
        );
      } else {
        throw ApiException(
          "Registration failed: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Registration error: $e");
      if (e is TimeoutException ||
          e is ConnectionRefusedException ||
          e is NetworkException ||
          e is ValidationException ||
          e is ApiException) {
        rethrow;
      }
      throw ApiException("Registration failed: $e");
    }
  }

  // Get current user profile
  static Future<User> getCurrentUserProfile() async {
    try {
      final response = await _handleRequest(
        http.get(Uri.parse('$baseUrl/users/me/'), headers: await _getHeaders()),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw AuthException("Authentication required");
      } else {
        throw ApiException(
          "Failed to get profile: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      if (e is TimeoutException ||
          e is ConnectionRefusedException ||
          e is NetworkException ||
          e is AuthException ||
          e is ApiException) {
        rethrow;
      }
      throw ApiException("Failed to get profile: $e");
    }
  }

  // Logout user
  static Future<void> logout() async {
    await clearAuthData();
  }

  // For testing connection to server - directly try the login endpoint
  static Future<bool> testConnection() async {
    try {
      // Try to access the login endpoint without credentials
      // This will return 401 but at least we know the server is running
      final response = await http
          .get(
            Uri.parse('$baseUrl/users/login/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
          
      print("Test connection status: ${response.statusCode}");
      
      // Any response means the server is accessible
      // 401 Unauthorized is expected for login endpoint without credentials
      return response.statusCode >= 200 && response.statusCode < 500 || 
             response.statusCode == 401;
    } on SocketException {
      print("Socket exception during connection test");
      return false;
    } catch (e) {
      print("Other exception during connection test: $e");
      return false;
    }
  }
}

// Custom exceptions
class ConnectionRefusedException implements Exception {
  final String message;
  const ConnectionRefusedException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => message;
}
