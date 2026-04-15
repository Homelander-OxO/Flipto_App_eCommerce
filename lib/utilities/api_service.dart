import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_app/models/address_model.dart';
import 'package:flutter_app/models/cart_items.dart';
import 'package:flutter_app/models/profile_model.dart';
import 'package:flutter_app/models/rating_model.dart';
import 'package:flutter_app/config/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/e-category_model.dart';
import '../models/e-subcategory_model.dart';

class ApiService {

  // static String baseUrl = "http://10.30.226.167/Apis/";
  static String baseUrl = '${AppConfig.baseUrl}/Apis/';
  // static String baseUrl = "http://flipto.kesug.com/Apis/?i=1";

  // Static list of keywords for suggestions
  static final List<String> searchKeywords = [
    "fruits",
    "green",
    "amul",
    "apple",
    "banana",
    "milk",
    "bread",
    "eggs",
    "chicken",
    "rice",
    "pasta",
    "tomato",
    "potato",
    "onion",
    "cheese",
    "yogurt",
    "orange juice",
    "coffee",
    "tea",
    "sugar",
    "flour",
    "oil",
    "butter",
    "T-shirt",
    "jeans",
    "laptop",
    "laptop HP",
    "laptop DELL",
    "headphones",
    "camera",
    "earbuds",
    "boat",
    "boat earbuds",
    "home and furniture",
    "home",
    "furniture",
    "shoes",
  ];

