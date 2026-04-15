import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/API%20E-Commerce/Model/e-subcategory_model.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class RecommendationService {
  late Interpreter _interpreter;
  late Box _userBehaviorBox;
  late Map<String, dynamic> _productInfo;
  late int _numProducts;
  late List<String> _productIds;

  bool _isInitialized = false;
  String? _currentUserId;
  final cartProvider = CartProvider();

  Future<void> init(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;

    try {
      _currentUserId = userId;
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);

      // Use a separate box per user
      _userBehaviorBox = await Hive.openBox('userBehavior_$userId');

      final modelPath =
          await _getModelPath('recommendation_model_compatible.tflite');
      final options = InterpreterOptions()..threads = 2;
      _interpreter =
          await Interpreter.fromFile(File(modelPath), options: options);

      final jsonStr =
          await rootBundle.loadString('assets/models/product_info.json');
      final jsonMap = json.decode(jsonStr);
      _productInfo = jsonMap['product_mapping'] ?? {};
      _productIds = List<String>.from(jsonMap['encoder_classes'] ?? []);
      _numProducts = _productIds.length;

      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize recommendation service: $e');
      // Initialize with empty data instead of throwing
      _productInfo = {};
      _productIds = [];
      _isInitialized = true;
    }
  }

  Future<String> _getModelPath(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/$modelName';
    if (!await File(modelPath).exists()) {
      final byteData = await rootBundle.load('assets/models/$modelName');
      await File(modelPath).writeAsBytes(byteData.buffer.asUint8List());
    }
    return modelPath;
  }

  Map<String, Subcategory>? _cachedProductMap;

  // Update getProductMapById to use caching
  Future<Map<String, Subcategory>> getProductMapById() async {
    if (_cachedProductMap != null) return _cachedProductMap!;

    // These should be the actual category IDs you want to include
    final categoryIds = ['3', '4', '5', '6', '7', '8'];
    final products = await ApiService.fetchAllProducts(categoryIds);

    _cachedProductMap = {
      for (var product in products) product.product_id.toString(): product,
    };
    return _cachedProductMap!;
  }

  // Add method to get products list when needed
  Future<List<Subcategory>> getAllProducts() async {
    final map = await getProductMapById();
    return map.values.toList();
  }

  // Clear cache when needed
  void clearProductCache() {
    _cachedProductMap = null;
  }

  Future<void> trackUserAction(
      String userId, String productId, String actionType) async {
    if (!_isInitialized || _currentUserId != userId) {
      await init(userId);
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _userBehaviorBox.add({
        'productId': productId,
        'action': actionType,
        'timestamp': timestamp,
      });
    } catch (e) {
      print('Error tracking user action: $e');
    }
  }

  Future<void> syncUserWishlist(String userId, List<String> productIds) async {
    if (!_isInitialized || _currentUserId != userId) {
      await init(userId);
    }

    try {
      // Clear existing wishlist actions
      final wishlistActions = _filterActions('wishlist');
      for (var i = 0; i < wishlistActions.length; i++) {
        final key = wishlistActions[i]['key'];
        if (key != null) {
          await _userBehaviorBox.delete(key);
        }
      }

      // Add current wishlist items
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      for (var productId in productIds) {
        await _userBehaviorBox.add({
          'productId': productId,
          'action': 'wishlist',
          'timestamp': timestamp,
        });
      }
    } catch (e) {
      print('Error syncing wishlist: $e');
    }
  }

  Future<void> syncUserOrders(String userId, List<String> productIds) async {
    if (!_isInitialized || _currentUserId != userId) {
      await init(userId);
    }

    try {
      // Clear existing purchase actions
      final orderActions = _filterActions('purchase');
      for (var i = 0; i < orderActions.length; i++) {
        final key = orderActions[i]['key'];
        if (key != null) {
          await _userBehaviorBox.delete(key);
        }
      }

      // Add current orders
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      for (var productId in productIds) {
        await _userBehaviorBox.add({
          'productId': productId,
          'action': 'purchase',
          'timestamp': timestamp,
        });
      }
    } catch (e) {
      print('Error syncing orders: $e');
    }
  }

  List<double> _createInteractionVector(List userActions) {
    final vector = List<double>.filled(_numProducts, 0.0);
    final weights = {
      'purchase': 5.0, // Highest weight for purchases
      'wishlist': 3.0, // High weight for wishlist
      'cart': 2.0, // Medium weight for cart
      'view': 1.0 // Base weight for views
    };

    // Calculate category interaction counts to prevent over-weighting popular categories
    final categoryInteractions = <String, int>{};
    for (var action in userActions) {
      final productId = action['productId'].toString();
      final productInfo = _productInfo[productId];
      if (productInfo != null) {
        final category = _getCategoryFromType(productInfo['type'] ?? '');
        categoryInteractions[category] =
            (categoryInteractions[category] ?? 0) + 1;
      }
    }

    // Find max interactions to normalize
    final maxCategoryInteractions = categoryInteractions.values.isEmpty
        ? 1
        : categoryInteractions.values.reduce((a, b) => a > b ? a : b);

    final now = DateTime.now().millisecondsSinceEpoch;

    for (var action in userActions) {
      final productId = action['productId'].toString();
      final index = _productIds.indexOf(productId);
      if (index == -1) continue;

      // Time decay - more recent actions have higher weight
      final timeDiff = now - (action['timestamp'] ?? now);
      final timeDecay =
          1 / (1 + timeDiff / (1000 * 60 * 60 * 24 * 14)); // 2-week decay

      final baseWeight = weights[action['action']] ?? 1.0;

      // Category balancing - reduce weight for over-represented categories
      final productInfo = _productInfo[productId];
      double categoryBalance = 1.0;
      if (productInfo != null) {
        final category = _getCategoryFromType(productInfo['type'] ?? '');
        final categoryCount = categoryInteractions[category] ?? 1;
        // Stronger penalty for over-represented categories
        categoryBalance =
            1.0 / (1.0 + (categoryCount / maxCategoryInteractions));
      }

      // Apply frequency penalty to prevent single product dominance
      final productFrequency =
          userActions.where((a) => a['productId'] == productId).length;
      final frequencyPenalty = 1.0 / (1.0 + (productFrequency - 1) * 0.3);

      vector[index] +=
          baseWeight * timeDecay * categoryBalance * frequencyPenalty;
    }

    // Normalize to prevent extreme values
    final maxValue = vector.reduce((a, b) => a > b ? a : b);
    return maxValue > 0 ? vector.map((v) => v / maxValue).toList() : vector;
  }

  List<Map<String, dynamic>> _rankedProducts(List<double> predictions,
      {int topN = 10}) {
    final indexed = List.generate(predictions.length, (i) => i);
    indexed.sort((a, b) => predictions[b].compareTo(predictions[a]));

    return indexed.take(topN).map((i) {
      final id = _productIds[i];
      return {
        'productId': id,
        'score': predictions[i],
        'name': _productInfo[id]?['name'] ?? '',
        'popularity': _productInfo[id]?['popularity'] ?? 0.0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _filterActions(String type) {
    final actions = <Map<String, dynamic>>[];
    for (var i = 0; i < _userBehaviorBox.length; i++) {
      final action = _userBehaviorBox.getAt(i);
      if (action != null && action['action'] == type) {
        final actionMap = Map<String, dynamic>.from(action);
        actionMap['key'] = i; // Store the key for deletion
        actions.add(actionMap);
      }
    }
    return actions;
  }

  Future<List<Map<String, dynamic>>> getRecentlyViewedWithData({
    int limit = 10,
  }) async {
    try {
      final views = _filterActions('view');
      views.sort(
          (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      final uniqueIds = <String>[];
      final seen = <String>{};
      for (var view in views) {
        final id = view['productId'].toString();
        if (!seen.contains(id)) {
          uniqueIds.add(id);
          seen.add(id);
        }
      }

      final productMap = await getProductMapById();

      return uniqueIds
          .take(limit)
          .map((id) {
            final product = productMap[id];
            if (product == null) return null;
            return _formatProduct(product, 'viewed');
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      print('Error getting recently viewed: $e');
      return [];
    }
  }

// Helper method to format product data consistently

  Future<List<Map<String, dynamic>>> getFromOrders({int limit = 10}) async {
    final userId = cartProvider.email ?? cartProvider.useremail ?? '';
    try {
      final trackingData =
          await ApiService.fetchTrackingData('hiren.tmbs@gmail.com');
      if (trackingData == null || !trackingData.containsKey('products')) {
        return [];
      }

      final productsData = trackingData['products'] as Map<String, dynamic>;
      final List<Map<String, dynamic>> orders = [];

      productsData.forEach((orderId, products) {
        if (products is List) {
          for (var product in products) {
            orders.add({
              'productId': product['product_id'].toString(),
              'name': product['product_name'] ?? '',
              'price': product['product_price']?.toString() ?? '0',
              'image': product['product_image'] ?? {},
              'type': product['product_type'] ?? '',
            });
          }
        }
      });

      return orders.take(limit).toList();
    } catch (e) {
      print('Error getting order recommendations: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTrendingNowWithData({
    int limit = 10,
  }) async {
    try {
      if (_productInfo.isEmpty) return [];

      final sorted = _productInfo.entries.toList()
        ..sort((a, b) => (b.value['popularity'] ?? 0.0)
            .compareTo(a.value['popularity'] ?? 0.0));

      final topEntries = sorted.take((sorted.length * 0.2).ceil()).toList();
      topEntries.shuffle(); // Add randomness

      final productMap = await getProductMapById();
      final seenTypes = <String>{};

      return topEntries
          .map((entry) => productMap[entry.key])
          .whereType<Subcategory>()
          .where((product) {
            final alreadySeen = seenTypes.contains(product.type);
            seenTypes.add(product.type);
            return !alreadySeen;
          })
          .take(limit)
          .map((product) => {
                'productId': product.product_id,
                'name': product.name,
                'price': product.price,
                'image': product.mainImages.isNotEmpty
                    ? product.mainImages.first
                    : '',
                'source': 'trending',
              })
          .toList();
    } catch (e) {
      print('Error getting trending products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendationsWithData({
    int topN = 10,
  }) async {
    try {
      final actions = _userBehaviorBox.values.toList();
      if (actions.isEmpty || _productIds.isEmpty) {
        return await getPopularProductsWithData(limit: topN);
      }

      final inputVector = _createInteractionVector(actions);
      final input = [inputVector];
      final output =
          List.generate(1, (_) => List<double>.filled(_productIds.length, 0.0));
      _interpreter.run(input, output);
      final predictionScores = output[0];

      final productMap = await getProductMapById();
      final rankedIndices = List.generate(predictionScores.length, (i) => i)
        ..sort((a, b) => predictionScores[b].compareTo(predictionScores[a]));

      // 🧠 Extract user's dominant types and gender from tracked actions
      final categoryCount = <String, int>{};
      final genderCount = <String, int>{};

      for (final action in actions) {
        final pid = action['productId'].toString();
        final product = productMap[pid];
        if (product == null) continue;

        final weight = switch (action['action']) {
          'purchase' => 3,
          'wishlist' => 2,
          'view' => 1,
          _ => 1
        };
        categoryCount[product.type] =
            (categoryCount[product.type] ?? 0) + weight;
        genderCount[product.gender] =
            (genderCount[product.gender] ?? 0) + weight;
      }

      // Get top categories and gender
      final topCategories = categoryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topGenders = genderCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final preferredCategories = topCategories.map((e) => e.key).toSet();
      final preferredGender =
          topGenders.isNotEmpty ? topGenders.first.key : null;

      // 🧠 Filter AI results to match category and gender
      final seenTypes = <String>{};
      final results = <Map<String, dynamic>>[];

      for (final index in rankedIndices) {
        final productId = _productIds[index];
        final product = productMap[productId];
        if (product == null) continue;

        final isGenderMatch = preferredGender == null ||
            product.gender.toLowerCase() == preferredGender.toLowerCase();
        final isTypeMatch = preferredCategories.contains(product.type);

        if (!isGenderMatch || !isTypeMatch) continue;

        if (seenTypes.contains(product.type)) continue; // Enforce variety
        seenTypes.add(product.type);

        results.add({
          'productId': product.product_id,
          'name': product.name,
          'price': product.price,
          'image':
              product.mainImages.isNotEmpty ? product.mainImages.first : '',
          'score': predictionScores[index],
          'source': 'ai_filtered',
        });

        if (results.length >= topN) break;
      }

      // Optional fallback
      if (results.length < topN) {
        for (final index in rankedIndices) {
          final productId = _productIds[index];
          final product = productMap[productId];
          if (product == null) continue;

          if (results.any((r) => r['productId'] == product.product_id))
            continue;

          results.add({
            'productId': product.product_id,
            'name': product.name,
            'price': product.price,
            'image':
                product.mainImages.isNotEmpty ? product.mainImages.first : '',
            'score': predictionScores[index],
            'source': 'ai_fallback',
          });

          if (results.length >= topN) break;
        }
      }

      return results;
    } catch (e) {
      print('❌ Error generating filtered AI recommendations: $e');
      return await getPopularProductsWithData(limit: topN);
    }
  }

  Future<List<Map<String, dynamic>>> getInspiredByWishlist({
    required String userId,
    int perCategory = 2,
  }) async {
    final wishlist = await ApiService.getWishlist(userId);
    final productMap = await getProductMapById();
    final allProducts = productMap.values.toList();

    final wishlistIds = wishlist.map((e) => e['product_id'].toString()).toSet();
    final wishlistProducts =
        wishlistIds.map((id) => productMap[id]).whereType<Subcategory>();

    final seen = wishlistIds;
    final Map<String, List<Subcategory>> buckets = {};

    for (var wp in wishlistProducts) {
      if (_isGrocery(wp.type)) continue;
      final matches = allProducts
          .where((p) =>
              p.product_id != wp.product_id &&
              p.type == wp.type &&
              p.gender == wp.gender &&
              !seen.contains(p.product_id))
          .toList();

      if (matches.isNotEmpty) {
        buckets.putIfAbsent(wp.type, () => []).addAll(matches);
      }
    }

    // Fallback if empty
    if (buckets.isEmpty) return await getMostWishlistedByOthers(perCategory);

    final results = <Map<String, dynamic>>[];
    for (var list in buckets.values) {
      list.shuffle();
      for (var p in list.take(perCategory)) {
        results.add(_formatProduct(p, 'inspired_wishlist'));
      }
    }

    return results;
  }

Future<List<Map<String, dynamic>>> getBasedOnOrders({
  required String email,
  int perCategory = 2,
}) async {
  try {
    final trackingData = await ApiService.fetchTrackingData(email);
    final productMap = await getProductMapById();
    final allProducts = productMap.values.toList();

    final orderedIds = <String>{};
    
    // Handle null trackingData
    if (trackingData == null) {
      return await getBestSellersByCategory(perCategory);
    }
    
    // Safe casting with proper handling
    final products = trackingData['products'];
    
    if (products is Map<String, dynamic>) {
      // Handle as map - iterate through orders
      products.forEach((orderId, productList) {
        if (productList is List) {
          for (final product in productList) {
            if (product is Map<String, dynamic> && product['product_id'] != null) {
              orderedIds.add(product['product_id'].toString());
            }
          }
        }
      });
    } else if (products is List) {
      // Handle as list - direct iteration
      for (final product in products) {
        if (product is Map<String, dynamic> && product['product_id'] != null) {
          orderedIds.add(product['product_id'].toString());
        }
      }
    }
    
    // If no orders found, return fallback
    if (orderedIds.isEmpty) {
      return await getBestSellersByCategory(perCategory);
    }
    
    // Get ordered products and find similar ones
    final orderedProducts = orderedIds
        .map((id) => productMap[id])
        .whereType<Subcategory>()
        .toList();
    
    final seen = orderedIds;
    final Map<String, List<Subcategory>> buckets = {};
    
    // Group similar products by category/type
    for (var orderedProduct in orderedProducts) {
      if (_isGrocery(orderedProduct.type)) continue;
      
      final matches = allProducts
          .where((p) =>
              p.product_id != orderedProduct.product_id &&
              p.type == orderedProduct.type &&
              p.gender == orderedProduct.gender &&
              !seen.contains(p.product_id))
          .toList();
      
      if (matches.isNotEmpty) {
        buckets.putIfAbsent(orderedProduct.type, () => []).addAll(matches);
      }
    }
    
    // Build results
    final results = <Map<String, dynamic>>[];
    for (var list in buckets.values) {
      list.shuffle();
      for (var p in list.take(perCategory)) {
        results.add(_formatProduct(p, 'based_on_orders'));
      }
    }
    
    return results;
    
  } catch (e) {
    print('Error in getBasedOnOrders: $e');
    // Return fallback on error
    return await getBestSellersByCategory(perCategory);
  }
}

  Future<List<Map<String, dynamic>>> getMostWishlistedByOthers(
      int perCategory) async {
    final productMap = await getProductMapById();
    final allProducts = productMap.values.toList();
    final Map<String, List<Subcategory>> buckets = {};

    for (var p in allProducts) {
      if (_isGrocery(p.type)) continue;
      buckets.putIfAbsent(p.type, () => []).add(p);
    }

    final results = <Map<String, dynamic>>[];
    for (var list in buckets.values) {
      list.shuffle();
      for (var p in list.take(perCategory)) {
        results.add(_formatProduct(p, 'popular_wishlist_fallback'));
      }
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> getBestSellersByCategory(
      int perCategory) async {
    final productMap = await getProductMapById();
    final allProducts = productMap.values.toList();
    final Map<String, List<Subcategory>> buckets = {};

    for (var p in allProducts) {
      if (_isGrocery(p.type)) continue;
      buckets.putIfAbsent(p.type, () => []).add(p);
    }

    final results = <Map<String, dynamic>>[];
    for (var list in buckets.values) {
      list.shuffle();
      for (var p in list.take(perCategory)) {
        results.add(_formatProduct(p, 'best_seller_fallback'));
      }
    }
    return results;
  }

  bool _isGrocery(String type) {
    final t = type.toLowerCase();
    return t.contains('grocery') || t.contains('food') || t.contains('daily');
  }

  Map<String, dynamic> _formatProduct(Subcategory p, String source) {
    return {
      'productId': p.product_id,
      'name': p.name,
      'price': p.price,
      'image': p.mainImages.isNotEmpty ? p.mainImages.first : '',
      'type': p.type,
      'gender': p.gender,
      'source': source,
    };
  }

  List<Map<String, dynamic>> _selectDiverseRecommendations(
    List<Map<String, dynamic>> candidates,
    Map<String, Subcategory> productMap,
    int limit,
  ) {
    final recommendations = <Map<String, dynamic>>[];
    final categoryCount = <String, int>{};
    final subcategoryCount = <String, int>{};

    // Define limits for each category to ensure diversity
    final categoryLimits = {
      '3': (limit * 0.2).ceil(), // Home & Kitchen: 20%
      '4': (limit * 0.2).ceil(), // Fashion: 20%
      '5': (limit * 0.2).ceil(), // Electronics: 20%
      '6': (limit * 0.15).ceil(), // Beauty: 15%
      '7': (limit * 0.15).ceil(), // Sports: 15%
      '8': (limit * 0.1).ceil(), // Groceries: 10%
    };

    // First pass: Fill each category up to its limit
    for (var candidate in candidates) {
      if (recommendations.length >= limit) break;

      final product = productMap[candidate['productId']];
      if (product == null) continue;

      final category = _getCategoryFromType(product.type);
      final currentCategoryCount = categoryCount[category] ?? 0;
      final categoryLimit = categoryLimits[category] ?? 1;

      if (currentCategoryCount < categoryLimit) {
        recommendations.add({
          'productId': product.product_id,
          'name': product.name,
          'price': product.price,
          'image':
              product.mainImages.isNotEmpty ? product.mainImages.first : '',
          'source': 'ml_diverse',
          'category': category,
          'score': candidate['score'],
        });

        categoryCount[category] = currentCategoryCount + 1;
        subcategoryCount[product.type] =
            (subcategoryCount[product.type] ?? 0) + 1;
      }
    }

    // Second pass: Fill remaining slots with best candidates
    if (recommendations.length < limit) {
      for (var candidate in candidates) {
        if (recommendations.length >= limit) break;

        final product = productMap[candidate['productId']];
        if (product == null) continue;

        // Skip if already added
        if (recommendations.any((r) => r['productId'] == product.product_id))
          continue;

        recommendations.add({
          'productId': product.product_id,
          'name': product.name,
          'price': product.price,
          'image':
              product.mainImages.isNotEmpty ? product.mainImages.first : '',
          'source': 'ml_diverse',
          'category': _getCategoryFromType(product.type),
          'score': candidate['score'],
        });
      }
    }

    return recommendations;
  }

// 2. Add category-balanced recommendation method
  Future<List<Map<String, dynamic>>> getCategoryBalancedRecommendations({
    int limit = 10,
    Set<String>? excludeIds,
  }) async {
    try {
      final productMap = await getProductMapById();
      final recommendations = <Map<String, dynamic>>[];

      // Define category distribution for balanced recommendations
      final categoryDistribution = {
        '3': (limit * 0.2).ceil(), // Home & Kitchen
        '4': (limit * 0.2).ceil(), // Fashion
        '5': (limit * 0.2).ceil(), // Electronics
        '6': (limit * 0.15).ceil(), // Beauty
        '7': (limit * 0.15).ceil(), // Sports
        '8': (limit * 0.1).ceil(), // Groceries
      };

      for (String categoryId in categoryDistribution.keys) {
        final targetCount = categoryDistribution[categoryId]!;
        final categoryProducts = productMap.values
            .where((product) =>
                _getCategoryFromType(product.type) == categoryId &&
                (excludeIds == null ||
                    !excludeIds.contains(product.product_id.toString())))
            .toList();

        // Sort by popularity within category
        categoryProducts.sort((a, b) {
          final aPopularity =
              _productInfo[a.product_id.toString()]?['popularity'] ?? 0.0;
          final bPopularity =
              _productInfo[b.product_id.toString()]?['popularity'] ?? 0.0;
          return bPopularity.compareTo(aPopularity);
        });

        // Add diverse subcategories from this category
        final addedSubcategories = <String>{};
        var addedFromCategory = 0;

        for (var product in categoryProducts) {
          if (addedFromCategory >= targetCount) break;

          // Prefer products from new subcategories for diversity
          if (!addedSubcategories.contains(product.type) ||
              addedFromCategory < targetCount ~/ 2) {
            recommendations.add({
              'productId': product.product_id,
              'name': product.name,
              'price': product.price,
              'image':
                  product.mainImages.isNotEmpty ? product.mainImages.first : '',
              'source': 'category_balanced',
              'category': categoryId,
            });

            addedSubcategories.add(product.type);
            addedFromCategory++;
          }
        }
      }

      // Shuffle to avoid predictable ordering
      recommendations.shuffle();
      return recommendations.take(limit).toList();
    } catch (e) {
      print('Error getting category-balanced recommendations: $e');
      return [];
    }
  }

// 3. Add helper method to map product type to category
  String _getCategoryFromType(String productType) {
    // Map product types to category IDs based on your business logic
    final categoryMapping = {
      // Fashion categories
      'Male': '4',
      'Women': '4',
      'Kids': '4',

      // Electronics categories
      'Boat': '5',
      'HP': '5',
      'Dell': '5',
      'DSLR': '5',
      'Aroma': '5',
      'MOTOROLA': '5',
      'Coocaa': '5',

      'Wrdrobe': '7',
      'Bed': '7',
      'gamingChair': '7',
      'Cabbinet': '7',
      'gardenChair': '7',
      'Sofa': '7',
    };

    // Check for exact matches first
    if (categoryMapping.containsKey(productType)) {
      return categoryMapping[productType]!;
    }

    // Check for partial matches (case insensitive)
    for (var entry in categoryMapping.entries) {
      if (productType.toLowerCase().contains(entry.key.toLowerCase()) ||
          entry.key.toLowerCase().contains(productType.toLowerCase())) {
        return entry.value;
      }
    }

    // For unknown types, distribute across non-fashion categories to avoid fashion bias
    final nonFashionCategories = [
      '3',
      '5',
      '6',
      '7',
      '8'
    ]; // Exclude fashion (4)
    return nonFashionCategories[
        productType.hashCode.abs() % nonFashionCategories.length];
  }

// 4. Improve wishlist recommendations with category diversity
  Future<List<Map<String, dynamic>>> getWishlistRecommendations(
      {int limit = 10}) async {
    final userId = cartProvider.email ?? cartProvider.useremail ?? '';
    try {
      final wishlist = await ApiService.getWishlist('hiren.tmbs@gmail.com');
      if (wishlist.isEmpty) {
        return await getCategoryBalancedRecommendations(limit: limit);
      }

      final productMap = await getProductMapById();
      if (productMap.isEmpty) return [];

      // Get categories and subcategories from wishlist
      final wishlistCategories = <String>{};
      final wishlistSubcategories = <String>{};
      final wishlistProductIds = <String>{};

      for (var item in wishlist) {
        final productId = item['product_id'].toString();
        wishlistProductIds.add(productId);

        final product = productMap[productId] ?? Subcategory.empty();
        if (product.type.isNotEmpty) {
          wishlistSubcategories.add(product.type);
          wishlistCategories.add(_getCategoryFromType(product.type));
        }
      }

      // Get products from same subcategories first, then categories
      final sameSubcategoryProducts = productMap.values
          .where((product) =>
              wishlistSubcategories.contains(product.type) &&
              !wishlistProductIds.contains(product.product_id))
          .toList();

      final sameCategoryProducts = productMap.values
          .where((product) =>
              wishlistCategories.contains(_getCategoryFromType(product.type)) &&
              !wishlistSubcategories.contains(product.type) &&
              !wishlistProductIds.contains(product.product_id))
          .toList();

      // Combine and sort by popularity
      final allRecommendations = [
        ...sameSubcategoryProducts,
        ...sameCategoryProducts
      ];
      allRecommendations.sort((a, b) {
        final aPopularity = _productInfo[a.product_id]?['popularity'] ?? 0.0;
        final bPopularity = _productInfo[b.product_id]?['popularity'] ?? 0.0;
        return bPopularity.compareTo(aPopularity);
      });

      final recommendations = allRecommendations
          .take(limit)
          .map((product) => _formatProduct(product, 'wishlist_category'))
          .toList();

      // Fill remaining slots with category-balanced products if needed
      if (recommendations.length < limit) {
        final additionalRecs = await getCategoryBalancedRecommendations(
          limit: limit - recommendations.length,
          excludeIds: {
            ...wishlistProductIds,
            ...recommendations.map((r) => r['productId'].toString())
          },
        );
        recommendations.addAll(additionalRecs);
      }

      return recommendations;
    } catch (e) {
      print('Error getting wishlist recommendations: $e');
      return await getCategoryBalancedRecommendations(limit: limit);
    }
  }

// 5. Improve popular products with category diversity
  Future<List<Map<String, dynamic>>> getPopularProductsWithData(
      {int limit = 10}) async {
    try {
      if (_productInfo.isEmpty) return [];

      final productMap = await getProductMapById();
      final categoryGroups = <String, List<Subcategory>>{};

      // Group products by category
      for (var product in productMap.values) {
        final category = _getCategoryFromType(product.type);
        categoryGroups.putIfAbsent(category, () => []).add(product);
      }

      // Sort each category by popularity
      for (var products in categoryGroups.values) {
        products.sort((a, b) {
          final aPopularity = _productInfo[a.product_id]?['popularity'] ?? 0.0;
          final bPopularity = _productInfo[b.product_id]?['popularity'] ?? 0.0;
          return bPopularity.compareTo(aPopularity);
        });
      }

      // Round-robin selection from each category
      final recommendations = <Map<String, dynamic>>[];
      final categoryKeys = categoryGroups.keys.toList();
      final categoryIndexes = <String, int>{
        for (var key in categoryKeys) key: 0
      };

      while (recommendations.length < limit &&
          categoryIndexes.values.any((index) =>
              index <
              (categoryGroups[categoryKeys.firstWhere(
                          (key) => categoryIndexes[key] == index,
                          orElse: () => categoryKeys.first)]
                      ?.length ??
                  0))) {
        for (var category in categoryKeys) {
          if (recommendations.length >= limit) break;

          final products = categoryGroups[category] ?? [];
          final index = categoryIndexes[category] ?? 0;

          if (index < products.length) {
            final product = products[index];
            recommendations.add({
              'productId': product.product_id,
              'name': product.name,
              'price': product.price,
              'image':
                  product.mainImages.isNotEmpty ? product.mainImages.first : '',
              'source': 'popular',
              'category': category,
            });
            categoryIndexes[category] = index + 1;
          }
        }
      }

      return recommendations;
    } catch (e) {
      print('Error getting popular products: $e');
      return [];
    }
  }

  Future<void> clearTrackedData() async {
    try {
      await _userBehaviorBox.clear();
    } catch (e) {
      print('Error clearing tracked data: $e');
    }
  }

  void dispose() {
    try {
      _interpreter.close();
      _userBehaviorBox.close();
    } catch (e) {
      print('Error disposing recommendation service: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getEnhancedRecommendations({
    int limit = 10,
    String? preferredCategory,
  }) async {
    try {
      // 1. Get multiple recommendation sources
      final mlRecs = await getRecommendationsWithData(topN: limit * 3);
      final popularRecs = await getPopularProductsWithData(limit: limit * 2);
      final trendingRecs = await getTrendingNowWithData(limit: limit * 2);

      // 2. Get user's recent interactions
      final recentActions = _userBehaviorBox.values.toList()
        ..sort(
            (a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));

      // 3. Analyze user's preferences
      final categoryPrefs = _calculateCategoryPreferences(recentActions);
      final subcategoryPrefs = _calculateSubcategoryPreferences(recentActions);

      // 4. Get all products
      final productMap = await getProductMapById();
      final allProducts = productMap.values.toList();

      // 5. Score products based on multiple factors
      final scoredProducts = <Subcategory, double>{};

      for (var product in allProducts) {
        double score = 0.0;

        // ML recommendation score
        final mlScore = mlRecs.firstWhere(
            (r) => r['productId'] == product.product_id,
            orElse: () => {'score': 0.0})['score'] as double;
        score += mlScore * 0.5;

        // Popularity score
        final popularity =
            _productInfo[product.product_id]?['popularity'] ?? 0.0;
        score += popularity * 0.2;

        // Category preference
        final category = _getCategoryFromType(product.type);
        score += (categoryPrefs[category] ?? 0.0) * 0.3;

        // Subcategory preference
        if (product.type.isNotEmpty) {
          score += (subcategoryPrefs[product.type] ?? 0.0) * 0.2;
        }

        // Trending boost (if in trending list)
        if (trendingRecs.any((r) => r['productId'] == product.product_id)) {
          score *= 1.2;
        }

        // Add some randomness
        score *= (0.9 + Random().nextDouble() * 0.2);

        scoredProducts[product] = score;
      }

      // 6. Sort and apply diversity
      final sorted = scoredProducts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return _ensureDiversity(sorted, limit, preferredCategory);
    } catch (e) {
      print('Error in enhanced recommendations: $e');
      return await getCategoryBalancedRecommendations(limit: limit);
    }
  }

  Map<String, double> _calculateSubcategoryPreferences(List<dynamic> actions) {
    final subcategoryWeights = <String, double>{};
    const weights = {
      'purchase': 2.0,
      'wishlist': 1.5,
      'cart': 1.0,
      'view': 0.5
    };
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var action in actions) {
      final productId = action['productId'].toString();
      final productInfo = _productInfo[productId];
      if (productInfo != null && productInfo['type'] != null) {
        final subcategory = productInfo['type'].toString();
        final timeDecay = 1 /
            (1 + (now - (action['timestamp'] ?? now)) / (86400 * 1000 * 30));
        final weight = weights[action['action']] ?? 0.5;

        subcategoryWeights.update(
            subcategory, (value) => value + (weight * timeDecay),
            ifAbsent: () => weight * timeDecay);
      }
    }

    // Normalize weights
    final total = subcategoryWeights.values.fold(0.0, (sum, w) => sum + w);
    return total > 0
        ? subcategoryWeights.map((k, v) => MapEntry(k, v / total))
        : subcategoryWeights;
  }

  List<Map<String, dynamic>> _ensureDiversity(
    List<MapEntry<Subcategory, double>> sortedProducts,
    int limit,
    String? preferredCategory,
  ) {
    final result = <Map<String, dynamic>>[];
    final categoriesIncluded = <String>{};
    final subcategoriesIncluded = <String>{};

    // Track how many items we've taken from each category
    final categoryCounts = <String, int>{};
    final maxPerCategory = (limit / 3).ceil(); // Max 3 categories represented

    // First pass - add preferred category items if specified
    if (preferredCategory != null) {
      for (var entry in sortedProducts) {
        final product = entry.key;
        if (product.id == preferredCategory &&
            result.length < limit ~/ 2 &&
            (categoryCounts[preferredCategory] ?? 0) < maxPerCategory) {
          result.add(_formatProduct(product, 'personalized'));
          categoriesIncluded.add(preferredCategory);
          categoryCounts.update(preferredCategory, (count) => count + 1,
              ifAbsent: () => 1);
          if (product.type.isNotEmpty) {
            subcategoriesIncluded.add(product.type);
          }
        }
      }
    }

    // Second pass - add diverse products
    for (var entry in sortedProducts) {
      if (result.length >= limit) break;

      final product = entry.key;
      final category = _getCategoryFromType(product.type);
      final isNewCategory = !categoriesIncluded.contains(category);
      final isNewSubcategory = product.type.isNotEmpty &&
          !subcategoriesIncluded.contains(product.type);
      final categoryCount = categoryCounts[category] ?? 0;

      // Skip if we've already taken enough from this category
      if (categoryCount >= maxPerCategory) continue;

      // Prefer products that add diversity
      if (isNewCategory || isNewSubcategory) {
        result.add(_formatProduct(product, 'personalized'));
        categoriesIncluded.add(category);
        categoryCounts.update(category, (count) => count + 1,
            ifAbsent: () => 1);
        if (product.type.isNotEmpty) {
          subcategoriesIncluded.add(product.type);
        }
      }
    }

    // Third pass - fill remaining slots with top products
    if (result.length < limit) {
      for (var entry in sortedProducts) {
        if (result.length >= limit) break;
        final product = entry.key;
        final category = _getCategoryFromType(product.type);
        if ((categoryCounts[category] ?? 0) < maxPerCategory &&
            !result.any((r) => r['productId'] == product.product_id)) {
          result.add(_formatProduct(product, 'personalized'));
          categoryCounts.update(category, (count) => count + 1,
              ifAbsent: () => 1);
        }
      }
    }

    return result;
  }

  Future<String> _determineUserSegment() async {
    try {
      final actions = _userBehaviorBox.values.toList();
      if (actions.isEmpty) return 'new_user';

      // Analyze user's category preferences
      final categoryPrefs = _calculateCategoryPreferences(actions);
      final topCategory =
          categoryPrefs.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      // Analyze interaction patterns
      final purchaseCount =
          actions.where((a) => a['action'] == 'purchase').length;
      final viewCount = actions.where((a) => a['action'] == 'view').length;
      final purchaseRatio = purchaseCount / (actions.length + 1);

      if (purchaseRatio > 0.5) {
        return 'frequent_buyer_$topCategory';
      } else if (viewCount > 5 && purchaseCount == 0) {
        return 'window_shopper_$topCategory';
      } else {
        return 'casual_user_$topCategory';
      }
    } catch (e) {
      print('Error determining user segment: $e');
      return 'new_user';
    }
  }

  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    int limit = 10,
  }) async {
    try {
      final userSegment = await _determineUserSegment();
      final productMap = await getProductMapById();

      // Different strategies for different segments
      switch (userSegment.split('_')[0]) {
        case 'frequent_buyer':
          final category = userSegment.split('_').skip(1).join('_');
          return await _getFrequentBuyerRecs(limit, category, productMap);
        case 'window_shopper':
          final category = userSegment.split('_').skip(1).join('_');
          return await _getWindowShopperRecs(limit, category, productMap);
        case 'casual_user':
          return await getEnhancedRecommendations(limit: limit);
        default: // new_user
          return await getCategoryBalancedRecommendations(limit: limit);
      }
    } catch (e) {
      print('Error in personalized recommendations: $e');
      return await getCategoryBalancedRecommendations(limit: limit);
    }
  }

  Future<List<Map<String, dynamic>>> _getFrequentBuyerRecs(
    int limit,
    String preferredCategory,
    Map<String, Subcategory> productMap,
  ) async {
    // For frequent buyers, show complementary products in their preferred category
    final productsInCategory = productMap.values
        .where((p) => _getCategoryFromType(p.type) == preferredCategory)
        .toList();

    // Sort by popularity and complementary attributes
    productsInCategory.sort((a, b) {
      final aPop = _productInfo[a.product_id]?['popularity'] ?? 0.0;
      final bPop = _productInfo[b.product_id]?['popularity'] ?? 0.0;
      return bPop.compareTo(aPop);
    });

    return productsInCategory
        .take(limit)
        .map((p) => _formatProduct(p, 'frequent_buyer'))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _getWindowShopperRecs(
    int limit,
    String viewedCategory,
    Map<String, Subcategory> productMap,
  ) async {
    // For window shoppers, show discounted/trending items in viewed categories
    final trending = await getTrendingNowWithData(limit: limit * 2);
    final viewedCategoryProducts = trending.where((p) {
      final product = productMap[p['productId']];
      return product != null &&
          _getCategoryFromType(product.type) == viewedCategory;
    }).toList();

    return viewedCategoryProducts.take(limit).toList();
  }

  Map<String, double> _calculateCategoryPreferences(List<dynamic> actions) {
    final categoryWeights = <String, double>{};
    const weights = {
      'purchase': 3.0,
      'wishlist': 2.0,
      'cart': 1.5,
      'view': 1.0
    };
    final now = DateTime.now().millisecondsSinceEpoch;

    for (var action in actions) {
      final productId = action['productId'].toString();
      final productInfo = _productInfo[productId];
      if (productInfo != null) {
        // Use 'type' field to determine category, not 'category_id'
        final category = _getCategoryFromType(productInfo['type'] ?? '');
        final timeDecay = 1 /
            (1 +
                (now - (action['timestamp'] ?? now)) /
                    (86400 * 1000 * 7)); // 1-week decay
        final weight = weights[action['action']] ?? 1.0;

        categoryWeights.update(
            category, (value) => value + (weight * timeDecay),
            ifAbsent: () => weight * timeDecay);
      }
    }

    // Normalize weights
    final total = categoryWeights.values.fold(0.0, (sum, w) => sum + w);
    return total > 0
        ? categoryWeights.map((k, v) => MapEntry(k, v / total))
        : categoryWeights;
  }
}

class ProductRecommendations extends StatefulWidget {
  final RecommendationService recommendationService;
  final String userEmail;

  const ProductRecommendations({
    Key? key,
    required this.recommendationService,
    required this.userEmail,
  }) : super(key: key);

  @override
  _ProductRecommendationsState createState() => _ProductRecommendationsState();
}

class _ProductRecommendationsState extends State<ProductRecommendations> {
  late Future<Map<String, dynamic>> _initializationFuture;
  bool _isLoading = false;
// Add these constants at the top of your RecommendationService class
  static const Map<String, String> _categoryNames = {
    '3': 'Grocery',
    '4': 'Fashion',
    '5': 'Electronics',
    '6': 'Toys',
    '7': 'Home & Furnitures',
    // '8': 'Groceries'
  };

  static const Map<String, List<String>> _subcategoryMapping = {
    '4': ['Men', 'Women', 'Kids', 'Shirts', 'Pants', 'Shoes', 'Accessories'],
    '5': ['Boat', 'HP', 'Dell', 'Sony', 'Headphones', 'Laptops', 'Speakers'],
    '6': ['Skincare', 'Makeup', 'Haircare', 'Fragrances'],
    '7': ['Furniture', 'Decor', 'Kitchenware', 'Bedding'],
    // '7': ['Fitness', 'Outdoor', 'Team Sports', 'Yoga'],
    // '8': ['Snacks', 'Beverages', 'Pantry', 'Fresh']
  };

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeData();
  }

  Future<Map<String, dynamic>> _initializeData() async {
  try {
    // Initialize recommendation service
    await widget.recommendationService.init(widget.userEmail);

    // Get product map ONCE (will be cached for subsequent calls)
    final productMap = await widget.recommendationService.getProductMapById();
    final allProducts = productMap.values.toList();

    // Fetch and sync wishlist
    final wishlist = await ApiService.getWishlist(widget.userEmail);
    final wishlistIds = wishlist
        .map((item) => item['product_id'].toString())
        .where((id) => id.isNotEmpty)
        .toList();

    // Fetch and sync orders
    final trackingData = await ApiService.fetchTrackingData(widget.userEmail);
    final List<String> orderIds = [];

    if (trackingData != null && trackingData.containsKey('orders')) {
      final orders = trackingData['orders'];
      if (orders is List) {
        for (var order in orders) {
          if (order is Map && order.containsKey('product_id')) {
            final productId = order['product_id'].toString();
            if (productId.isNotEmpty) {
              orderIds.add(productId);
            }
          }
        }
      }
    }

    // Sync data
    await widget.recommendationService
        .syncUserWishlist(widget.userEmail, wishlistIds);
    await widget.recommendationService
        .syncUserOrders(widget.userEmail, orderIds);



    // Get recommendations using the cached product map - WITH NULL SAFETY
    List<Map<String, dynamic>> wishlistRecs = [];
    List<Map<String, dynamic>> orderRecs = [];
    List<Map<String, dynamic>> recentlyViewed = [];
    List<Map<String, dynamic>> popular = [];

    try {
      wishlistRecs = wishlistIds.isNotEmpty
          ? await widget.recommendationService
              .getInspiredByWishlist(userId:'hiren.tmbs@gmail.com') ?? []
          : await widget.recommendationService.getMostWishlistedByOthers(2) ?? [];
    } catch (e) {
      print('Error getting wishlist recommendations: $e');
      wishlistRecs = [];
    }

    try {
      orderRecs = orderIds.isNotEmpty
          ? await widget.recommendationService
              .getBasedOnOrders(email: 'hiren.tmbs@gmail.com') ?? []
          : await widget.recommendationService.getBestSellersByCategory(2) ?? [];
    } catch (e) {
      print('Error getting order recommendations: $e');
      orderRecs = [];
    }

    try {
      recentlyViewed = await widget.recommendationService.getRecentlyViewedWithData() ?? [];
    } catch (e) {
      print('Error getting recently viewed: $e');
      recentlyViewed = [];
    }

    try {
      popular = await widget.recommendationService.getRecommendationsWithData() ?? [];
    } catch (e) {
      print('Error getting popular recommendations: $e');
      popular = [];
    }

    return {
      'allProducts': allProducts,
      'wishlist': wishlistRecs,
      'orders': orderRecs,
      'recentlyViewed': recentlyViewed,
      'popular': popular,
      'trending': <Map<String, dynamic>>[], // Empty for now
    };
  } catch (e) {
    print('Error initializing data: $e');
    return {
      'allProducts': <Subcategory>[],
      'wishlist': <Map<String, dynamic>>[],
      'orders': <Map<String, dynamic>>[],
      'recentlyViewed': <Map<String, dynamic>>[],
      'popular': <Map<String, dynamic>>[],
      'trending': <Map<String, dynamic>>[],
    };
  }
}

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _initializationFuture = _initializeData();
    });

    // Wait for initialization to complete
    await _initializationFuture;

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Smart AI Recommendations'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading personalized recommendations...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          final allProducts = data['allProducts'] as List<Subcategory>;

          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView(
              children: [
                _buildSection(
                  title: '🔁 Recently Viewed',
                  recommendations:
                      data['recentlyViewed'] as List<Map<String, dynamic>>,
                  allProducts: allProducts,
                ),
                _buildSection(
                  title: '❤️ Inspired By Your Wishlist',
                  recommendations:
                      data['wishlist'] as List<Map<String, dynamic>>,
                  allProducts: allProducts,
                ),
                _buildSection(
                  title: '🛍️ Based On Your Orders',
                  recommendations: data['orders'] as List<Map<String, dynamic>>,
                  allProducts: allProducts,
                ),
                _buildSection(
                  title: '👀 Popular Products',
                  recommendations:
                      data['popular'] as List<Map<String, dynamic>>,
                  allProducts: allProducts,
                ),
                _buildSection(
                  title: '🆕 Trending Now',
                  recommendations:
                      data['trending'] as List<Map<String, dynamic>>,
                  allProducts: allProducts,
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Map<String, dynamic>> recommendations,
    required List<Subcategory> allProducts,
  }) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = recommendations[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    // Extract image URL - handle both direct URLs and nested structures
    final dynamic imageData = product['image'];
    String imageUrl = '';

    // Handle case where image is already a URL string
    if (imageData is String && imageData.startsWith('http')) {
      imageUrl = imageData;
    }
    // Handle nested JSON structure
    else if (imageData is Map) {
      if (imageData['main'] is List && imageData['main'].isNotEmpty) {
        imageUrl = imageData['main'][0].toString();
      } else if (imageData.isNotEmpty) {
        // Get first available image URL from the map
        final firstImage = imageData.values.firstWhere(
          (v) => v is String && v.startsWith('http'),
          orElse: () => '',
        );
        imageUrl = firstImage.toString();
      }
    }

    return GestureDetector(
      onTap: () {
        widget.recommendationService.trackUserAction(
            widget.userEmail, product['productId'].toString(), 'view');
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with category badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image,
                                  size: 40, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child:
                                Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                  ),
                ),
                if (product['category'] != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _categoryNames[product['category']] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'Unknown Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product['price'] ?? '0'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Add rating if available
                  if (product['rating'] != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          product['rating'].toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
