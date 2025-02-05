import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class ProductsService {
  // Use localhost for web, IP address for mobile
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    } else {
      return 'http://192.168.1.42:8000/api';
    }
  }

  final String _token;

  // In-memory storage for products
  List<Product> _products = [];

  ProductsService({required String token}) : _token = token;

  Future<List<Product>> fetchProducts() async {
    try {
      // Enhanced token validation
      if (_token.isEmpty) {
        debugPrint('❌ No authentication token available');
        throw Exception('User not authenticated');
      }
      
      if (kDebugMode) {
        debugPrint('🔍 Fetching Products');
        debugPrint('🔑 Authentication Token (first 10 chars): ${_token.substring(0, 10)}...');
        debugPrint('🌐 API Endpoint: $_baseUrl/products');
      }

      try {
        final response = await http.get(
          Uri.parse('$_baseUrl/products'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('🚨 Request timed out');
            throw TimeoutException('The connection has timed out.');
          },
        );

        // Comprehensive logging of response
        if (kDebugMode) {
          debugPrint('📡 Response Status Code: ${response.statusCode}');
          debugPrint('📄 Response Headers: ${response.headers}');
          debugPrint('📄 Response Body: ${response.body}');
        }

        // Handle different HTTP status codes
        switch (response.statusCode) {
          case 200:
            try {
              final responseBody = jsonDecode(response.body);
              
              // Comprehensive logging of response structure
              if (kDebugMode) {
                debugPrint('🧐 Response Type: ${responseBody.runtimeType}');
                debugPrint('🔑 Available Keys: ${responseBody.keys}');
              }

              // More flexible parsing of products
              final List<dynamic> productData = _extractProductData(responseBody);
              
              _products = productData
                  .map((productJson) {
                    try {
                      if (kDebugMode) {
                        debugPrint('🖼️ Product Image Path: ${productJson['product_image']}');
                      }
                      return Product.fromJson(productJson);
                    } catch (e) {
                      debugPrint('❌ Error parsing individual product: $e');
                      debugPrint('Problematic JSON: $productJson');
                      return null;
                    }
                  })
                  .whereType<Product>()
                  .toList();
              
              if (kDebugMode) {
                debugPrint('📦 Parsed Products Count: ${_products.length}');
                if (_products.isNotEmpty) {
                  debugPrint('🥇 First Product Details: ${_products[0].toJson()}');
                }
              }

              return _products;
            } catch (parseError) {
              debugPrint('❌ JSON Parsing Error: $parseError');
              throw Exception('Failed to parse products: $parseError');
            }
          
          case 401:
            debugPrint('❌ Authentication Failed (401)');
            throw Exception('Authentication failed. Please login again.');
          
          case 403:
            debugPrint('❌ Forbidden Access (403)');
            throw Exception('You do not have permission to access products.');
          
          case 404:
            debugPrint('❌ Products Endpoint Not Found (404)');
            throw Exception('Products endpoint not found. Check API configuration.');
          
          case 500:
            debugPrint('❌ Internal Server Error (500)');
            throw Exception('Server error. Please try again later.');
          
          default:
            debugPrint('❌ Unexpected Response: ${response.statusCode}');
            throw Exception('Unexpected error. Status code: ${response.statusCode}');
        }
      } on SocketException catch (e) {
        debugPrint('🚨 Network Error: ${e.message}');
        throw Exception('Network error. Please check your internet connection and API endpoint.');
      } on TimeoutException catch (e) {
        debugPrint('🚨 Connection Timeout: ${e.message}');
        throw Exception('Connection timed out. Please check your network and try again.');
      } catch (e) {
        debugPrint('🚨 Unexpected Error: $e');
        throw Exception('An unexpected error occurred: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🚨 Products Fetch Error: $e');
      }
      rethrow;  // Rethrow to allow caller to handle the error
    }
  }

  // Flexible method to extract product data from different response structures
  List<dynamic> _extractProductData(dynamic responseBody) {
    if (kDebugMode) {
      debugPrint('🕵️ Attempting to extract products');
      debugPrint('🔍 Response Type: ${responseBody.runtimeType}');
    }

    // Specifically handle the Laravel pagination structure
    if (responseBody is Map && responseBody.containsKey('data')) {
      final productData = responseBody['data'];
      
      if (kDebugMode) {
        debugPrint('✅ Found products in "data" key');
        debugPrint('📊 Products Count: ${productData.length}');
        
        // Log first product details for debugging
        if (productData.isNotEmpty) {
          debugPrint('🥇 First Product Details:');
          debugPrint('   Name: ${productData[0]['name']}');
          debugPrint('   ID: ${productData[0]['id']}');
          debugPrint('   Category: ${productData[0]['category']}');
        }
      }
      
      return productData;
    }

    // Fallback for other possible response structures
    final productKeys = ['products', 'items', 'results'];
    
    if (responseBody is Map) {
      for (var key in productKeys) {
        if (responseBody.containsKey(key)) {
          if (responseBody[key] is List) {
            return responseBody[key];
          }
        }
      }
    } else if (responseBody is List) {
      return responseBody;
    }

    // If no products found, return empty list with debug info
    if (kDebugMode) {
      debugPrint('❌ No products could be parsed');
    }
    return [];
  }

  // Fetch a single product by ID
  Future<Product?> fetchProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return Product.fromJson(responseBody);
      } else {
        throw Exception('Failed to load product details');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching product details: $e');
      }
      return null;
    }
  }

  Future<Product> fetchProductDetails(String productId) async {
    try {
      // Enhanced token validation
      if (_token.isEmpty) {
        debugPrint('❌ No authentication token available');
        throw Exception('User not authenticated');
      }
      
      if (kDebugMode) {
        debugPrint('🔍 Fetching Product Details for ID: $productId');
        debugPrint('🔑 Authentication Token (first 10 chars): ${_token.substring(0, 10)}...');
        debugPrint('🌐 API Endpoint: $_baseUrl/products/$productId');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('🚨 Request timed out');
          throw TimeoutException('The connection has timed out.');
        },
      );

      // Comprehensive logging of response
      if (kDebugMode) {
        debugPrint('📡 Response Status Code: ${response.statusCode}');
        debugPrint('📄 Response Headers: ${response.headers}');
        debugPrint('📄 Response Body: ${response.body}');
      }

      // Handle different HTTP status codes
      switch (response.statusCode) {
        case 200:
          try {
            final responseBody = jsonDecode(response.body);
            
            // More flexible parsing of product
            final productJson = responseBody is Map ? responseBody : responseBody['data'];
            
            if (productJson == null) {
              throw Exception('No product data found');
            }
            
            final product = Product.fromJson(productJson);
            
            if (kDebugMode) {
              debugPrint('📦 Parsed Product: ${product.toJson()}');
            }

            return product;
          } catch (parseError) {
            debugPrint('❌ JSON Parsing Error: $parseError');
            throw Exception('Failed to parse product details: $parseError');
          }
        
        case 401:
          debugPrint('❌ Authentication Failed (401)');
          throw Exception('Authentication failed. Please login again.');
        
        case 404:
          debugPrint('❌ Product Not Found (404)');
          throw Exception('Product not found');
        
        default:
          debugPrint('❌ Unexpected Error: ${response.statusCode}');
          throw Exception('Failed to fetch product details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Fetch Product Details Error: $e');
      rethrow;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      if (_token.isEmpty) {
        debugPrint('❌ No authentication token available');
        throw Exception('User not authenticated');
      }

      if (kDebugMode) {
        debugPrint('🔍 Searching Products with query: $query');
        debugPrint('🌐 API Endpoint: $_baseUrl/products/search');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/products/search?q=${Uri.encodeComponent(query)}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('The connection has timed out.');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<Product> searchResults = data.map((json) => Product.fromJson(json)).toList();
        return searchResults;
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching products: $e');
      rethrow;
    }
  }

  List<Product> get products => _products;
}
