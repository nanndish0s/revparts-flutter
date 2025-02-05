import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Base URL for the API
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://192.168.1.42:8000';
    }
  }
  
  // API endpoints
  static const String cartEndpoint = '/api/cart';
  static const String productsEndpoint = '/api/products';
  static const String authEndpoint = '/api/auth';
  
  // API version
  static const String apiVersion = 'v1';
  
  // Timeout durations
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
