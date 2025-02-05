import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mad_revparts/services/auth_service.dart';
import 'package:mad_revparts/screens/login_screen.dart';
import 'package:mad_revparts/screens/products_screen.dart';
import 'package:mad_revparts/services/cart_service.dart';
import 'package:mad_revparts/models/cart_item.dart';
import 'package:mad_revparts/screens/cart_screen.dart';
import 'package:mad_revparts/services/products_service.dart';
import 'package:mad_revparts/models/product.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logging/logging.dart';
import 'package:mad_revparts/models/category.dart';
import 'package:mad_revparts/screens/orders_screen.dart';
import 'package:mad_revparts/theme/theme_provider.dart';
import 'package:mad_revparts/screens/device_features_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  HomeScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Map<String, dynamic> _userData;
  int _selectedIndex = 0;
  late CartService _cartService;
  late ProductsService _productsService;
  List<CartItem> _cartItems = [];
  List<Product> _featuredProducts = [];
  bool _isLoadingFeaturedProducts = true;
  String _featuredProductsError = '';
  final Logger _logger = Logger('HomeScreen');

  @override
  void initState() {
    super.initState();
    _userData = widget.userData;
    _cartService = CartService(token: _userData['token']);
    _productsService = ProductsService(token: _userData['token']);
    _fetchCartItems();
    _fetchFeaturedProducts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchCartItems() async {
    try {
      final cartResponse = await _cartService.getCart();
      if (mounted) {
        setState(() {
          _cartItems = cartResponse.cartItems;
        });
      }
    } catch (e) {
      _logger.severe('Error fetching cart items: $e');
    }
  }

  Future<void> _fetchFeaturedProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoadingFeaturedProducts = true;
      _featuredProductsError = '';
    });

    try {
      final products = await _productsService.fetchProducts();

      // Select top 3 products as featured
      final featuredProducts = products.take(3).toList();

      if (!mounted) return;

      setState(() {
        _featuredProducts = featuredProducts;
        _isLoadingFeaturedProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingFeaturedProducts = false;
        _featuredProductsError = e.toString();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Refresh cart items when cart tab is selected
    if (index == 2) {
      _fetchCartItems();
    }
  }

  // Logout method
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () {
                // Perform logout
                AuthService().logout();

                // Navigate to login screen and remove all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  SliverToBoxAdapter _buildUserWelcomeSection() {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(16),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${_userData['name'] ?? 'User'}!',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUserInfoChip(
                  icon: Icons.email,
                  label: _userData['email'] ?? 'No email',
                ),
                _buildUserInfoChip(
                  icon: Icons.person,
                  label: _userData['role'] ?? 'User',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoChip({required IconData icon, required String label}) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildCategoriesSection() {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Categories',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: category.color,
                        child: Icon(category.icon, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        category.name,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildFeaturedProductsSection() {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Featured Products',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_isLoadingFeaturedProducts)
            Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          else if (_featuredProductsError.isNotEmpty)
            Center(
              child: Text(
                'Error loading featured products: $_featuredProductsError',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            )
          else if (_featuredProducts.isEmpty)
            Center(
              child: Text(
                'No featured products available',
                style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
            )
          else
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: _featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = _featuredProducts[index];

                  return Container(
                    width: 180,
                    margin: EdgeInsets.symmetric(horizontal: 6),
                    child: Card(
                      color: theme.colorScheme.surface,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(10)),
                            child: product.productImage != null
                                ? CachedNetworkImage(
                                    imageUrl: 'http://127.0.0.1:8000/api/image-proxy/${product.productImage!.replaceAll(RegExp(r'^/+'), '')}',
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) => Icon(Icons.error),
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: Icon(Icons.image_not_supported),
                                  ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                SizedBox(height: 4),
                                Text(
                                  product.category ?? 'Automotive Parts',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '\LKR${product.price?.toStringAsFixed(2) ?? "N/A"}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildRecommendedSection() {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Center(
        child: Text(
          'Personalized recommendations coming soon!',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }

  // Get current screen based on index
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return CustomScrollView(
          slivers: [
            _buildUserWelcomeSection(),
            _buildCategoriesSection(),
            _buildFeaturedProductsSection(),
            _buildRecommendedSection(),
          ],
        );
      case 1:
        return ProductsScreen(userData: widget.userData);
      case 2:
        return CartScreen(token: _userData['token']);
      case 3:
        return OrdersScreen(token: _userData['token']);
      default:
        return const Center(child: Text('Screen not found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'RevParts',
              style: TextStyle(
                color: theme.appBarTheme.foregroundColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const Spacer(),
          ],
        ),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: theme.appBarTheme.foregroundColor,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.sensors,
              color: theme.appBarTheme.foregroundColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceFeaturesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.shopping_cart,
              color: theme.appBarTheme.foregroundColor,
            ),
            onPressed: () {
              // Get token from userData
              final token = _userData['token'] as String?;
              if (token != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(token: token),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please log in to access cart',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: theme.appBarTheme.foregroundColor,
            ),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: theme.colorScheme.onSurface),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag, color: theme.colorScheme.onSurface),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, color: theme.colorScheme.onSurface),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, color: theme.colorScheme.onSurface),
            label: 'Orders',
          ),
        ],
      ),
    );
  }

  // Automotive parts categories
  final List<Category> _categories = [
    Category(name: 'Engine', icon: Icons.car_repair, color: Color(0xFFFF4500)),
    Category(name: 'Brakes', icon: Icons.settings, color: Colors.blue),
    Category(name: 'Transmission', icon: Icons.sync, color: Colors.green),
    Category(name: 'Suspension', icon: Icons.height, color: Colors.orange),
    Category(
        name: 'Electrical', icon: Icons.electric_bolt, color: Colors.purple),
    Category(name: 'Body Parts', icon: Icons.directions_car, color: Colors.red),
  ];
}
