import 'package:flutter_app/models/e-subcategory_model.dart';

class CartItem {
  final String cartId;
  final String userId;
  final String productId;
  final String quantity;
  final String price;
  final String totalPrice;
  final String addedAt;
  final String updatedAt;
  String? name;
  final ProductDetails image;
  String? size;
  String? color;

  CartItem({
    required this.cartId,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.addedAt,
    required this.updatedAt,
    this.name,
    required this.image,
    this.size,
    this.color,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    print('Raw JSON: $json'); // ✅ Log the raw JSON

    return CartItem(
      cartId: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'] ?? '',
      quantity: json['quantity'] ?? '0',
      price: json['price'] ?? '0.0',
      totalPrice: json['total_price'] ?? '0.0',
      addedAt: json['added_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      name: json['name'] ?? json['product_name'] ?? '', // Try multiple possible keys
      image: ProductDetails.fromJson(
        json['images'] ?? '{"main":[],"colors":{}}',
        json['sizes'] ?? '',
      ),
      color: json['color'] ?? '',
      size: json['size'] ?? '',
    );
  }

}