  // Search products API method
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final url = Uri.parse("$baseUrl/searchProduct");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          "query": query,
        },
      );

      print('SEARCH RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);

        // Handle both array and single object responses
        if (decodedResponse is List) {
          return decodedResponse.map<Map<String, dynamic>>((item) {
            return Map<String, dynamic>.from(item);
          }).toList();
        } else if (decodedResponse is Map) {
          return [Map<String, dynamic>.from(decodedResponse)];
        }
        return [];
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (error) {
      print('SEARCH ERROR: $error');
      throw Exception('Failed to connect to server: $error');
    }
  }

  static Future<List<Subcategory>> fetchProducts() async {
    final url = Uri.parse("$baseUrl/showProducts");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Subcategory.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addUser(
      String fullName, String email) async {
    final url = Uri.parse("$baseUrl/addUser");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          "full_name": fullName,
          "email": email,
        },
      );

      print('RESPONSE: ${response.body}'); // Debugging

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decodedResponse; // Return API response directly
      } else {
        return {
          "success": false,
          "message": decodedResponse.containsKey("Failure")
              ? decodedResponse["Failure"]
              : "Failed to add user",
        };
      }
    } catch (error) {
      return {
        "success": false,
        "message": "Something went wrong",
        "error": error.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> addReview({
    required String email,
    required String productId,
    required String rating,
    required String reviewT,
    required String reviewM,
    required List<File> images, // Now accepts List<File>
  }) async {
    final url = Uri.parse("$baseUrl/addReview");

    try {
      var request = http.MultipartRequest('POST', url);

      // Add text fields
      request.fields.addAll({
        'email': email,
        'product_id': productId,
        'rating': rating,
        'reviewT': reviewT,
        'reviewM': reviewM,
      });

      // Add image files
      for (var imageFile in images) {
        var file = await http.MultipartFile.fromPath(
          'images[]', // PHP array format
          imageFile.path,
        );
        request.files.add(file);
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('Add Review Response: $responseString');

      final decodedResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        return {
          "success": false,
          "message": decodedResponse.containsKey("message")
              ? decodedResponse["message"]
              : "Failed to add review",
        };
      }
    } catch (error) {
      debugPrint('Error in addReview: $error');
      return {
        "success": false,
        "message": "Something went wrong",
        "error": error.toString(),
      };
    }
  }

  // Add this to your ApiService class
  static Future<Map<String, dynamic>> getProductRatings(
      String productId) async {
    final url = Uri.parse("${baseUrl}getRR/$productId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        return Map<String, dynamic>.from(decodedResponse);
      } else {
        throw Exception('Failed to load ratings: ${response.statusCode}');
      }
    } catch (error) {
      print('RATINGS ERROR: $error');
      throw Exception('Failed to connect to server: $error');
    }
  }

  static Future<List<ProductRating>> fetchReviews(String email) async {
    final url = Uri.parse("${baseUrl}fetchReview");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
        },
      );

      print('REVIEWS RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle both single review and multiple reviews
        if (responseData is List) {
          return responseData
              .map<ProductRating>((json) => ProductRating.fromJson(json))
              .toList();
        } else if (responseData is Map<String, dynamic>) {
          return [ProductRating.fromJson(responseData)];
        } else if (responseData is Map) {
          // Handle case where it's Map<dynamic, dynamic>
          return [
            ProductRating.fromJson(Map<String, dynamic>.from(responseData))
          ];
        }
        return [];
      } else {
        throw Exception('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (error) {
      print('FETCH REVIEWS ERROR: $error');
      throw Exception('Failed to connect to server: $error');
    }
  }

  static Future<ProductRating?> fetchReviewById(String rid) async {
    final url = Uri.parse("${baseUrl}editReviewM/$rid");

    try {
      final response = await http.get(url);
      print('RESPONSE for rid $rid: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Direct parsing if the API returns the review object directly
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('rid')) {
            // The response is directly the review object
            return ProductRating.fromJson(responseData);
          } else if (responseData['success'] == true &&
              responseData['data'] != null) {
            // The response has a data field containing the review
            return ProductRating.fromJson(responseData['data']);
          }
        }
      }
      return null;
    } catch (e) {
      print('Error fetching review by ID: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    required String rating,
    required String productId,
    required String reviewM,
    required List<File> images,
    List<String>? previousImages,
  }) async {
    final url = Uri.parse('$baseUrl/updateReview');

    final request = http.MultipartRequest('POST', url)
      ..fields['rid'] = reviewId
      ..fields['rating'] = rating
      ..fields['product_id'] = productId
      ..fields['reviewM'] = reviewM;

    if (previousImages != null && previousImages.isNotEmpty) {
      for (int i = 0; i < previousImages.length; i++) {
        request.fields['previous_images[$i]'] = previousImages[i];
      }
      // OR if your API supports it as JSON
      // request.fields['previous_images'] = jsonEncode(previousImages);
    }

    for (var image in images) {
      final imageFile =
          await http.MultipartFile.fromPath('images[]', image.path);
      request.files.add(imageFile);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Request Fields: ${request.fields}');
    print('Response: ${response.body}');

    if (response.statusCode == 200) {
      final body = response.body.trim();

      if (body.toLowerCase().contains('success')) {
        return {'success': 'true', 'message': 'Review updated successfully'};
      }

      try {
        final json = jsonDecode(body);
        return json.map((k, v) => MapEntry(k.toString(), v.toString()));
      } catch (e) {
        print('JSON decode error: $e');
        return {'success': 'false', 'message': 'Invalid JSON response'};
      }
    }

    return {
      'success': 'false',
      'message': 'Server error: ${response.statusCode}'
    };
  }

  // Method to remove review
  static Future<bool> removeReview(String email, String rid) async {
    final url = Uri.parse("$baseUrl/removeReview");

    try {
      final response = await http.post(
        url,
        body: {
          'email': email,
          'rid': rid,
        },
      );
      print('Response: ${response.body}');
      if (response.statusCode == 200) {
        return true; // Successfully removed
      } else {
        throw Exception('Failed to remove review: ${response.statusCode}');
      }
    } catch (error) {
      print('Remove review error: $error');
      throw Exception('Failed to connect to server: $error');
    }
  }

  static Future<bool> sendOtp(String email) async {
    final url = Uri.parse('$baseUrl/generateOtp');
    try {
      final response = await http.post(
        url,
        body: {
          'email': email,
          // 'full_name': username, // Send username along with email
        },
      );

      print('Send OTP Response: ${response.body}');

      if (response.statusCode == 200) {
        return response.body ==
            'Success'; // Return true if OTP is sent successfully
      } else {
        print("Server returned non-200 status code: ${response.statusCode}");
        return false;
      }
    } catch (error) {
      print('Error sending OTP: $error');
      return false;
    }
  }

  // Method to verify OTP
  static Future<Map<String, dynamic>> verifyOtp(
      String email, String otp) async {
    final url = Uri.parse('$baseUrl/verifyOtpM');
    try {
      final response = await http.post(
        url,
        body: {
          'email': email,
          'otp': otp,
        },
      );

      print('Verify OTP Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': responseData["Success"] == "Login Successful!",
          'data': responseData
        };
      }
      return {'success': false, 'data': null};
    } catch (error) {
      print('Error verifying OTP: $error');
      return {'success': false, 'data': null};
    }
  }

  static Future<UserDetailsModel> updateUserProfileMultipart({
    required String fullName,
    required String email,
    required String user_id,
    File? imageFile,
  }) async {
    final url = Uri.parse("$baseUrl/updateUser");

    // Print debug information
    print('Sending update for user $user_id');
    print('Image file provided: ${imageFile != null}');

    var request = http.MultipartRequest('POST', url)
      ..fields['full_name'] = fullName
      ..fields['email'] = email
      ..fields['user_id'] = user_id;

    if (imageFile != null) {
      print('Attaching image file: ${imageFile.path}');
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        filename: 'user_$user_id.jpg', // Consistent filename
      ));
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Handle both JSON and plain text responses
        if (response.body.trim().startsWith('{')) {
          return UserDetailsModel.fromJson(jsonDecode(response.body));
        } else {
          // For plain text responses like "Data Updated!!!"
          // Fetch fresh user data from server
          final user = await ApiService().fetchUserDetails(email);
          if (user != null) {
            return user;
          }
          throw Exception(
              'Update successful but failed to fetch updated profile');
        }
      } else {
        throw Exception('Server responded with status ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateUserProfileMultipart: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> addAddress({
    required String email,
    required String contact,
    required String apartmentNo,
    required String street,
    required String area,
    required String city,
    required String pincode,
  }) async {
    final Uri url = Uri.parse('$baseUrl/address');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          "email": email,
          "contact": contact,
          "apartment_no": apartmentNo,
          "street": street,
          "area": area,
          "city": city,
          "pincode": pincode,
        },
      );

      print('Add Address Response: ${response.body}'); // Debugging

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decodedResponse; // Return API response
      } else {
        return {
          "success": false,
          "message": decodedResponse.containsKey("Failure")
              ? decodedResponse["Failure"]
              : "Failed to add address",
        };
      }
    } catch (error) {
      return {
        "success": false,
        "message": "Something went wrong",
        "error": error.toString(),
      };
    }
  }

  static Future<List<Address>> showAddress(String email) async {
  final Uri url = Uri.parse('$baseUrl/showAddress');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {"email": email},
    );

    print("Show Address Response: ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      String contact = data["contact"] ?? "";
      
      List<Address> addresses = [];
      data.forEach((key, value) {
        if (key != "contact" && value is Map<String, dynamic>) {
          addresses.add(Address.fromJson(key, {
            ...value,
            "contact": contact // Include contact in each address
          }));
        }
      });
      
      return addresses;
    } else {
      return [];
    }
  } catch (error) {
    print("Error fetching addresses: $error");
    return [];
  }
}

  static Future<bool> deleteAddress(String email, int index) async {
    final Uri url = Uri.parse('$baseUrl/delete_address');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {"email": email, "index": index.toString()},
      );

      print("Delete Address Response: ${response.body}"); // Debugging

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.containsKey("success") &&
            data["success"] == "Address deleted successfully";
      }
      return false;
    } catch (error) {
      print("Error deleting address: $error");
      return false;
    }
  }

  static Future<Map<String, dynamic>> updateAddress({
    required String email,
    required int index,
    required String contact,
    required String apartmentNo,
    required String street,
    required String area,
    required String city,
    required String pincode,
  }) async {
    final Uri url = Uri.parse('$baseUrl/updateAddress');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "email": email,
          "index": index.toString(),
          "contact": contact,
          "apartment_no": apartmentNo,
          "street": street,
          "area": area,
          "city": city,
          "pincode": pincode,
        },
      );

      print("Update Address Response: ${response.body}");

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
    } catch (error) {
      print("Error updating address: $error");
      return {"error": error.toString()};
    }
  }

  Future<UserDetailsModel?> fetchUserDetails(String email) async {
    final Uri url = Uri.parse('$baseUrl/findUser');

    try {
      final response = await http.post(
        url,
        body: {'email': email},
      );

      print("CODE: ${response.statusCode}");
      print("RESPONSE: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return UserDetailsModel.fromJson(responseData);
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }

    return null; // Return null if fetching fails
  }

  // static Future<List<Subcategory>> searchProducts(String categoryId, String query) async {
  //   final String apiUrl = '$baseUrl/findProducts';
  //
  //   final response = await http.post(
  //     Uri.parse(apiUrl),
  //     body: {"category_id": categoryId}, // Only sending category ID
  //   );
  //
  //   print("API Response: ${response.body}");
  //
  //   if (response.statusCode == 200) {
  //     List<dynamic> data = jsonDecode(response.body);
  //     List<Subcategory> allProducts = data.map((subcategory) => Subcategory.fromJson(subcategory)).toList();
  //
  //     // Filter products based on search query
  //     List<Subcategory> filteredProducts = allProducts.where((product) {
  //       return product.name.toLowerCase().contains(query.toLowerCase());
  //     }).toList();
  //
  //     return filteredProducts;
  //   } else {
  //     throw Exception('Failed to load products');
  //   }
  // }

  static Future<List<Subcategory>> searchProducts1(
      List<String> categoryIds, String query) async {
    final String apiUrl = '$baseUrl/findProducts';

    List<Subcategory> allProducts = [];

    for (String categoryId in categoryIds) {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {"category_id": categoryId},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Subcategory> products = data
            .map((subcategory) => Subcategory.fromJson(subcategory))
            .toList();

        allProducts.addAll(products);
      } else {
        print("Error fetching category $categoryId: ${response.statusCode}");
      }
    }

    // Filter products based on search query
    List<Subcategory> filteredProducts = allProducts.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return filteredProducts;
  }

  static Future<List<Category>> fetchCategories() async {
    // Define the API link for fetching categories
    final String apiUrl = '$baseUrl/showCategory'; // Add your API link here

    final response = await http.get(Uri.parse(apiUrl));
    print('API Response: ${response.body}');

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((category) => Category.fromJson(category)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Static method to fetch subcategories from API
  static Future<List<Subcategory>> fetchSubcategories(String id) async {
    final String apiUrl = '$baseUrl/findProducts';

    final response = await http.post(
      Uri.parse(apiUrl),
      body: {"category_id": id},
    );

    print("API Response: ${response.body}"); // Log the API response
    //print("Category ID: ${id}");

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      return data
          .map((subcategory) => Subcategory.fromJson(subcategory))
          .toList();
    } else {
      print("Error: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to load subcategories');
    }
  }

  static Future<List<Subcategory>> fetchAllProducts(
      List<String> categoryIds) async {
    final String apiUrl = '$baseUrl/findProducts';
    List<Subcategory> allProducts = [];

    for (String id in categoryIds) {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {"category_id": id},
      );

      print("API Response for Category $id: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        allProducts.addAll(data
            .map((subcategory) => Subcategory.fromJson(subcategory))
            .toList());
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
      }
    }

    return allProducts;
  }

  Future<bool> addToCart(String email, String productId,
      {String? color, String? size}) async {
    try {
      var url = Uri.parse('$baseUrl/addCart');
      var body = {
        "user_id": email,
        "product_id": productId,
        "color": color?.trim() ?? ' ',
        "size": size?.trim() ?? ' ',
      };

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          // Try to parse as JSON
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] == true) {
            print('✅ Product added to cart successfully');
            return true;
          }
        } catch (e) {
          // If not JSON, fall back to string check
          if (response.body.toLowerCase().contains('success') ||
              response.body.toLowerCase().contains('insert into')) {
            print('✅ Product added to cart successfully');
            return true;
          }
        }
        print('❌ API returned 200 but indicated failure: ${response.body}');
        return false;
      } else {
        print('❌ Failed with status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('🚨 Network error: $e');
      return false;
    }
  }

  Future<List<CartItem>> searchCart(String userId) async {
    try {
      var url = Uri.parse('$baseUrl/searchCart');

      var body = {
        "user_id": userId,
      };

      var response = await http.post(
        url,
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // ✅ Check if 'cart' is present and is a list
        if (data['cart'] is List) {
          return data['cart']
              .map<CartItem>((item) => CartItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('🚨 Error fetching cart: $e');
      return [];
    }
  }

  static Future<void> downloadInvoice(String orderId) async {
    try {
      // 1. Clean and validate orderId
      final cleanOrderId = orderId.replaceAll('order_', '').trim();
      if (cleanOrderId.isEmpty) {
        throw Exception('Invalid order ID format');
      }

      // 2. Print the URL for debugging
      final url = Uri.parse('$baseUrl/download_invoice/$cleanOrderId');
      debugPrint('Attempting to download from: $url');

      // 3. Check permissions (your existing code is fine)
      final isAndroid = Platform.isAndroid;
      final isAndroidQOrAbove = isAndroid &&
          await DeviceInfoPlugin()
              .androidInfo
              .then((info) => info.version.sdkInt >= 29);

      PermissionStatus status;
      if (isAndroidQOrAbove) {
        status = await Permission.manageExternalStorage.request();
      } else {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        if (status.isPermanentlyDenied) await openAppSettings();
        throw Exception('Storage permission required');
      }

      // 4. Make the request with timeout
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/invoice_$cleanOrderId.pdf';
        await File(filePath).writeAsBytes(response.bodyBytes);
        await OpenFile.open(filePath);
      } else {
        throw Exception('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Invoice download failed: $e');
      rethrow;
    }
  }

  // static Future<void> _showDownloadCompleteNotification(
  //     String filePath, String orderId) async {
  //   const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //       AndroidNotificationDetails(
  //     'download_channel',
  //     'Downloads',
  //     importance: Importance.high,
  //     priority: Priority.high,
  //     showWhen: false,
  //   );
  //
  //   const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics,
  //   );
  //
  //   await FlutterLocalNotificationsPlugin().show(
  //     0,
  //     'Invoice Downloaded',
  //     'Tap to open invoice #$orderId',
  //     platformChannelSpecifics,
  //     payload: filePath,
  //   );
  // }

// ✅ Update Cart Quantity
  static Future<void> updateCart(
      String cartId, String productId, int quantity, String price) async {
    String apiUrl = '$baseUrl/updateCart';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'id': cartId,
          'product_id': productId,
          'quantity': quantity.toString(),
          'price': price,
        },
      );

      if (response.statusCode == 200) {
        print('✅ Update Cart Response: ${response.body}');
      } else {
        print('🚨 Failed to update cart: ${response.body}');
      }
    } catch (e) {
      print('🚨 Error updating cart: $e');
    }
  }

