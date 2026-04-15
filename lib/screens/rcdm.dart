import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_app/models/e-subcategory_model.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class UserInteraction {
  final String productId;
  final String interactionType;
  final DateTime timestamp;

  UserInteraction({
    required this.productId,
    required this.interactionType,
    required this.timestamp,
  });

  factory UserInteraction.fromJson(Map<String, dynamic> json) {
    return UserInteraction(
      productId: json['productId'],
      interactionType: json['interactionType'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'interactionType': interactionType,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

class RealtimeRecommendationService {
  static final RealtimeRecommendationService _instance =
      RealtimeRecommendationService._internal();

  factory RealtimeRecommendationService() => _instance;

  RealtimeRecommendationService._internal();

  Interpreter? _interpreter;
  Map<String, dynamic>? _productInfo;
  List<String>? _encoderClasses;
  Map<String, double>? _interactionWeights;
  bool _isInitialized = false;
  List<Subcategory> _allProducts = [];

  // Recently viewed products list
  List<Subcategory> _recentlyViewed = [];

  // Product ID mapping for model compatibility
  Map<String, String> _productIdMapping = {};
  Map<String, String> _reverseProductIdMapping = {};

  // Maximum items to keep in recently viewed
  static const int maxRecentlyViewed = 10;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the TensorFlow Lite model
      _interpreter = await Interpreter.fromAsset(
          'assets/models/recommendation_model_compatible.tflite');

      // Load product information
      final String productInfoStr =
          await rootBundle.loadString('assets/models/product_info.json');
      _productInfo = json.decode(productInfoStr);

      _encoderClasses = List<String>.from(_productInfo!['encoder_classes']);
      _interactionWeights =
          Map<String, double>.from(_productInfo!['interaction_weights']);

      // Fetch all products from API
      _allProducts = await ApiService.fetchAllProducts(['4', '5', '6', '7']);

      // Create product ID mapping
      _createProductMapping();

      // Load recently viewed from storage
      await _loadRecentlyViewed();

      _isInitialized = true;
      print('RealtimeRecommendationService initialized successfully');
      print('Loaded ${_encoderClasses!.length} model products');
      print('Loaded ${_allProducts.length} API products');
      print('Created ${_productIdMapping.length} mappings');
    } catch (e) {
      print('Error initializing RealtimeRecommendationService: $e');
      throw Exception('Failed to initialize recommendation service: $e');
    }
  }

  // Create mapping between API product IDs and model product IDs
  void _createProductMapping() {
    _productIdMapping.clear();
    _reverseProductIdMapping.clear();

    // Map API product IDs to model product IDs
    for (int i = 0;
        i < _allProducts.length && i < _encoderClasses!.length;
        i++) {
      final apiProductId = _allProducts[i].product_id;
      final modelProductId = _encoderClasses![i];

      _productIdMapping[apiProductId] = modelProductId;
      _reverseProductIdMapping[modelProductId] = apiProductId;
    }

    print('Product mapping created: ${_productIdMapping.length} mappings');
  }

  // Get random products for the first list
  List<Subcategory> getRandomProducts({int limit = 10}) {
    if (_allProducts.isEmpty) return [];

    final shuffled = List<Subcategory>.from(_allProducts);
    shuffled.shuffle(Random());
    return shuffled.take(limit).toList();
  }

  // Get similar products based on category and AI recommendations
  Future<List<Subcategory>> getSimilarProducts(Subcategory clickedProduct,
      {int limit = 3}) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
    }

    try {
      print('Getting similar products for: ${clickedProduct.name}');

      final aiRecommendations = await _getAIRecommendations(limit: 30);
      print('Got ${aiRecommendations.length} AI recommendations');

      final usedIds = <String>{clickedProduct.product_id};
      final result = <Subcategory>[];
      // 2️⃣ Add products matching both product_type AND gender_category
      final filteredRecommendations = aiRecommendations.where((product) {
        return product.type == clickedProduct.type &&
            product.gender == clickedProduct.gender &&
            !usedIds.contains(product.product_id);
      }).toList();

      for (final product in filteredRecommendations) {
        result.add(product);
        usedIds.add(product.product_id);
        if (result.length >= limit) return result;
      }
      // 3️⃣ Add one product of same gender_category (any type)

      final sameGender = aiRecommendations.firstWhere(
        (p) =>
            p.gender == clickedProduct.gender &&
            !usedIds.contains(p.product_id),
        orElse: () => Subcategory.empty(),
      );
      if (sameGender.id.isNotEmpty) {
        result.add(sameGender);
        usedIds.add(sameGender.product_id);
      }

      // 4️⃣ Add one product from same category_id
      final sameCategory = _allProducts.firstWhere(
        (p) => p.id == clickedProduct.id && !usedIds.contains(p.product_id),
        orElse: () => Subcategory.empty(),
      );
      if (sameCategory.id.isNotEmpty) {
        result.add(sameCategory);
        usedIds.add(sameCategory.product_id);
      }
// // 1️⃣ Add TWO products with same product_type (any gender)
      final sameTypeList = aiRecommendations
          .where(
            (p) =>
                p.type == clickedProduct.type &&
                !usedIds.contains(p.product_id),
          )
          .toList();

      for (final product in sameTypeList) {
        result.add(product);
        usedIds.add(product.product_id);
        if (result.length >= 2) break; // ✅ Only take 2 from same type
      }
      print('Final recommendations count: ${result.length}');
      return result.take(limit).toList();
    } catch (e) {
      print('Error in getSimilarProducts: $e');
      return [];
    }
  }

  // Add product to recently viewed
  Future<void> addToRecentlyViewed(Subcategory product) async {
    // Remove if already exists
    _recentlyViewed.removeWhere((p) => p.product_id == product.product_id);

    // Add to beginning
    _recentlyViewed.insert(0, product);

    // Keep only max items
    if (_recentlyViewed.length > maxRecentlyViewed) {
      _recentlyViewed = _recentlyViewed.take(maxRecentlyViewed).toList();
    }

    // Save to storage
    await _saveRecentlyViewed();

    // Record interaction for AI learning
    await recordInteraction(product.product_id, 'view');
  }

  // Get recently viewed products
  List<Subcategory> getRecentlyViewed() {
    return List<Subcategory>.from(_recentlyViewed);
  }

  // Clear recently viewed
  Future<void> clearRecentlyViewed() async {
    _recentlyViewed.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recently_viewed');
  }

  // Load recently viewed from storage
  Future<void> _loadRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewedStr = prefs.getString('recently_viewed');

      if (recentlyViewedStr != null) {
        final List<dynamic> recentlyViewedJson = json.decode(recentlyViewedStr);
        _recentlyViewed = recentlyViewedJson
            .map((json) {
              // Find the product in our all products list
              final productId = json['product_id'];
              return _allProducts.firstWhere(
                (p) => p.product_id == productId,
                orElse: () => Subcategory.empty(),
              );
            })
            .where((product) => product.id.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('Error loading recently viewed: $e');
      _recentlyViewed = [];
    }
  }

  // Save recently viewed to storage
  Future<void> _saveRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewedJson = _recentlyViewed
          .map((product) => {
                'product_id': product.product_id,
                'name': product.name,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              })
          .toList();

      await prefs.setString('recently_viewed', json.encode(recentlyViewedJson));
    } catch (e) {
      print('Error saving recently viewed: $e');
    }
  }

  // Record user interaction
  Future<void> recordInteraction(
      String productId, String interactionType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interactions = await getUserInteractions();

      interactions.add(UserInteraction(
        productId: productId,
        interactionType: interactionType,
        timestamp: DateTime.now(),
      ));

      // Keep only recent interactions (last 1000)
      if (interactions.length > 1000) {
        interactions.removeRange(0, interactions.length - 1000);
      }

      final interactionsJson = interactions.map((i) => i.toJson()).toList();
      await prefs.setString('user_interactions', json.encode(interactionsJson));

      print('Recorded $interactionType interaction for product $productId');

      // Debug: Print current interactions
      final recentInteractions = interactions
          .where((i) => DateTime.now().difference(i.timestamp).inMinutes < 60)
          .toList();
      print('Recent interactions: ${recentInteractions.length}');
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }

  // Get user interactions from local storage
  Future<List<UserInteraction>> getUserInteractions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interactionsStr = prefs.getString('user_interactions');

      if (interactionsStr == null) return [];

      final List<dynamic> interactionsJson = json.decode(interactionsStr);
      return interactionsJson
          .map((json) => UserInteraction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user interactions: $e');
      return [];
    }
  }

  // Create user interaction vector for the model - FIXED VERSION
  List<double> _createUserVector(List<UserInteraction> interactions) {
    final vector = List<double>.filled(_encoderClasses!.length, 0.0);
    final now = DateTime.now();

    print('Creating user vector from ${interactions.length} interactions');

    for (final interaction in interactions) {
      // Map API product ID to model product ID
      final modelProductId = _productIdMapping[interaction.productId];
      if (modelProductId == null) {
        print('No mapping found for product ID: ${interaction.productId}');
        continue;
      }

      final index = _encoderClasses!.indexOf(modelProductId);
      if (index == -1) {
        print('Product ID not found in encoder classes: $modelProductId');
        continue;
      }

      // Get interaction weight
      final weight = _interactionWeights?[interaction.interactionType] ?? 0.5;

      // FIXED: Use days instead of minutes for time decay
      final daysSince = now.difference(interaction.timestamp).inDays.toDouble();
      final timeDecay = exp(-daysSince / 30.0); // 30-day half-life

      final adjustedWeight = weight * timeDecay;
      vector[index] += adjustedWeight;

      print(
          'Added interaction: ${interaction.interactionType} for ${interaction.productId} -> $modelProductId (weight: $adjustedWeight)');
    }

    // Normalize the vector
    final sum = vector.reduce((a, b) => a + b);
    if (sum > 0) {
      for (int i = 0; i < vector.length; i++) {
        vector[i] /= sum;
      }
      print('Vector normalized, sum was: $sum');
    } else {
      print('Warning: Empty interaction vector');
    }

    return vector;
  }

  // Get AI recommendations using the trained model - IMPROVED VERSION
  Future<List<Subcategory>> _getAIRecommendations({int limit = 10}) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
    }

    try {
      print('Getting AI recommendations...');

      // Get user interactions
      final interactions = await getUserInteractions();
      print('Found ${interactions.length} total interactions');

      if (interactions.isEmpty) {
        print('No interactions found, returning popular products');
        return _getPopularProducts(limit: limit);
      }

      // Create input vector for the model
      final inputVector = _createUserVector(interactions);

      // Check if vector has any non-zero values
      final hasData = inputVector.any((value) => value > 0);
      if (!hasData) {
        print('No valid interactions for model, returning popular products');
        return _getPopularProducts(limit: limit);
      }

      // Prepare input for TensorFlow Lite
      final input = [inputVector];
      final output = [List.filled(_encoderClasses!.length, 0.0)];

      print('Running model inference...');

      // Run inference
      _interpreter!.run(input, output);

      // Get recommendation scores
      final scores = output[0] as List<double>;
      print(
          'Model output scores: ${scores.take(5).toList()}... (showing first 5)');

      // Create list of product IDs with scores
      final productScores = <MapEntry<String, double>>[];
      for (int i = 0; i < scores.length && i < _encoderClasses!.length; i++) {
        final modelProductId = _encoderClasses![i];
        final apiProductId = _reverseProductIdMapping[modelProductId];
        if (apiProductId != null) {
          productScores.add(MapEntry(apiProductId, scores[i]));
        }
      }

      // Sort by score (descending) and filter out already interacted products
      final interactedProductIds = interactions
          .where((i) =>
              DateTime.now().difference(i.timestamp).inDays <
              7) // Recent interactions
          .map((i) => i.productId)
          .toSet();

      productScores.sort((a, b) => b.value.compareTo(a.value));

      print(
          'Top 5 product scores: ${productScores.take(5).map((e) => '${e.key}: ${e.value.toStringAsFixed(4)}').join(', ')}');

      final recommendations = <Subcategory>[];

      for (final entry in productScores) {
        if (recommendations.length >= limit) break;

        final productId = entry.key;
        final score = entry.value;

        // Skip very low scores
        if (score < 0.001) continue;

        // Skip recently interacted products
        if (interactedProductIds.contains(productId)) {
          print('Skipping recently interacted product: $productId');
          continue;
        }

        // Find the product in our allProducts list
        final product = _allProducts.firstWhere(
          (p) => p.product_id == productId,
          orElse: () => Subcategory.empty(),
        );

        if (product.id.isNotEmpty) {
          recommendations.add(product);
          print(
              'Added recommendation: ${product.name} (score: ${score.toStringAsFixed(4)})');
        }
      }

      print('Generated ${recommendations.length} AI recommendations');

      // If we don't have enough recommendations, fill with popular products
      if (recommendations.length < limit) {
        final popularProducts =
            _getPopularProducts(limit: limit - recommendations.length);
        for (final product in popularProducts) {
          if (!recommendations.any((r) => r.product_id == product.product_id)) {
            recommendations.add(product);
          }
        }
        print('Added ${popularProducts.length} popular products to fill gap');
      }

      return recommendations;
    } catch (e) {
      print('Error generating AI recommendations: $e');
      return _getPopularProducts(limit: limit);
    }
  }

  // Get popular products as fallback
  List<Subcategory> _getPopularProducts({int limit = 10}) {
    final productMapping =
        _productInfo?['product_mapping'] as Map<String, dynamic>?;

    if (productMapping == null) {
      // Simple random selection if no popularity data
      final shuffled = List<Subcategory>.from(_allProducts);
      shuffled.shuffle(Random());
      return shuffled.take(limit).toList();
    }

    final sortedProducts = _allProducts.toList()
      ..sort((a, b) {
        final aModelId = _productIdMapping[a.product_id];
        final bModelId = _productIdMapping[b.product_id];

        final aPopularity = aModelId != null
            ? (productMapping[aModelId]?['popularity'] ?? 0.0).toDouble()
            : 0.0;
        final bPopularity = bModelId != null
            ? (productMapping[bModelId]?['popularity'] ?? 0.0).toDouble()
            : 0.0;

        return bPopularity.compareTo(aPopularity);
      });

    return sortedProducts.take(limit).toList();
  }

  // Get all available products
  List<Subcategory> getAllProducts() {
    return _allProducts;
  }

  Future<List<Subcategory>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart_items');
      if (cartJson == null) return [];

      final List<dynamic> cartList = json.decode(cartJson);
      return cartList
          .map((item) {
            final productId = item['product_id'];
            return _allProducts.firstWhere(
              (p) => p.product_id == productId,
              orElse: () => Subcategory.empty(),
            );
          })
          .where((p) => p.id.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error loading cart items: $e');
      return [];
    }
  }

  // Debug method to check interactions
  Future<void> debugInteractions() async {
    final interactions = await getUserInteractions();
    print('=== DEBUG INTERACTIONS ===');
    print('Total interactions: ${interactions.length}');

    final recentInteractions = interactions
        .where((i) => DateTime.now().difference(i.timestamp).inHours < 24)
        .toList();

    print('Recent interactions (24h): ${recentInteractions.length}');

    for (final interaction in recentInteractions.take(10)) {
      final hoursAgo = DateTime.now().difference(interaction.timestamp).inHours;
      print(
          '- ${interaction.interactionType} on ${interaction.productId} (${hoursAgo}h ago)');
    }

    final vector = _createUserVector(interactions);
    final nonZeroIndices =
        vector.asMap().entries.where((e) => e.value > 0).length;
    print('Non-zero vector elements: $nonZeroIndices / ${vector.length}');
    print('===========================');
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

class RecommendationDemoScreen extends StatefulWidget {
  const RecommendationDemoScreen({Key? key}) : super(key: key);

  @override
  _RecommendationDemoScreenState createState() =>
      _RecommendationDemoScreenState();
}

class _RecommendationDemoScreenState extends State<RecommendationDemoScreen> {
  final RealtimeRecommendationService _service =
      RealtimeRecommendationService();

  List<Subcategory> _randomProducts = [];
  List<Subcategory> _recommendations = [];
  List<Subcategory> _recentlyViewed = [];
  List<Subcategory> _cartItems = [];
  bool _isLoading = true;
  String _error = '';
  Subcategory? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await _service.initialize();
      await _loadInitialData();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final randomProducts = _service.getRandomProducts(limit: 10);
      final recentlyViewed = _service.getRecentlyViewed();
      final cartItems = await _service.getCartItems();

      setState(() {
        _randomProducts = randomProducts;
        _recentlyViewed = recentlyViewed;
        _cartItems = cartItems;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
      });
    }
  }

  Future<void> _onProductClick(Subcategory product) async {
    setState(() {
      _selectedProduct = product;
    });

    try {
      await _service.addToRecentlyViewed(product);
      final similarProducts =
          await _service.getSimilarProducts(product, limit: 10);

      setState(() {
        _recommendations = similarProducts;
        _recentlyViewed = _service.getRecentlyViewed();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Viewing ${product.name}'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.black87,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _recordInteraction(
      String productId, String interactionType) async {
    try {
      await _service.recordInteraction(productId, interactionType);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Added to ${interactionType == "cart" ? "cart" : "wishlist"}'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearRecentlyViewed() async {
    await _service.clearRecentlyViewed();
    setState(() {
      _recentlyViewed = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Recently viewed cleared'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _refreshAll() async {
    setState(() {
      _isLoading = true;
    });
    await _initializeService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text(
          'AI Recommendations',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _refreshAll,
            tooltip: 'Refresh',
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.clear_all_rounded,
                        size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Clear Recently Viewed',
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                  ],
                ),
                onTap: () =>
                    Future.delayed(Duration.zero, _clearRecentlyViewed),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.bug_report_rounded,
                        size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Debug Interactions',
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                  ],
                ),
                onTap: () => _service.debugInteractions(),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading recommendations...',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _error.isNotEmpty
              ? _buildErrorState()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshAll,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Try Again',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return CustomScrollView(
      slivers: [
        // Selected product info
        if (_selectedProduct != null)
          SliverToBoxAdapter(child: _buildSelectedProductCard()),

        // Random products section
        _buildSectionSliver(
          title: 'Discover Products',
          subtitle: 'Explore our collection',
          products: _randomProducts,
          onTap: _onProductClick,
        ),

        // Recommendations section
        if (_recommendations.isNotEmpty)
          _buildSectionSliver(
            title: 'Recommended For You',
            subtitle: 'Based on your preferences',
            products: _recommendations,
            onTap: _onProductClick,
            showRecommendedBadge: true,
          ),

        // Recently viewed section
        if (_recentlyViewed.isNotEmpty)
          _buildHorizontalSectionSliver(
            title: 'Recently Viewed',
            products: _recentlyViewed,
            onTap: _onProductClick,
          ),

        // Cart Reminder section
        if (_cartItems.isNotEmpty)
          _buildHorizontalSectionSliver(
            title: 'Items in Your Cart',
            icon: Icons.shopping_cart_rounded,
            products: _cartItems,
            onTap: _onProductClick,
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildSelectedProductCard() {
    if (_selectedProduct == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_selectedProduct!.mainImages.isNotEmpty)
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(_selectedProduct!.mainImages.first),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently Viewing',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3B82F6),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedProduct!.name,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_selectedProduct!.price}',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSliver({
    required String title,
    String? subtitle,
    required List<Subcategory> products,
    required Function(Subcategory) onTap,
    bool showRecommendedBadge = false,
  }) {
    if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.55,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildProductCard(
                products[index],
                onTap,
                showRecommendedBadge: showRecommendedBadge,
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildHorizontalSectionSliver({
    required String title,
    IconData? icon,
    required List<Subcategory> products,
    required Function(Subcategory) onTap,
  }) {
    if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: Colors.black87),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 275,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 150,
                  margin: EdgeInsets.only(
                      right: index == products.length - 1 ? 0 : 12),
                  child: _buildProductCard(products[index], onTap),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Subcategory product,
    Function(Subcategory) onTap, {
    bool showRecommendedBadge = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(product),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.12)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        color: Colors.grey[100],
                      ),
                      child: product.mainImages.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Image.network(
                                product.mainImages.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                  child: Icon(Icons.image_not_supported,
                                      color: Colors.grey[400]),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.image_not_supported,
                                  color: Colors.grey[400]),
                            ),
                    ),
                    if (showRecommendedBadge)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome_rounded,
                                  size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'AI Pick',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${product.price}',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              color: const Color(0xFF10B981),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _recordInteraction(
                                  product.product_id, 'wishlist'),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey.withOpacity(0.2)),
                                ),
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: InkWell(
                              onTap: () => _recordInteraction(
                                  product.product_id, 'cart'),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
