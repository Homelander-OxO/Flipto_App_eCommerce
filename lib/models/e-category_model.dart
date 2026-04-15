import 'dart:convert';

class Category {
  final String id;
  final String name;
  final String image;

  Category({
    required this.id,
    required this.name,
    required this.image,
  });

  // Factory constructor to create a Category from JSON
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['category_id'].toString() ?? '',
      // Default to empty string if 'name' is null
      name: json['categoryName'] ?? '',
      // Default to empty string if 'name' is null
      image: json['category_image'] ??
          '', // Default to empty string if 'name' is null
    );
  }
}

class Student {
  final String id;
  final String name;
  final int no;

  Student({
    required this.id,
    required this.name,
    required this.no,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      no: json['no'],
    );
  }
}

