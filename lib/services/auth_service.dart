import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  // Use localhost for web, IP address for mobile
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      return 'http://192.168.1.42:8000/api';
    }
  }
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Store authentication token and user data in memory
  String? _authToken;
  Map<String, dynamic>? _userData;

  // Initialize SharedPreferences
  Future<void> _initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Retrieve stored token and user data
    _authToken = prefs.getString(_tokenKey);
    
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      _userData = jsonDecode(userDataString);
    }

    if (kDebugMode) {
      debugPrint('🔑 Stored Token: ${_authToken != null ? '(exists)' : 'null'}');
      debugPrint('👤 Stored User Data: ${_userData != null ? '(exists)' : 'null'}');
    }
  }

  // Save token to persistent storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _authToken = token;

    if (kDebugMode) {
      debugPrint('💾 Token saved to persistent storage');
    }
  }

  // Save user data to persistent storage
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
    _userData = userData;

    if (kDebugMode) {
      debugPrint('💾 User data saved to persistent storage');
    }
  }

  // Constructor to initialize preferences
  AuthService() {
    _initPreferences();
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email.toLowerCase(),
          'password': password,
          'password_confirmation': passwordConfirmation,
          'role': role,
        }),
      );

      print('Registration Response Status Code: ${response.statusCode}');
      print('Registration Response Body: ${response.body}');

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save user data and token if registration is successful
        await _saveUserData(responseBody['user'] ?? {});
        
        if (responseBody['token'] != null) {
          await _saveToken(responseBody['token']);
        }

        return {
          'success': true,
          'message': responseBody['message'] ?? 'Registration successful',
          'user': responseBody['user'],
        };
      } else if (response.statusCode == 422) {
        return {
          'success': false,
          'message': 'Validation Error',
          'errors': responseBody['errors'] ?? {
            'general': ['Unprocessable content. Please check your input.']
          },
        };
      } else {
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Registration failed',
          'errors': responseBody['errors'] ?? {},
        };
      }
    } catch (e) {
      print('Registration Error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Attempting Login:');
        debugPrint('   Email: $email');
        debugPrint('   Base URL: $_baseUrl/login');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (kDebugMode) {
        debugPrint('📡 Login Response:');
        debugPrint('   Status Code: ${response.statusCode}');
        debugPrint('   Response Body: ${response.body}');
      }

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Detailed logging of token and user data
        if (kDebugMode) {
          debugPrint('🔑 Token Received: ${responseBody['token'] != null}');
          debugPrint('👤 User Data Received: ${responseBody['user'] != null}');
          
          if (responseBody['token'] != null) {
            debugPrint('   Token (first 10 chars): ${responseBody['token'].substring(0, 10)}...');
          }
          
          if (responseBody['user'] != null) {
            debugPrint('   User Details:');
            debugPrint('     ID: ${responseBody['user']['id']}');
            debugPrint('     Email: ${responseBody['user']['email']}');
          }
        }

        // Save token and user data to persistent storage
        final token = responseBody['token'];
        final userData = responseBody['user'] ?? {};

        // Validate token before saving
        if (token != null) {
          await _saveToken(token);
        } else {
          if (kDebugMode) {
            debugPrint('❌ No token received during login');
          }
        }

        await _saveUserData(userData);

        return {
          'success': true,
          'message': responseBody['message'] ?? 'Login successful',
          'user': userData,
          'token': token,
        };
      } else {
        if (kDebugMode) {
          debugPrint('❌ Login Failed:');
          debugPrint('   Status Code: ${response.statusCode}');
          debugPrint('   Error Message: ${responseBody['message'] ?? 'Unknown error'}');
        }

        return {
          'success': false,
          'message': responseBody['message'] ?? 'Login failed',
          'errors': responseBody['errors'] ?? {},
        };
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🚨 Login Error:');
        debugPrint('   Error: $e');
      }

      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Getter method to retrieve authentication token
  String? getAuthToken() {
    if (kDebugMode) {
      debugPrint('🔑 Retrieving Token: ${_authToken != null ? '(exists)' : 'null'}');
    }
    return _authToken;
  }

  // Getter methods to access stored token and user data
  String? get authToken => _authToken;
  Map<String, dynamic>? get userData => _userData;

  // Method to check if user is logged in
  bool get isLoggedIn => _authToken != null;

  // Method to logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    
    _authToken = null;
    _userData = null;
    
    if (kDebugMode) {
      debugPrint('🚪 User logged out. Token and user data cleared.');
    }
  }

  // Clear method to reset all authentication-related data
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    
    _authToken = null;
    _userData = null;
  }

  // Check if user is currently authenticated
  bool get isAuthenticated => _authToken != null;

  // Validate token format
  bool isValidToken(String? token) {
    if (token == null) return false;
    
    // Basic token validation (adjust based on your token format)
    bool hasValidFormat = token.length > 20 && token.contains('.');
    
    if (kDebugMode) {
      debugPrint('🕵️ Token Validation:');
      debugPrint('   Length: ${token.length}');
      debugPrint('   Contains ".": ${token.contains('.')}');
      debugPrint('   Valid Format: $hasValidFormat');
    }
    
    return hasValidFormat;
  }
}
