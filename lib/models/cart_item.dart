class CartProduct {
  final String id;
  final String name;
  final double price;
  final String? productImage;

  CartProduct({
    required this.id,
    required this.name,
    required this.price,
    this.productImage,
  });

  factory CartProduct.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CartProduct(id: '', name: '', price: 0.0, productImage: null);
    }
    return CartProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 0.0,
      productImage: json['product_image'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'product_image': productImage,
  };
}

class CartItem {
  final String id;
  final String productId;
  final int quantity;
  final CartProduct product;

  CartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CartItem(
        id: '',
        productId: '',
        quantity: 0,
        product: CartProduct(id: '', name: '', price: 0.0, productImage: null),
      );
    }
    
    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      quantity: json['quantity'] is int ? json['quantity'] : 0,
      product: CartProduct.fromJson(json['product'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'quantity': quantity,
    'product': product.toJson(),
  };
}
