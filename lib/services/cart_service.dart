import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../models/cart_item.dart';
import '../config/api_config.dart';

class CartResponse {
  final List<CartItem> cartItems;
  final double total;

  CartResponse({
    required this.cartItems,
    required this.total,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Handle case where cart_items might be null
      final cartItemsList = json['cart_items'] as List<dynamic>? ?? [];
      
      return CartResponse(
        cartItems: cartItemsList.map((item) => CartItem.fromJson(item)).toList(),
        total: (json['total'] is num) ? (json['total'] as num).toDouble() : 0.0,
      );
    } catch (e) {
      Logger('CartResponse').severe('Error parsing CartResponse: $json');
      Logger('CartResponse').severe('Error details: $e');
      // Return empty cart response instead of throwing
      return CartResponse(cartItems: [], total: 0.0);
    }
  }
}

class CartService {
  final String _baseUrl = '${ApiConfig.baseUrl}${ApiConfig.cartEndpoint}';
  final String token;
  final Logger _logger = Logger('CartService');

  CartService({required this.token});

  // Get cart items
  Future<CartResponse> getCart() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _logger.info('Get cart response - Status: ${response.statusCode}');
      _logger.fine('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CartResponse.fromJson(data);
      } else {
        _logger.warning('Failed to get cart items. Status: ${response.statusCode}');
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to load cart items');
      }
    } catch (e) {
      _logger.severe('Error getting cart items: $e');
      throw Exception('Error getting cart items: $e');
    }
  }

  // Add item to cart
  Future<CartResponse> addToCart(String productId, int quantity) async {
    try {
      _logger.info('Adding to cart - Product ID: $productId, Quantity: $quantity');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/add'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      _logger.info('Add to cart response - Status: ${response.statusCode}');
      _logger.fine('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data == null) {
          _logger.warning('Received null response data');
          return CartResponse(cartItems: [], total: 0.0);
        }
        return CartResponse.fromJson(data);
      } else {
        _logger.warning('Failed to add item to cart. Status: ${response.statusCode}');
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to add item to cart');
      }
    } catch (e) {
      _logger.severe('Add to cart error: $e');
      throw Exception('Error adding item to cart: $e');
    }
  }

  // Update cart item quantity
  Future<CartResponse> updateCartItemQuantity(String cartItemId, int quantity) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/update/$cartItemId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'quantity': quantity,
        }),
      );

      _logger.info('Update cart response - Status: ${response.statusCode}');
      _logger.fine('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CartResponse.fromJson(data);
      } else {
        _logger.warning('Failed to update cart item. Status: ${response.statusCode}');
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to update cart item');
      }
    } catch (e) {
      _logger.severe('Error updating cart item: $e');
      throw Exception('Error updating cart item: $e');
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/remove/$cartItemId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _logger.info('Remove from cart response - Status: ${response.statusCode}');
      _logger.fine('Response body: ${response.body}');

      if (response.statusCode != 200) {
        _logger.warning('Failed to remove item from cart. Status: ${response.statusCode}');
        final errorBody = json.decode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to remove item from cart');
      }
    } catch (e) {
      _logger.severe('Error removing item from cart: $e');
      throw Exception('Error removing item from cart: $e');
    }
  }
}
