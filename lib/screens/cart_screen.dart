import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../models/cart_item.dart';
import '../screens/orders_screen.dart';
import '../screens/products_screen.dart';
import 'package:logging/logging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../config/api_config.dart';

class CartScreen extends StatefulWidget {
  final String token;

  const CartScreen({
    super.key,
    required this.token,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final CartService _cartService;
  final Logger _logger = Logger('CartScreen');
  List<CartItem> _cartItems = [];
  double _total = 0;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _cartService = CartService(token: widget.token);
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      
      final cartResponse = await _cartService.getCart();
      
      setState(() {
        _cartItems = cartResponse.cartItems;
        _total = cartResponse.total;
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Error loading cart items: $e');
      setState(() {
        _error = 'Failed to load cart items';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    try {
      setState(() => _isLoading = true);
      await _cartService.updateCartItemQuantity(item.id, newQuantity);
      await _loadCartItems(); // Reload the cart to get updated data
    } catch (e) {
      _logger.severe('Error updating quantity: $e');
      setState(() {
        _error = 'Failed to update quantity';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating quantity')),
        );
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      setState(() => _isLoading = true);
      await _cartService.removeFromCart(item.id);
      await _loadCartItems(); // Reload the cart to get updated data
    } catch (e) {
      _logger.severe('Error removing item: $e');
      setState(() {
        _error = 'Failed to remove item';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error removing item')),
        );
      }
    }
  }

  double _calculateTotal() {
    return _cartItems.fold(0, (total, item) => total + item.product.price * item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shopping Cart',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: theme.colorScheme.onPrimary,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCartItems,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            )
          : _cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 100,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Your cart is empty',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Add some items to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductsScreen(userData: {'token': widget.token}),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_bag_outlined),
                        label: const Text('Continue Shopping'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          return Dismissible(
                            key: Key(item.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: theme.colorScheme.onError,
                                size: 28,
                              ),
                            ),
                            onDismissed: (direction) => _removeItem(item),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: theme.colorScheme.outline.withOpacity(0.1),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Product Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: item.product.productImage != null
                                          ? CachedNetworkImage(
                                              imageUrl: '${ApiConfig.baseUrl}/api/image-proxy/${item.product.productImage!.replaceAll(RegExp(r'^/+'), '')}',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: theme.colorScheme.primary.withOpacity(0.1),
                                                child: Icon(
                                                  Icons.inventory_2_outlined,
                                                  color: theme.colorScheme.primary,
                                                  size: 30,
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Container(
                                                color: theme.colorScheme.primary.withOpacity(0.1),
                                                child: Icon(
                                                  Icons.error_outline,
                                                  color: theme.colorScheme.error,
                                                  size: 30,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.inventory_2_outlined,
                                                color: theme.colorScheme.primary,
                                                size: 30,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Product Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.name,
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'LKR ${item.product.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Quantity Controls
                                          Container(
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.remove_circle_outline,
                                                    size: 20,
                                                    color: item.quantity > 1 
                                                        ? theme.colorScheme.primary 
                                                        : theme.colorScheme.primary.withOpacity(0.5),
                                                  ),
                                                  onPressed: item.quantity > 1
                                                      ? () => _updateQuantity(item, item.quantity - 1)
                                                      : null,
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  child: Text(
                                                    '${item.quantity}',
                                                    style: TextStyle(
                                                      color: theme.colorScheme.onSurface,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.add_circle_outline,
                                                    size: 20,
                                                    color: theme.colorScheme.primary,
                                                  ),
                                                  onPressed: () => _updateQuantity(item, item.quantity + 1),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Cart Summary
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total (${_cartItems.length} items):',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'LKR ${_calculateTotal().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : () async {
                                try {
                                  setState(() => _isLoading = true);
                                  
                                  _logger.info('Starting checkout process...');
                                  final orderService = OrderService(token: widget.token);
                                  
                                  _logger.info('Creating order with cart items: $_cartItems');
                                  final order = await orderService.createOrder();
                                  _logger.info('Order created successfully: ${order.id}');
                                  
                                  if (!mounted) return;
                                  
                                  // Store context locally
                                  final context = this.context;
                                  
                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: theme.colorScheme.onPrimary),
                                          const SizedBox(width: 8),
                                          const Text('Order placed successfully!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                  
                                  // Navigate to orders screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrdersScreen(token: widget.token),
                                    ),
                                  );
                                  
                                  // Refresh cart
                                  await _loadCartItems();
                                } catch (e) {
                                  _logger.severe('Error in checkout process: $e');
                                  if (!mounted) return;
                                  
                                  String errorMessage = 'Failed to place order';
                                  
                                  // Extract error message from the exception
                                  final errorString = e.toString();
                                  if (errorString.contains('Exception: ')) {
                                    errorMessage = errorString.split('Exception: ')[1];
                                  }
                                  
                                  _logger.info('Showing error message to user: $errorMessage');
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: theme.colorScheme.onError),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(errorMessage)),
                                        ],
                                      ),
                                      backgroundColor: theme.colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                              icon: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.shopping_cart_checkout),
                              label: Text(_isLoading ? 'Processing...' : 'Proceed to Checkout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