// ✅ Remove Cart Item
  static Future<void> removeCart(String cartId) async {
    String apiUrl = '$baseUrl/removeCart';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'cart_id': cartId},
      );

      if (response.statusCode == 200) {
        print('✅ Remove Cart Response: ${response.body}');
      } else {
        print('🚨 Failed to remove cart: ${response.body}');
      }
    } catch (e) {
      print('🚨 Error removing cart: $e');
    }
  }

  static Future<void> emptyCart(String userId) async {
    final url = '$baseUrl/emptyCart';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'user_id': userId,
        },
      );
      print('RESPONSE: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Cart Emptied Successfully');
        } else {
          print('❌ Failed to Empty Cart');
        }
      } else {
        print('❌ Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  // Add to wishlist
  static Future<bool> addToWishlist(String email, String productId) async {
    final url = Uri.parse("$baseUrl/addWishlist");

    print('STARTING ADD TO WISHLIST: email=$email, productId=$productId');

    try {
      print('SENDING REQUEST to $url');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          "email": email,
          "product_id": productId,
        },
      );

      print('RESPONSE STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY RAW: "${response.body}"');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        print('TRIMMED RESPONSE: "$responseBody"');

        // Look for "Data Successfully Stored" specifically
        if (responseBody == "Data Successfully Stored") {
          print('SUCCESS DETECTED in response');
          return true;
        } else {
          print('FAILURE DETECTED: $responseBody');
          return false;
        }
      } else {
        print('NON-200 STATUS CODE: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      print('ADD TO WISHLIST COMPLETE ERROR: $error');
      return false;
    }
  }

// Add the removeFromWishlist function if you don't have it yet
  static Future<bool> removeFromWishlist(String email, String productId) async {
    final url = Uri.parse("$baseUrl/removeWishlist");

    print('STARTING REMOVE FROM WISHLIST: email=$email, productId=$productId');

    try {
      print('SENDING REQUEST to $url');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          "email": email,
          "product_id": productId,
        },
      );

      print('RESPONSE STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY RAW: "${response.body}"');

      if (response.statusCode == 200) {
        final responseBody = response.body.trim();
        print('TRIMMED RESPONSE: "$responseBody"');

        // Look for success message
        if (responseBody.contains("Successfully") ||
            responseBody.contains("successfully") ||
            responseBody.contains("removed") ||
            responseBody.contains("Removed")) {
          print('SUCCESS DETECTED in response');
          return true;
        } else {
          print('FAILURE DETECTED: $responseBody');
          return false;
        }
      } else {
        print('NON-200 STATUS CODE: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      print('REMOVE FROM WISHLIST COMPLETE ERROR: $error');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getWishlist(String email) async {
    final url = Uri.parse("$baseUrl/wishlist");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          "email": email,
        },
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];

        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded.containsKey('wishlists')) {
          // ✅ Extract only the list of wishlist items
          return List<Map<String, dynamic>>.from(decoded['wishlists']);
        }

        // Other legacy cases (optional fallback)
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
      }

      return [];
    } catch (e) {
      print('EXCEPTION GETTING WISHLIST: $e');
      return [];
    }
  }

  // static Future<ProfileModel?> fetchLogin(String email, String password) async {
  //   // final url = Uri.parse("http://192.168.1.160/Apis/login"); // Ensure URL is correct
  //   final String apiUrl = '$baseUrl/login';
  //   print("🌐 Calling API: $apiUrl");
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       body: {
  //         "email": email,
  //         "password": password,
  //       },
  //     );
  //
  //     print("📝 Raw Response: ${response.body}");
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //
  //       if (data.containsKey("Success") && data.containsKey("Data")) {
  //         print("✅ Login Successful! Extracting user data...");
  //         return ProfileModel.fromJson(
  //             data["Data"]); // Correctly parse user data
  //       } else {
  //         print("❌ Login Failed: ${data["message"] ?? "Unknown error"}");
  //         return null;
  //       }
  //     } else {
  //       print("❌ Server Error: ${response.statusCode} - ${response.body}");
  //       return null;
  //     }
  //   } catch (e) {
  //     print("❌ API Call Exception: $e");
  //     return null;
  //   }
  // }

  static String? razorpayOrderId; // Store Razorpay order ID globally
  static Map<String, dynamic>?
      razorpayOrderResponse; // Variable to store the full response

  static Future<PaymentRequest?> buyNow(double amount) async {
    final String apiUrl = '$baseUrl/razorPay';

    // Ensure amount is a valid integer
    int amountInPaisa = amount.round();
    print("Attempting API call with amount: $amountInPaisa");

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'price': amountInPaisa.toString()}, // Send as form-encoded
    ).timeout(
      Duration(seconds: 10), // Add timeout
      onTimeout: () {
        print('API call timed out');
        return http.Response('Timeout', 408);
      },
    );

    print("Response Status Code: ${response.statusCode}");
    print("Response Headers: ${response.headers}");
    print("Full Response Body: ${response.body}");

    if (response.statusCode == 200) {
      var responseBody = json.decode(response.body);

      // Store the `order_id` from the response
      razorpayOrderId = responseBody['id'];
      print("Stored Razorpay Order ID: $razorpayOrderId");

      // Store the full Razorpay order response
      razorpayOrderResponse = responseBody;
      print("Stored Razorpay Order Response: $razorpayOrderResponse");

      return PaymentRequest.fromJson(responseBody);
    } else {
      print("API Error Details:");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      return null;
    }
  }

  static Future<void> storePaymentData({
    required Map<String, dynamic> order,
    required String userId,
    required List<String> productIds,
    required List<String> amounts,
    required List<int> quantity,
    required Map<String, dynamic> addressDetails,
    required List<String> colors,
    required List<String> sizes,
  }) async {
    if (razorpayOrderResponse == null) {
      print("Error: No Razorpay order response stored!");
      return;
    }

    // Create the formatted address string
    final formattedAddress = '${addressDetails['apartmentNo']}, '
        '${addressDetails['street']}, '
        '${addressDetails['area']}, '
        '${addressDetails['city']}, '
        '${addressDetails['pincode']}';

    // Prepare the data in the format your backend expects
    final formData = {
      'order': jsonEncode(razorpayOrderResponse),
      'user_id': userId,
      'product_id': jsonEncode(productIds),
      'amount': jsonEncode(amounts),
      'quantity': jsonEncode(quantity),
      'colors': jsonEncode(colors),
      'sizes': jsonEncode(sizes),
      'discount': '0', // Send as a single string value, not an array
      'selectedAddress': jsonEncode({
        'apartmentNo': addressDetails['apartmentNo'],
        'street': addressDetails['street'],
        'area': addressDetails['area'],
        'city': addressDetails['city'],
        'pincode': addressDetails['pincode'],
        'contact': addressDetails['contact'],
        'formattedAddress': formattedAddress,
      }),
    };

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/addOrders"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData,
      );
      print('Request Body: $formData');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      if (response.statusCode == 200) {
        print("Success! API returned: ${response.body}");
      } else {
        print("Error: ${response.statusCode}");
        throw Exception('Failed to store payment data');
      }
    } catch (e) {
      print('Exception: $e');
      rethrow;
    }
  }

  static Future<void> sendFCMNotification({
    String title = '',
    String main = '',
    required String deviceToken,
    required String userId,
  }) async {
    final formData = {
      'deviceToken': deviceToken,
      'title': title,
      'main': main,
      'user_id': userId
    };

    // Remove null values from the formData
    formData.removeWhere((key, value) => value == null);

    final String apiUrl = '$baseUrl/fcm';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: formData,
      );

      print('FCM Request Body: $formData');
      print('FCM Response Status: ${response.statusCode}');
      print('FCM Response: ${response.body}');

      if (response.statusCode == 200) {
        print("✅ FCM Notification Sent!");
      } else {
        print("❌ Error sending FCM: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Exception while sending FCM: $e');
      rethrow; // Re-throw the exception so it can be caught upstream
    }
  }

  static Future<void> addTransaction({
    required String paymentId,
  }) async {
    if (razorpayOrderId == null) {
      print("Error: No Razorpay Order ID stored!");
      return;
    }

    // Store data in a variable
    final transactionData = {
      'razorpay_order_id': razorpayOrderId!,
      'razorpay_payment_id': paymentId,
    };

    // Assign it as the value of 'response' key
    final formData = {
      'response': jsonEncode(transactionData),
    };

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/addTransaction"),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData,
      );

      print('Request Body: $formData');
      print('Response Body: ${response.body}');
      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print("✅ Transaction successfully added!");
      } else {
        print("❌ Error adding transaction: ${response.statusCode}");
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  static Future<Map<String, dynamic>?> fetchTrackingData(String email) async {
    final String apiUrl = '$baseUrl/shipHistory';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'email': email},
      );

      print("Tracking API Response: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Error fetching tracking data: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception while fetching tracking data: $e");
      return null;
    }
  }

  static Future<void> googleSignIn() async {
    GoogleSignIn googleSignIn = GoogleSignIn(); // Create GoogleSignIn instance

    try {
      // Sign in the user
      GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        print("User canceled Google sign-in.");
        return;
      }

      // Obtain the authentication token
      GoogleSignInAuthentication authentication = await account.authentication;
      String? idToken = authentication.idToken;
      print("Google ID Token: $idToken");

      // Call the API with the token
      final response = await http.post(
        Uri.parse("$baseUrl/googleSignIn"),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': idToken,
        }),
      );

      if (response.statusCode == 200) {
        print("Google sign-in successful: ${response.body}");
      } else {
        print("Failed to sign in with Google: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during Google Sign-In: $e");
    }
  }
}

class PaymentRequest {
  final int amountInPaisa;
  final String orderId;

  PaymentRequest({
    required this.amountInPaisa,
    required this.orderId,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      amountInPaisa: json['amount'] ?? 0,
      orderId: json['id'] ?? '',
    );
  }
}

class RazorpayResponseModel {
  String id;
  String entity;
  double amount;
  String currency;
  String status;
  String method;

  RazorpayResponseModel({
    required this.id,
    required this.entity,
    required this.amount,
    required this.currency,
    required this.status,
    required this.method,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity': entity,
      'amount': amount,
      'currency': currency,
      'status': status,
      'method': method,
    };
  }

  static RazorpayResponseModel fromJson(Map<String, dynamic> json) {
    return RazorpayResponseModel(
      id: json['id'],
      entity: json['entity'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'],
      status: json['status'],
      method: json['method'],
    );
  }
}
