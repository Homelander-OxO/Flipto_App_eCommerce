import 'dart:convert'; // Add this import at the top of your file

class Subcategory {
  final String id;
  final String product_id;
  final String name;
  final String type;
  final String gender;
  final String description;
  final String price;
  final String discount;
  final String image;
  final ProductDetails productDetails;
  String? size;
  String? color;
  double? averageRating; // new field

  Subcategory({
    required this.id,
    required this.product_id,
    required this.name,
    required this.type,
    required this.gender,
    required this.description,
    required this.price,
    required this.discount,
    required this.image,
    required this.productDetails,
    this.size,
    this.color,
    this.averageRating,
  });

  // Factory constructor to create a Subcategory from JSON
  factory Subcategory.fromJson(Map<String, dynamic> json) {
    // Handle the image data - it's already a Map, no need to decode
    dynamic imageData = json['product_image'];
    if (imageData is String) {
      try {
        imageData = jsonDecode(imageData);
      } catch (e) {
        imageData = {'main': [], 'colors': {}};
      }
    } else if (imageData == null || imageData is! Map) {
      imageData = {'main': [], 'colors': {}};
    }
    return Subcategory(
      id: json['category_id'],
      product_id: json['product_id'],
      name: json['product_name'],
      type: json['product_type'],
      gender: json['gender_category'],
      description: json['product_desc'],
      price: json['product_price'].toString(),
      discount: json['discount'].toString(),
      image: jsonEncode(imageData), // Encode the map back to string for storage
      size: json['product_size'],
      productDetails: ProductDetails.fromJson(
        imageData,
        json['product_size']?.toString() ?? '',
      ),
    );
  }

  // Add these getters
  List<String> get mainImages {
    try {
      final unescaped = image.replaceAll(r'\/', '/');
      final imageData = jsonDecode(unescaped);
      return (imageData['main'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } catch (e) {
      return [image]; // fallback
    }
  }

  Map<String, String> get colorOptions {
    try {
      final unescaped = image.replaceAll(r'\/', '/');
      final imageData = jsonDecode(unescaped);
      return (imageData['colors'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      return {}; // fallback
    }
  }

  List<String> get allSizes {
    if (productDetails.sizes.isNotEmpty) {
      return productDetails.sizes;
    }
    if (size != null) {
      return size!.split(',').map((s) => s.trim()).toList();
    }
    return [];
  }

  Subcategory copyWith(
      {String? color, String? size, double? rating, String? image}) {
    return Subcategory(
      id: id,
      product_id: product_id,
      name: name,
      type: type,
      gender: gender,
      description: description,
      price: price,
      discount: discount,
      image: image ?? this.image,
      productDetails: productDetails,
      size: size ?? this.size,
      color: color ?? this.color,
    )..averageRating = rating;
  }

  factory Subcategory.empty() => Subcategory(
    id: '',
    product_id: '',
    name: '',
    type: '',
    gender: '',
    description: '',
    price: '',
    discount: '',
    image: '',
    productDetails: ProductDetails(
      sizes: [],
      mainImages: [],
      colorImages: {},
    ),
  );

}

class ProductDetails {
  final List<String> sizes;
  final List<String> mainImages;
  final Map<String, String> colorImages;

  ProductDetails({
    required this.sizes,
    required this.mainImages,
    required this.colorImages,
  });

  factory ProductDetails.fromJson(dynamic imageData, String sizeString) {
    try {
      // Handle case where imageData might be a JSON string
      if (imageData is String) {
        imageData = jsonDecode(imageData);
      }

      final mainImages = (imageData['main'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];

      final colorData = imageData['colors'];
      final colorImages = (colorData is Map)
          ? colorData.map<String, String>(
              (key, value) => MapEntry(key.toString(), value.toString()))
          : <String, String>{};

      final sizes = sizeString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      return ProductDetails(
        sizes: sizes,
        mainImages: mainImages,
        colorImages: colorImages,
      );
    } catch (e) {
      print('❌ Error parsing product details: $e');
      return ProductDetails(
        sizes: sizeString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        mainImages: [],
        colorImages: {},
      );
    }
  }
}

Map<String, String> genderImages = {
  "Men": "assets/images/men.png",
  "Women": "assets/images/women.png",
  "Kids": "assets/images/kids.png",
};

// class CartItem extends Subcategory {
//   int quantity;
//
//   CartItem({
//     required String id,
//     required String product_id,
//     required String name,
//     required String type,
//     required String gender,
//     required String description,
//     required String price,
//     required String image,
//     required this.quantity,
//   }) : super(
//           id: id,
//           product_id: product_id,
//           name: name,
//           type: type,
//           gender: gender,
//           description: description,
//           price: price,
//           image: image,
//         );
//
//   // Factory constructor to create CartItem from JSON
//   factory CartItem.fromJson(Map<String, dynamic> json) {
//     return CartItem(
//       id: json['id'],
//       product_id: json['product_id'],
//       name: json['product_name'],
//       type: json['product_type'],
//       gender: json['gender_category'],
//       description: json['product_desc'],
//       price: json['product_price'].toString(),
//       image: json['product_image'],
//       quantity: int.parse(json['quantity'] ?? '1'),
//     );
//   }
// }
