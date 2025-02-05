import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../config/api_config.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

class OrderService {
  final String token;
  final String baseUrl = ApiConfig.baseUrl;
  final Logger _logger = Logger('OrderService');

  OrderService({required this.token});

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<List<Order>> getOrders() async {
    try {
      _logger.info('Getting orders from: $baseUrl/api/orders');
      _logger.info('Headers: $_headers');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders'),
        headers: _headers,
      );

      _logger.info('Get orders response status: ${response.statusCode}');
      _logger.info('Get orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['orders'] != null && responseData['orders'] is List) {
          final List<dynamic> orders = responseData['orders'];
          return orders.map((orderJson) => Order.fromJson(orderJson)).toList();
        }
        throw Exception('Invalid response format: Missing orders array');
      } else {
        throw Exception('Failed to load orders: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error getting orders: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<Order> createOrder() async {
    try {
      final url = '$baseUrl/api/orders';
      _logger.info('Creating order at: $url');
      _logger.info('Headers: $_headers');
      
      // We don't need to send cart items as the API will fetch them
      final Map<String, dynamic> orderData = {
        'status': 'pending'
      };

      _logger.info('Sending order data: ${json.encode(orderData)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(orderData),
      );

      _logger.info('Create order response status: ${response.statusCode}');
      _logger.info('Create order raw response: ${response.body}');
      
      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        _logger.info('Successfully decoded response: $responseData');
        
        if (responseData['order'] != null) {
          final orderData = responseData['order'];
          _logger.info('Found order data: $orderData');
          return Order.fromJson(orderData);
        }
        
        throw Exception('Invalid response format: Missing order data');
      } else {
        String errorMessage = 'Failed to create order';
        try {
          final errorData = json.decode(response.body);
          _logger.info('Error response data: $errorData');
          
          if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          _logger.warning('Could not parse error response: $e');
        }
        throw Exception('$errorMessage (Status: ${response.statusCode})');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error creating order: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<Order> getOrder(int id) async {
    try {
      _logger.info('Getting order from: $baseUrl/api/orders/$id');
      _logger.info('Headers: $_headers');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders/$id'),
        headers: _headers,
      );

      _logger.info('Get order response status: ${response.statusCode}');
      _logger.info('Get order response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return Order.fromJson(data);
      } else {
        throw Exception('Failed to load order: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      _logger.severe('Error getting order: $e\n$stackTrace');
      rethrow;
    }
  }
}
