import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/API%20E-Commerce/Model/e-subcategory_model.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/product_screen.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/Utilities/provider.dart';

import 'search_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _wishlistItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGridView = true;
  final Duration _animationDuration = const Duration(milliseconds: 300);

  Map<String, dynamic> _subcategoryToMap(Subcategory item) {
    return {
      'product_id': item.product_id,
      'name': item.name,
      'price': item.price,
      'image': item.mainImages.isNotEmpty ? item.mainImages.first : '',
      'subcategory': item,
    };
  }

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.initWishlist();
      setState(() {});
    });
  }

  String _getThumbnailFromProduct(Subcategory product) {
    try {
      final imageData = jsonDecode(product.image);
      if (imageData is Map &&
          imageData['main'] is List &&
          imageData['main'].isNotEmpty) {
        return imageData['main'][0];
      }
    } catch (e) {
      return product.image;
    }
    return product.image;
  }

  Future<void> _fetchWishlist() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final uEmail = cartProvider.useremail ?? cartProvider.email ?? '';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final wishlistMeta = await ApiService.getWishlist(uEmail);
      final wishlistProductIds = wishlistMeta
          .map((item) => item['product_id'].toString())
          .toSet();

      final allProducts = await ApiService.searchProducts1(
          ['3', '4', '5', '6', '7', '8'], "");

      final filteredWishlist = allProducts
          .where((product) => wishlistProductIds.contains(product.product_id))
          .toList();

      setState(() {
        _wishlistItems =
            filteredWishlist.map((e) => _subcategoryToMap(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load wishlist';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // Sliver App Bar with animated title
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Wishlist',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.grey[200],
              ),
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
                icon: Icon(
                  _isGridView ? Icons.view_agenda_outlined : Icons.grid_view_outlined,
                  color: Colors.black87,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading wishlist...',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black54,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_wishlistItems.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated heart with scale animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Your wishlist is empty',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Start adding items you love\nand find them here later',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.6,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.grey[800]!],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Navigate to shopping
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore Products',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            '${_wishlistItems.length} ${_wishlistItems.length == 1 ? 'item' : 'items'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black54,
              letterSpacing: -0.2,
            ),
          ),
        ),
        _isGridView ? _buildGridView() : _buildListView(),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _wishlistItems.length,
      itemBuilder: (context, index) {
        // Add staggered animation
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: _buildGridItem(index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _wishlistItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        // Add slide-in animation
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, double value, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: _buildListItem(index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridItem(int index) {
    final item = _wishlistItems[index];
    final subcategory = item['subcategory'] as Subcategory;
    final discount = int.tryParse(subcategory.discount) ?? 0;

    return GestureDetector(
      onTap: () => _navigateToProduct(subcategory),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      item['image'],
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                ),
                // Discount Badge
                if (discount > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$discount%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                // Wishlist Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildWishlistButton(subcategory, isSmall: true),
                ),
              ],
            ),
            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['name'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.3,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 5,
                      children: [
                        Text(
                          '₹${item['price']}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (discount > 0)
                          Text(
                            '₹${((int.tryParse(item['price']) ?? 0) * (100 + discount) ~/ 100)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.black38,
                              letterSpacing: -0.2,
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
    );
  }

  Widget _buildListItem(int index) {
    final item = _wishlistItems[index];
    final subcategory = item['subcategory'] as Subcategory;
    final discount = int.tryParse(subcategory.discount) ?? 0;

    return GestureDetector(
      onTap: () => _navigateToProduct(subcategory),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Image.network(
                      item['image'],
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 28,
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                    if (discount > 0)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-$discount%',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (discount > 0) ...[
                        Text(
                          '₹${(int.parse(item['price']) * (100 + discount) ~/ 100)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.black38,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '₹${item['price']}',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Wishlist Button
            _buildWishlistButton(subcategory),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistButton(Subcategory subcategory, {bool isSmall = false}) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final isWishlisted =
        cartProvider.isProductInWishlist(subcategory.product_id);
        return IconButton(
          iconSize: isSmall ? 20 : 24,
          icon: Container(
            padding: EdgeInsets.all(isSmall ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: isWishlisted ? Colors.red[400] : Colors.black54,
              size: isSmall ? 16 : 18,
            ),
          ),
          onPressed: () async {
            await cartProvider.toggleWishlist(subcategory.product_id);
            _fetchWishlist();
          },
        );
      },
    );
  }

  void _navigateToProduct(Subcategory subcategory) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ItemDetailScreen(subcategory: subcategory),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.1);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
