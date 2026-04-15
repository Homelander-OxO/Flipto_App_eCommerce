import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/e-subcategory_model.dart';
import 'package:flutter_app/models/rating_model.dart';
import 'package:flutter_app/screens/s.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/ai.dart';
import 'package:flutter_app/screens/cart_page.dart';
import 'package:flutter_app/screens/favourite.dart';
import 'package:flutter_app/custom_widgets/cart_badge.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'dart:convert';
import 'package:transparent_image/transparent_image.dart';
import 'package:photo_view/photo_view.dart';

import 'search_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Subcategory subcategory;
  final String? productId;

  const ItemDetailScreen({Key? key, required this.subcategory, this.productId})
      : super(key: key);

  @override
  _ItemDetailScreenState createState() => _ItemDetailScreenState();
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return PhotoView(
                imageProvider: NetworkImage(widget.imageUrls[index]),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                initialScale: PhotoViewComputedScale.contained,
                backgroundDecoration: BoxDecoration(color: Colors.white),
                heroAttributes: PhotoViewHeroAttributes(
                  tag: widget.imageUrls[index],
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.black87, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.imageUrls.length, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.black87
                          : Colors.grey.withOpacity(0.5),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with SingleTickerProviderStateMixin {
  late List<String> _mainImages;
  late Map<String, String> _colorOptions;
  late List<String> _sizes;
  int _currentImageIndex = 0;
  String? _selectedColor;
  String? _selectedSize;
  bool _showingColorImage = false;
  bool _showFullDescription = false;
  bool _showBottomBar = true;
  late List<Subcategory> _similarProducts = [];
  bool _isLoadingSimilarProducts = false;
  final ScrollController _scrollController = ScrollController();
  late RecommendationService recommendationService;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  List<ProductRating> _productRatings = [];
  bool _isLoadingRatings = false;
  double _averageRating = 0.0;
  int _totalRatings = 0;
  bool _isInWishlist = false;
  bool _isWishlistLoading = false;
  bool _isLoading = true;

  // Add this method to fetch ratings

  @override
  void initState() {
    super.initState();
    _parseProductDetails();
    _loadAllData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.initWishlist(); // 👈 Await here
      setState(() {}); // 👈 Force rebuild after loading wishlist
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), _loadSimilarProducts);
    recommendationService = RecommendationService();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userId = cartProvider.email ?? cartProvider.useremail ?? '';
    recommendationService.init(userId);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadProductRatings(),
        _loadSimilarProducts(),
        Provider.of<CartProvider>(context, listen: false).initWishlist(),
      ]);
    } catch (e) {
      print('Error loading all data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

// Helper function to format date (add this outside your widget class)
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMM, y').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getThumbnailFromProduct(Subcategory product) {
    final images = product.mainImages;
    return images.isNotEmpty ? images[0] : product.image;
  }

  Future<void> _loadProductRatings() async {
    if (!mounted) return;

    setState(() {
      _isLoadingRatings = true;
    });

    try {
      final response =
          await ApiService.getProductRatings(widget.subcategory.product_id);
      final ratingsData = response['rating'] as List<dynamic>? ?? [];

      // Parse ratings
      _productRatings =
          ratingsData.map((rating) => ProductRating.fromJson(rating)).toList();

      // Calculate average rating
      if (_productRatings.isNotEmpty) {
        final total = _productRatings.fold(
            0.0, (sum, rating) => sum + double.parse(rating.rating));
        _averageRating = total / _productRatings.length;
        _totalRatings = _productRatings.length;
      }
    } catch (e) {
      print('Error loading ratings: $e');
      _productRatings = [];
    }

    if (mounted) {
      setState(() {
        _isLoadingRatings = false;
      });
    }
  }

  Future<void> _loadSimilarProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSimilarProducts = true;
    });

    try {
      final currentProduct = widget.subcategory;
      final currentCategoryId = currentProduct.id;
      final currentType = currentProduct.type;
      final currentGender = currentProduct.gender;

      // Search only in the current product's category
      List<Subcategory> categoryProducts = [];
      try {
        // For Fashion category, search by gender first
        // For other categories, search by product type
        final searchTerm =
            currentCategoryId == '4' ? currentGender : currentType;

        categoryProducts = await ApiService.searchProducts1(
          [currentCategoryId],
          searchTerm,
        );
      } catch (e) {
        print('Error loading products for category $currentCategoryId: $e');
      }

      // Filter logic
      if (currentCategoryId == '4') {
        // For Fashion: gender AND type
        _similarProducts = categoryProducts.where((product) {
          return product.product_id !=
                  currentProduct.product_id && // Exclude current
              product.gender == currentGender && // Same gender
              product.type == currentType; // Same type
        }).toList();
      } else {
        // For others: only type
        _similarProducts = categoryProducts.where((product) {
          return product.product_id !=
                  currentProduct.product_id && // Exclude current
              product.type == currentType; // Same type
        }).toList();
      }

      // If not enough in current category, search all categories
      if (_similarProducts.length < 3) {
        final allCategoryIds = ['3', '4', '5', '6', '7', '8'];
        List<Subcategory> allProducts = [];

        for (String categoryId in allCategoryIds) {
          try {
            // Still maintain the same search term rules
            final searchTerm =
                currentCategoryId == '4' ? currentGender : currentType;

            final products = await ApiService.searchProducts1(
              [categoryId],
              searchTerm,
            );
            allProducts.addAll(products);
          } catch (e) {
            print('Error loading products for category $categoryId: $e');
          }
        }

        // Apply same filtering rules
        if (currentCategoryId == '4') {
          final additional = allProducts.where((product) {
            return product.product_id != currentProduct.product_id &&
                product.gender == currentGender &&
                product.type == currentType &&
                !_similarProducts
                    .any((p) => p.product_id == product.product_id);
          }).toList();
          _similarProducts.addAll(additional);
        } else {
          final additional = allProducts.where((product) {
            return product.product_id != currentProduct.product_id &&
                product.type == currentType &&
                !_similarProducts
                    .any((p) => p.product_id == product.product_id);
          }).toList();
          _similarProducts.addAll(additional);
        }
      }

      // Remove duplicates
      _similarProducts = _similarProducts.toSet().toList();

      // Limit to 6 max
      if (_similarProducts.length > 6) {
        _similarProducts = _similarProducts.sublist(0, 6);
      }

      print('Found ${_similarProducts.length} similar products for:');
      print(
          'Category: $currentCategoryId, Type: $currentType, Gender: $currentGender');
      _similarProducts.forEach((p) =>
          print('- ${p.name} (${p.type}, ${p.gender}, Category: ${p.id})'));
    } catch (e) {
      print('Error loading similar products: $e');
      _similarProducts = [];
    }

    if (mounted) {
      setState(() {
        _isLoadingSimilarProducts = false;
      });
    }
  }

  void _parseProductDetails() {
    _mainImages = widget.subcategory.mainImages;
    _colorOptions = widget.subcategory.colorOptions;

    // Use all available sizes from the product
    _sizes = widget.subcategory.allSizes;

    // Keep the selected size from cart if it exists, otherwise use first available
    _selectedSize =
        widget.subcategory.size ?? (_sizes.isNotEmpty ? _sizes.first : null);
    if (_sizes.isNotEmpty) {
      _selectedSize = _sizes.first;
    }
  }

  Widget _buildImageCarousel() {
    final imagesToShow = (_showingColorImage &&
            _selectedColor != null &&
            _colorOptions.containsKey(_selectedColor))
        ? [_colorOptions[_selectedColor]!]
        : _mainImages.isNotEmpty
            ? _mainImages
            : [widget.subcategory.image];

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 0.5),
            child: child,
          ),
        );
      },
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 2.2,
              // height: 350,
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrls: imagesToShow,
                            initialIndex: _currentImageIndex,
                          ),
                        ),
                      );
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: PageView.builder(
                        key: ValueKey<String>(_showingColorImage
                            ? 'color_$_selectedColor'
                            : 'main_images'),
                        itemCount: imagesToShow.length,
                        controller:
                            PageController(initialPage: _currentImageIndex),
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Hero(
                            tag: imagesToShow[index],
                            child: FadeInImage(
                              placeholder: MemoryImage(kTransparentImage),
                              image: NetworkImage(imagesToShow[index]),
                              fit: BoxFit.contain,
                              fadeInDuration: const Duration(milliseconds: 200),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height / 50,
                    right: MediaQuery.of(context).size.height / 50,
                    child: Consumer<CartProvider>(
                      builder: (context, cartProvider, _) {
                        final isInWishlist = cartProvider
                            .isProductInWishlist(widget.subcategory.product_id);
                        final isLoading = cartProvider.isLoadingWishlist;

                        return GestureDetector(
                          onTap: isLoading
                              ? null
                              : () async {
                                  final success =
                                      await cartProvider.toggleWishlist(
                                          widget.subcategory.product_id);

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(cartProvider
                                                .isProductInWishlist(widget
                                                    .subcategory.product_id)
                                            ? 'Added to wishlist!'
                                            : 'Removed from wishlist!'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Failed to update wishlist')),
                                    );
                                  }
                                },
                          child: Container(
                            height: MediaQuery.of(context).size.height / 23.5,
                            width: MediaQuery.of(context).size.width / 11,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                                child: Container(
                                  padding: EdgeInsets.only(top: 2),
                                  color: Colors.white.withOpacity(0.3),
                                  child: Center(
                                    child: Icon(
                                      isInWishlist
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 25,
                                      color: isInWishlist
                                          ? Colors.red
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 14,
                bottom: 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imagesToShow.length, (index) {
                  final isColorImage =
                      _showingColorImage && _selectedColor != null;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _currentImageIndex == index
                        ? (isColorImage ? 5 : 20)
                        : 5,
                    height: isColorImage ? 5 : 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(isColorImage ? 50 : 2),
                      color: _currentImageIndex == index
                          ? Colors.black
                          : Colors.grey[300],
                      border: isColorImage && _currentImageIndex == index
                          ? Border.all(color: Colors.white, width: 1)
                          : null,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOptions() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 0.3),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "COLOR",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              // letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _colorOptions.entries.map((entry) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedColor == entry.key) {
                      _selectedColor = null;
                      _showingColorImage = false;
                    } else {
                      _selectedColor = entry.key;
                      _showingColorImage = true;
                    }
                    _currentImageIndex = 0;
                  });
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedColor == entry.key
                          ? Colors.black
                          : Colors.transparent,
                      width: 1.7,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                            image: NetworkImage(entry.value),
                            fit: BoxFit.cover),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      // backgroundImage: NetworkImage(entry.value),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildSizeOptions() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value * 0.2),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _sizes.map((size) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSize = size;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color:
                        _selectedSize == size ? Colors.black : Colors.grey[100],
                  ),
                  child: Center(
                    child: Text(
                      size,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            _selectedSize == size ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Product Screen Rating Section
  Widget _buildRatingsSection() {
    if (_isLoadingRatings) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        ),
      );
    }

    final totalRatingsFormatted = NumberFormat.compact().format(_totalRatings);
    final totalReviewsFormatted =
        NumberFormat.compact().format(_productRatings.length);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            "Ratings & Reviews",
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Rating Summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < _averageRating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$totalRatingsFormatted ratings & $totalReviewsFormatted reviews",
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: List.generate(5, (index) {
                      final starRating = 5 - index;
                      final count = _productRatings
                          .where((r) => double.parse(r.rating) == starRating)
                          .length;
                      final percentage = (_totalRatings > 0)
                          ? (count / _totalRatings * 100).round()
                          : 0;

                      // Determine color based on star rating (5=green, 1=red)
                      Color barColor;
                      switch (starRating) {
                        case 5:
                          barColor = Colors.green;
                          break;
                        case 4:
                          barColor = Colors.lightGreen;
                          break;
                        case 3:
                          barColor = Colors.amber;
                          break;
                        case 2:
                          barColor = Colors.orange;
                          break;
                        case 1:
                          barColor = Colors.red;
                          break;
                        default:
                          barColor = Colors.amber;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              "$starRating ★",
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  barColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$percentage%",
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Top Reviews (show 2)
          ..._productRatings.take(3).map((rating) {
            return _buildReviewItem(rating);
          }),
          // See All Reviews Button
          if (_productRatings.length > 2)
            TextButton(
              onPressed: () {
                _showAllReviews(context);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: Text(
                "See All Reviews",
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(ProductRating rating) {
    final ratingValue = double.parse(rating.rating);
    final isCertified =
        rating.userId != null; // Example condition for certified buyer

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < ratingValue.floor() ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            "${ratingValue.toStringAsFixed(1)} ★ ${rating.review.split('\n').first}",
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            rating.review,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          if (rating.images.isNotEmpty)
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rating.images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, imgIndex) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrls: rating.images,
                            initialIndex: imgIndex,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        rating.images[imgIndex],
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Text(
              //   rating.userId ?? "Anonymous User",
              //   style: GoogleFonts.roboto(
              //     fontSize: 12,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),

              Text(
                _formatDate(rating.createdAt),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (isCertified) ...[
                const SizedBox(width: 8),
                Icon(Icons.verified, color: Colors.blue, size: 14),
                const SizedBox(width: 4),
                Text(
                  "Certified Buyer",
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ],
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.thumb_up_outlined, size: 18),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              Text(
                "Helpful",
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                "Report",
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Full Reviews Screen
  void _showAllReviews(BuildContext context) {
    Navigator.push(
      context,
      CustomCupertinoPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.grey[50],
            title: Text(
              "Ratings & Reviews",
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating Summary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: GoogleFonts.roboto(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < _averageRating.floor()
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 24,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${NumberFormat.compact().format(_totalRatings)} ratings & ${NumberFormat.compact().format(_productRatings.length)} reviews",
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: List.generate(5, (index) {
                          final starRating = 5 - index;
                          final count = _productRatings
                              .where(
                                  (r) => double.parse(r.rating) == starRating)
                              .length;
                          final percentage = (_totalRatings > 0)
                              ? (count / _totalRatings * 100).round()
                              : 0;
                          Color barColor;
                          switch (starRating) {
                            case 5:
                              barColor = Colors.green;
                              break;
                            case 4:
                              barColor = Colors.lightGreen;
                              break;
                            case 3:
                              barColor = Colors.amber;
                              break;
                            case 2:
                              barColor = Colors.orange;
                              break;
                            case 1:
                              barColor = Colors.red;
                              break;
                            default:
                              barColor = Colors.amber;
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  "$starRating ★",
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      barColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$percentage%",
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Rate and Review Button
                ElevatedButton(
                  onPressed: () {
                    // Add review action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.blue),
                    ),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    "RATE AND WRITE A REVIEW",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // All Reviews
                ..._productRatings.map((rating) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _buildReviewItem(rating),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          final isInCart =
              cartProvider.isProductInCart(widget.subcategory.product_id);

          return Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (isInCart) {
                      Navigator.push(
                        context,
                        CustomCupertinoPageRoute(
                          builder: (context) => CartScreen(),
                        ),
                      );
                    } else {
                      // Don't validate - use whatever is selected or null
                      final updatedProduct = widget.subcategory.copyWith(
                        color: _selectedColor,
                        size: _selectedSize,
                      );

                      final message =
                          await cartProvider.addToCart(updatedProduct, context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(8),
                          backgroundColor: Colors.black,
                          content: Text(
                            message,
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'VIEW CART',
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.push(
                                context,
                                CustomCupertinoPageRoute(
                                  builder: (context) => CartScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isInCart ? Colors.grey[200] : Color(0xff101d42),
                    foregroundColor: isInCart ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isInCart ? 'VIEW CART' : 'ADD TO CART',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Remove validation - use whatever is selected or null
                    final updatedProduct = widget.subcategory.copyWith(
                      color: _selectedColor,
                      size: _selectedSize,
                    );

                    cartProvider.addToCart(updatedProduct, context);
                    Navigator.push(
                      context,
                      CustomCupertinoPageRoute(
                        builder: (context) => CartScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                  child: Text(
                    'BUY NOW',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductHeader() {
    final discount = int.tryParse(widget.subcategory.discount) ?? 0;
    final originalPrice = double.parse(widget.subcategory.price);
    final discountedPrice = originalPrice * (100 - discount) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image Carousel
        _buildImageCarousel(),

        // Color Options (moved up)
        if (_colorOptions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildColorOptions(),
          ),

        // Product Name and Price
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                widget.subcategory.name,
                style: GoogleFonts.manrope(
                  fontSize: 17, // Slightly smaller
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    "₹${discountedPrice}",
                    style: GoogleFonts.manrope(
                        fontSize: 22, // Slightly smaller
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  if (discount > 0) ...[
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '₹${originalPrice.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "$discount% off",
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${_averageRating.toStringAsFixed(1)} ($_totalRatings)",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Trusted",
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            "SELECT SIZE",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildSizeOptions(),
          const SizedBox(height: 5),
          Text(
            "Product Details",
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              // color: Colors.grey[800],
              // letterSpacing: 0.5 ,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Name: ${widget.subcategory.name}",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              if (_showFullDescription) ...[
                const SizedBox(height: 12),
                Text(
                  "Description: ${widget.subcategory.description}",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFullDescription = !_showFullDescription;
                  });
                },
                child: Text(
                  _showFullDescription ? "Read Less" : "Read More",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProducts() {
    // Don't show section if no products (after loading) unless we're still loading
    if (!_isLoadingSimilarProducts && _similarProducts.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            "Similar Products",
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingSimilarProducts)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              height: MediaQuery.of(context).size.height / 3.6,

              // height: 245,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _similarProducts.length,
                itemBuilder: (context, index) {
                  final product = _similarProducts[index];
                  final discount = int.tryParse(product.discount) ?? 0;
                  final originalPrice = double.parse(product.price);
                  final discountedPrice =
                      originalPrice * (100 - discount) / 100;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        CustomCupertinoPageRoute(
                          builder: (_) =>
                              ItemDetailScreen(subcategory: product),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3.2,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            child: SizedBox(
                              // width: 125,
                              width: MediaQuery.of(context).size.width / 3.25,
                              height: MediaQuery.of(context).size.height / 5.1,
                              // height: 150,
                              child: FadeInImage(
                                placeholder: MemoryImage(kTransparentImage),
                                image: NetworkImage(
                                    _getThumbnailFromProduct(product)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Product Details
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Name
                                Text(
                                  product.name,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Price and Discount
                                Row(
                                  children: [
                                    Text(
                                      "₹${discountedPrice.round()}",
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    if (discount > 0) ...[
                                      Text(
                                        "₹${originalPrice.round()}",
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(Icons.star,
                                        color: Colors.amber, size: 13.5),
                                    const SizedBox(width: 1),
                                    Text(
                                      "3.8 (117)",
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "$discount% off",
                                        style: GoogleFonts.manrope(
                                          fontSize: 10,
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: ImageIcon(
              AssetImage(
                'assets/images/search0.png',
              ),
              size: 24,
            ),
            // Icon(Icons.search_rounded, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                CustomCupertinoPageRoute(
                  builder: (context) => SearchScreen100(

                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(CupertinoIcons.heart, size: 28), // Reduced
            onPressed: () {
              Navigator.push(
                  context,
                  CustomCupertinoPageRoute(
                      builder: (context) => FavoriteScreen()));
            },
          ),
          const CartIconWithBadge(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductHeader(),
                _buildProductDetails(),
                _buildRatingsSection(),
                _buildSimilarProducts(),
                SizedBox(height: MediaQuery.of(context).size.height / 12)
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(context),
          ),
          // if (_isLoading)
          //   Container(
          //     color: Colors.white,
          //     child: Center(
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           CircularProgressIndicator(
          //             valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          //           ),
          //           SizedBox(height: 16),
          //           Text(
          //             'Loading product details...',
          //             style: GoogleFonts.manrope(
          //               fontSize: 16,
          //               fontWeight: FontWeight.w500,
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
