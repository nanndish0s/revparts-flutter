import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:mad_revparts/models/product.dart';
import 'package:mad_revparts/services/products_service.dart';
import 'package:mad_revparts/screens/product_detail_screen.dart';
import 'package:http/http.dart' as http;

class ProductsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProductsScreen({super.key, required this.userData});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductsService _productsService;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebouncer;

  @override
  void initState() {
    super.initState();
    final token = widget.userData['token'] as String?;
    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication token not found';
      });
      return;
    }
    _productsService = ProductsService(token: token);
    _initializeAndFetchProducts();
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
      return;
    }

    final searchQuery = query.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final name = product.name.toLowerCase();
        final description = product.description.toLowerCase();
        return name.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _initializeAndFetchProducts() async {
    if (!mounted) return;

    try {
      // Wait for AuthService to initialize
      await Future.delayed(const Duration(
          milliseconds: 500)); // Give time for SharedPreferences to load
      await _fetchProducts();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error initializing: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final products = await _productsService.fetchProducts();
      if (!mounted) return;

      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);
    // Debug the raw product image path
    print(' Raw Product Image Path: ${product.productImage}');

    // Construct full image URL for Laravel storage
    String? imageUrl = product.productImage;

    // Remove any leading slashes and ensure correct path
    if (imageUrl != null) {
      imageUrl = imageUrl.replaceAll(RegExp(r'^/+'), '');

      // Get the base URL for the Laravel server
      const String baseUrl = 'http://127.0.0.1:8000';

      // Use the proxy endpoint
      imageUrl = '$baseUrl/api/image-proxy/$imageUrl';
    }

    print(' Original Product Image Path: ${product.productImage}');
    print(' Final Constructed URL: $imageUrl');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: product.id,
                token: widget.userData['token'],
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surface,
                          child:
                              Icon(Icons.error, color: theme.colorScheme.error),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surface,
                        child: Icon(Icons.image_not_supported,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.5)),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.category,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.description,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'LKR ${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 16,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Products',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                onChanged: (value) {
                  _searchDebouncer?.cancel();
                  _searchDebouncer =
                      Timer(const Duration(milliseconds: 500), () {
                    _filterProducts(value);
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search,
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts('');
                          },
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
            ),
          ),
          // Products Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: _initializeAndFetchProducts,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              child: _filteredProducts.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'No products available'
                            : 'No products found',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductCard(_filteredProducts[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
