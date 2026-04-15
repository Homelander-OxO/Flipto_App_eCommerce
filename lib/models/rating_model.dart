import 'package:flutter/material.dart';

class ProductRating {
  final String rid;
  final String userId;
  final String productId;
  final String rating;
  final double? ratings;
  final String review;
  final List<String> images;
  final String createdAt;
  final String updatedAt;

  ProductRating({
    required this.rid,
    required this.userId,
    required this.productId,
    required this.rating,
    this.ratings,
    required this.review,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductRating.fromJson(Map<String, dynamic> json) {
    // Debug the incoming json
    print("Creating ProductRating from JSON: $json");

    // Handle images - could be a string, array, or null
    List<String> imageList = [];
    var imageData = json['image'];

    if (imageData != null) {
      if (imageData is String) {
        if (imageData.isNotEmpty) {
          imageList = imageData.split(',');
        }
      } else if (imageData is List) {
        imageList = imageData.map((item) => item.toString()).toList();
      }
    }

    // Parse rating carefully
    final ratingString = json['rating']?.toString() ?? '0';
    final ratingDouble = double.tryParse(ratingString) ?? 0.0;

    print("Parsed rating: string=$ratingString, double=$ratingDouble");

    return ProductRating(
      rid: json['rid'] ?? '',
      userId: json['user_id'] ?? '',
      productId: json['product_id'] ?? '',
      rating: ratingString,
      ratings: ratingDouble,
      review: json['review'] ?? '',
      images: imageList,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

// Add this static method for creating an empty review
  static ProductRating empty() {
    return ProductRating(
      rid: '',
      userId: '',
      productId: '',
      rating: '0',
      ratings: 0,
      review: '',
      images: [],
      createdAt: '',
      updatedAt: '',
    );
  }

  // Add this helper method to check if the review is empty
  bool get isEmpty => rid.isEmpty;
}

class RatedProduct {
  final String productId;
  final String productName;
  final String productImage;
  final ProductRating review;

  RatedProduct({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.review,
  });
}

class StarRating extends StatelessWidget {
  final double rating;
  final double starSize;

  const StarRating({
    Key? key,
    required this.rating,
    this.starSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.green,
          size: starSize,
        );
      }),
    );
  }
}
