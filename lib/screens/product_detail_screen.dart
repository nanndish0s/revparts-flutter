import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logging/logging.dart';

import 'package:mad_revparts/models/product.dart';
import 'package:mad_revparts/services/products_service.dart';
import 'package:mad_revparts/services/cart_service.dart';
import 'package:mad_revparts/screens/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:mad_revparts/theme/theme_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String token;

  const ProductDetailScreen(
      {super.key, required this.productId, required this.token});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductsService _productsService;
  late final CartService _cartService;
  Product? _product;
  bool _isLoading = true;
  String _errorMessage = '';
  int _quantity = 1;
  bool _addingToCart = false;
  final Logger _logger = Logger('ProductDetailScreen');

  @override
  void initState() {
    super.initState();
    _productsService = ProductsService(token: widget.token);
    _cartService = CartService(token: widget.token);
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    try {
      final product =
          await _productsService.fetchProductDetails(widget.productId);

      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _constructImageUrl(String? imagePath) {
    if (imagePath == null) return '';

    // Remove any leading slashes and ensure correct path
    String imageUrl = imagePath.replaceAll(RegExp(r'^/+'), '');

    // Get the base URL for the Laravel server
    const String baseUrl = 'http://127.0.0.1:8000';

    // Use the proxy endpoint
    imageUrl = '$baseUrl/api/image-proxy/$imageUrl';

    // Detailed logging
    _logger.info('🔍 Original Image Path: $imagePath');
    _logger.info('🌐 Final Constructed URL: $imageUrl');

    return imageUrl;
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    setState(() => _addingToCart = true);

    try {
      final cartResponse =
          await _cartService.addToCart(_product!.id, _quantity);
      _logger.info('Adding product to cart: ${_product!.name}');
      _logger.info('Cart response: $cartResponse');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_product!.name} added to cart'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CartScreen(token: widget.token)),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      _logger.severe('Error adding to cart: $e');
      if (mounted) {
        String errorMessage = e.toString();
        // Remove the "Exception: " prefix if it exists
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring('Exception: '.length);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _addingToCart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: theme.colorScheme.onSurface,
              ),
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.shopping_cart, color: theme.colorScheme.onSurface),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => CartScreen(token: widget.token)),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _product != null
          ? FloatingActionButton.extended(
              onPressed: _addingToCart ? null : _addToCart,
              backgroundColor: theme.colorScheme.primary,
              icon: _addingToCart
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.shopping_cart_checkout,
                      color: theme.colorScheme.onPrimary),
              label: Text(
                _addingToCart ? 'Adding...' : 'Add to Cart',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.deepOrange,
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _product == null
                  ? const Center(child: Text('No product found'))
                  : CustomScrollView(
                      slivers: [
                        // Hero Image with Gradient Overlay
                        SliverToBoxAdapter(
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: CachedNetworkImage(
                                  imageUrl: _constructImageUrl(
                                      _product!.productImage),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: theme.colorScheme.surface,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                            size: 30,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image not available',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        theme.colorScheme.background,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Product Details
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Name and Price
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _product!.name,
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '\LKR${_product!.price.toStringAsFixed(2)}',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Quantity Selector
                                Card(
                                  elevation: 0,
                                  color: theme.colorScheme.surfaceVariant,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Quantity',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                if (_quantity > 1) {
                                                  setState(() => _quantity--);
                                                }
                                              },
                                              icon: Icon(
                                                Icons.remove_circle_outline,
                                                color: _quantity > 1
                                                    ? theme.colorScheme.primary
                                                    : theme
                                                        .colorScheme.onSurface
                                                        .withOpacity(0.3),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 40,
                                              child: Text(
                                                _quantity.toString(),
                                                textAlign: TextAlign.center,
                                                style:
                                                    theme.textTheme.titleMedium,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() => _quantity++);
                                              },
                                              icon: Icon(
                                                Icons.add_circle_outline,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Description Section
                                Text(
                                  'Description',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _product!.description ??
                                      'No description available',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    height: 1.5,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Additional Details
                                if (_product!.category != null) ...[
                                  Text(
                                    'Category',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Card(
                                    elevation: 0,
                                    color: theme.colorScheme.surfaceVariant,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.category_outlined,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _product!.category ??
                                                'Uncategorized',
                                            style: theme.textTheme.bodyLarge,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                // Bottom padding for FAB
                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
