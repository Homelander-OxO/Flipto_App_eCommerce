import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/API%20E-Commerce/Model/e-subcategory_model.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/product_screen.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SearchResultsScreen extends StatefulWidget {
  final String keyword;
  final List<String> categoryIds;
  final List<Map<String, dynamic>> searchResults;

  const SearchResultsScreen({
    Key? key,
    required this.keyword,
    required this.categoryIds,
    required this.searchResults,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Map<String, dynamic>> _displayedResults = [];
  bool _isLoading = false;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
    });

    // If we have direct search results, use those
    if (widget.searchResults.isNotEmpty) {
      _displayedResults = widget.searchResults;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildProductItem(Map<String, dynamic> product, int index) {
    // Fix image paths before creating subcategory
    Map<String, dynamic> imageData;
    try {
      final rawImage = product['product_image'];
      if (rawImage is String) {
        imageData = jsonDecode(rawImage);
      } else {
        imageData = rawImage as Map<String, dynamic>;
      }

      // Add base URL to all image paths
      if (imageData['main'] is List) {
        imageData['main'] = (imageData['main'] as List).map((img) {
          final imgPath = img.toString().replaceAll('\\', '/');
          if (!imgPath.startsWith('http')) {
            return '${ApiService.baseUrl}/$imgPath';
          }
          return imgPath;
        }).toList();
      }

      if (imageData['colors'] is Map) {
        imageData['colors'] = (imageData['colors'] as Map).map((key, value) {
          final imgPath = value.toString().replaceAll('\\', '/');
          if (!imgPath.startsWith('http')) {
            return MapEntry(key, '${ApiService.baseUrl}/$imgPath');
          }
          return MapEntry(key, imgPath);
        });
      }
    } catch (e) {
      imageData = {'main': [], 'colors': {}};
    }

    final subcategory = Subcategory.fromJson({
      'category_id': product['category_id'] ?? '',
      'product_id': product['product_id'] ?? '',
      'product_name': product['product_name'] ?? 'No Name',
      'product_type': product['product_type'] ?? 'N/A',
      'gender_category': product['gender_category'] ?? 'N/A',
      'product_desc': product['product_desc'] ?? '',
      'product_price': product['product_price'] ?? '0',
      'discount': product['discount'] ?? '0',
      'product_image': jsonEncode(imageData),
      'product_size': product['product_size'],
    });

    String imageUrl = '';
    try {
      if (imageData['main'] is List && imageData['main'].isNotEmpty) {
        imageUrl = imageData['main'][0].toString();
      }
    } catch (e) {
      print('Image parsing error: $e');
    }

    final discount = int.tryParse(subcategory.discount) ?? 0;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      margin: _isGridView
          ? const EdgeInsets.all(0)
          : const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              CustomCupertinoPageRoute(
                builder: (_) => ItemDetailScreen(subcategory: subcategory),
              ),
            );
          },
          child: Container(
            padding: _isGridView
                ? const EdgeInsets.all(8)
                : const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isGridView
                ? _buildGridItem(subcategory, imageUrl, discount)
                : _buildListItem(subcategory, imageUrl, discount),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(
      Subcategory subcategory, String imageUrl, int discount) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    // fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.image_outlined,
                          size: 32, color: Colors.grey[400]),
                    ),
                  ),
                )
              : Center(
                  child: Icon(Icons.image_outlined,
                      size: 32, color: Colors.grey[400]),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subcategory.name,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  letterSpacing: -0.1,
                  height: 1.3
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subcategory.gender,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                  letterSpacing: 0.1,
                  height: 1.3
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '₹${subcategory.price}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: -0.1,
                      height: 1.3
                    ),
                  ),
                  if (discount > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '₹${(int.parse(subcategory.price) * (100 + discount) ~/ 100)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$discount%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, _) {
                      final rating = cartProvider
                          .getRatingForProduct(subcategory.product_id);
                      final count = cartProvider
                          .getRatingCountForProduct(subcategory.product_id);
                      return Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.6),
                            decoration: BoxDecoration(
                              color: Colors.green[500],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 2),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            '(${count.toString()})',
                            style: TextStyle(
                              letterSpacing: 0.01,
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.08),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius:
                      BorderRadius.circular(2),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: Colors.purple,
                          size: 12,
                        ),
                        SizedBox(width: 2),
                        Text(
                          'Trusted',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.purple,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[500]),
      ],
    );
  }

  Widget _buildGridItem(
      Subcategory subcategory, String imageUrl, int discount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    // fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(Icons.image_outlined,
                          size: 32, color: Colors.grey[400]),
                    ),
                  ),
                )
              : Center(
                  child: Icon(Icons.image_outlined,
                      size: 32, color: Colors.grey[400]),
                ),
        ),
        const SizedBox(height: 12),
        Text(
          subcategory.name,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              letterSpacing: -0.1,
              height: 1.3
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '₹${subcategory.price}',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            if (discount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '₹${(int.parse(subcategory.price) * (100 + discount) ~/ 100)}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                ),
              ),
            ],
            if (discount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '-$discount%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[600],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subcategory.gender,
          style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[600],
              letterSpacing: 0.1,
              height: 1.3
          ),
        ),

        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Consumer<CartProvider>(
              builder: (context, cartProvider, _) {
                final rating = cartProvider
                    .getRatingForProduct(subcategory.product_id);
                final count = cartProvider
                    .getRatingCountForProduct(subcategory.product_id);
                return Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.6),
                      decoration: BoxDecoration(
                        color: Colors.green[500],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star,
                              color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '(${count.toString()})',
                      style: TextStyle(
                        letterSpacing: 0.01,
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),

            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius:
                BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.purple,
                    size: 12,
                  ),
                  SizedBox(width: 2),
                  Text(
                    'Trusted',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            surfaceTintColor: Colors.transparent,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Results for "${widget.keyword}"',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isGridView
                      ? Icons.view_list_outlined
                      : Icons.grid_view_outlined,
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: Colors.grey[200],
              ),
            ),
          ),

          // Results Count
          if (!_isLoading && _displayedResults.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  '${_displayedResults.length} ${_displayedResults.length == 1 ? 'product' : 'products'} found',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),

          // Results
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading results...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_displayedResults.isNotEmpty && _isGridView)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(4,4,4,30),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.53,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildProductItem(_displayedResults[index], index),
                  childCount: _displayedResults.length,
                ),
              ),
            )
          else if (_displayedResults.isNotEmpty && !_isGridView)
            SliverPadding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildProductItem(_displayedResults[index], index),
                  childCount: _displayedResults.length,
                ),
              ),
            )
          else if (!_isLoading && _displayedResults.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try different keywords',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
