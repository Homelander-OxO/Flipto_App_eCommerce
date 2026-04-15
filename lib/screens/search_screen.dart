import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/config/app_config.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/screens/product_screen.dart';
import 'package:flutter_app/screens/search_result.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Utilities/provider.dart';
import '../models/e-subcategory_model.dart';
import '../utilities/api_service.dart';

class SearchScreen100 extends StatefulWidget {
  const SearchScreen100({Key? key}) : super(key: key);

  @override
  State<SearchScreen100> createState() => _SearchScreen100State();
}

class _SearchScreen100State extends State<SearchScreen100> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  static final Map<String, ImageProvider> _imageCache = {};

  List<String> _suggestions = [
    'Men',
    'Women',
    'Kids',
    'Fruits',
    'Vegetables',
    'Shoes',
    'Kurta',
    'Toys',
    'Cleaning',
    'Electronics'
  ];

  final keywordToCategoryIds = {
    'men': ['4'],
    'women': ['4'],
    'kids': ['4'],
    'fruits': ['3'],
    'vegetables': ['3'],
    'toys': ['6'],
    'cleaning essentials': ['10'],
  };

  List<String> _filteredSuggestions = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _showRecentSearches = true;
  bool _hasSearched = false;

  // Recent searches storage
  List<String> _recentSearches = [];
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 5;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];
    setState(() {
      _recentSearches = searches;
    });
  }

  Future<void> _saveRecentSearch(String search) async {
    if (search.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    // Remove if already exists
    _recentSearches.remove(search);

    // Add to beginning
    _recentSearches.insert(0, search);

    // Keep only max items
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.take(_maxRecentSearches).toList();
    }

    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    setState(() {});
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    setState(() {
      _recentSearches.clear();
    });
  }

  Future<void> _removeRecentSearch(String search) async {
    final prefs = await SharedPreferences.getInstance();
    _recentSearches.remove(search);
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
    setState(() {});
  }

  void _updateSuggestions(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performRealtimeSearch(query);
      } else {
        setState(() {
          _searchResults.clear();
          _showRecentSearches = true;
          _hasSearched = false;
        });
      }
    });

    // Update filtered suggestions for display
    setState(() {
      _filteredSuggestions = _suggestions
          .where((item) => item.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _showRecentSearches = query.isEmpty;
    });
  }

  Future<void> _performRealtimeSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await ApiService.searchProducts(query);
      print('API returned ${results.length} items for: $query');

      final lowerQuery = query.toLowerCase();
      final filtered = results.where((product) {
        final name = product['product_name']?.toString().toLowerCase() ?? '';
        final type = product['product_type']?.toString().toLowerCase() ?? '';
        final genderCategory =
            product['gender_category']?.toString().toLowerCase() ?? '';
        final desc = product['product_desc']?.toString().toLowerCase() ?? '';

        // For gender searches, use exact matching
        if (lowerQuery == 'men') {
          return genderCategory == 'male' || genderCategory == 'men';
        } else if (lowerQuery == 'women') {
          return genderCategory == 'female' || genderCategory == 'women';
        } else if (lowerQuery == 'kids') {
          return genderCategory == 'kids' || genderCategory == 'children';
        }

        // For other searches, use contains but exclude gender-based filtering
        return name.contains(lowerQuery) ||
            type.contains(lowerQuery) ||
            desc.contains(lowerQuery);
      }).toList();

      print('Filtered results: ${filtered.length}');

      // Show only top 5 suggestions in search screen
      setState(() {
        _searchResults = filtered.take(4).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getFullSearchResults(String query) async {
    try {
      final results = await ApiService.searchProducts(query);
      final lowerQuery = query.toLowerCase();

      final filtered = results.where((product) {
        final name = product['product_name']?.toString().toLowerCase() ?? '';
        final type = product['product_type']?.toString().toLowerCase() ?? '';
        final genderCategory =
            product['gender_category']?.toString().toLowerCase() ?? '';
        final desc = product['product_desc']?.toString().toLowerCase() ?? '';

        if (lowerQuery == 'men') {
          return genderCategory == 'male' || genderCategory == 'men';
        } else if (lowerQuery == 'women') {
          return genderCategory == 'female' || genderCategory == 'women';
        } else if (lowerQuery == 'kids') {
          return genderCategory == 'kids' || genderCategory == 'children';
        }

        return name.contains(lowerQuery) ||
            type.contains(lowerQuery) ||
            desc.contains(lowerQuery);
      }).toList();

      return filtered;
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  void _goToSearchResults(String keyword) async {
    // Save to recent searches
    await _saveRecentSearch(keyword);

    // Show loading
    setState(() => _isLoading = true);

    // Get full results
    final fullResults = await _getFullSearchResults(keyword);

    setState(() => _isLoading = false);

    final ids = keywordToCategoryIds[keyword.toLowerCase()] ?? [];

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SearchResultsScreen(
          keyword: keyword,
          categoryIds: ids,
          searchResults: fullResults,
        ),
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

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.requestFocus();
    setState(() {
      _searchResults.clear();
      _showRecentSearches = true;
      _hasSearched = false;
    });
  }

  Widget _buildProductItem(Map<String, dynamic> product, int index) {
    final productName = product['product_name'] ?? 'No Name';
    final genderCategory = product['gender_category'] ?? 'N/A';
    final price = product['product_price'] ?? 'N/A';
    final discount = int.tryParse(product['discount']?.toString() ?? '0') ?? 0;

    // Fix image paths before creating subcategory
    Map<String, dynamic> imageData;
    try {
      final rawImage = product['product_image'];
      if (rawImage is String) {
        imageData = jsonDecode(rawImage);
      } else {
        imageData = rawImage as Map<String, dynamic>;
      }

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
      final imageData = product['product_image'];
      if (imageData is String) {
        final decoded = jsonDecode(imageData);
        if (decoded['main'] is List && decoded['main'].isNotEmpty) {
          imageUrl = decoded['main'][0].toString().replaceAll('\\', '/');
        }
      } else if (imageData is Map) {
        if (imageData['main'] is List && imageData['main'].isNotEmpty) {
          imageUrl = imageData['main'][0].toString().replaceAll('\\', '/');
        }
      }

      if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
        imageUrl = '${ApiService.baseUrl}/$imageUrl';
      }
    } catch (e) {
      print('Image parsing error: $e');
    }

    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: 10,
        top: index == 0 ? 6 : 0,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image(
                            image: _imageCache.putIfAbsent(
                              imageUrl,
                              () => NetworkImage(imageUrl),
                            ),
                            // fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                              child: Icon(Icons.image_not_supported_outlined,
                                  size: 24, color: Colors.grey[400]),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.image_outlined,
                              size: 24, color: Colors.grey[400]),
                        ),
                ),
                const SizedBox(width: 12),

                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        productName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1A1A),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        genderCategory,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF757575),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            '₹$price',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                          if (discount > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '₹${(int.tryParse(price.toString()) ?? 0) * (100 + discount) ~/ 100}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: const Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$discount% OFF',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD32F2F),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String suggestion) {
    return InkWell(
      onTap: () {
        _searchController.text = suggestion;
        _goToSearchResults(suggestion);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 6, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Text(
          suggestion,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF424242),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return InkWell(
      onTap: () {
        _searchController.text = search;
        _goToSearchResults(search);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.history, size: 16, color: Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                search,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF424242),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: Colors.grey[400]),
              onPressed: () => _removeRecentSearch(search),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Text(
            _hasSearched ? 'Results' : 'Search',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (_hasSearched && _searchResults.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_searchResults.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF616161),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6,
              bottom: 6,
              left: 12,
              right: 12,
            ),
            child: Row(
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                // Search Field
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(width: 0.2, color: Colors.black12)
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _updateSuggestions,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _goToSearchResults(value);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Search products',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF9E9E9E),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1
                        ),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF757575), size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: Color(0xFF757575)),
                                onPressed: _clearSearch,
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(height: 1, color: const Color(0xFFEEEEEE)),

          // Content
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Loading State
                if (_isLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF424242)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Searching...',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF757575),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )

                // Search Results (Preview)
                else if (_hasSearched && _searchResults.isNotEmpty)
                  SliverList(
                    delegate: SliverChildListDelegate([
                      _buildSearchHeader(),
                      ..._searchResults.asMap().entries.map(
                            (entry) =>
                                _buildProductItem(entry.value, entry.key),
                          ),
                      // See All Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () =>
                                _goToSearchResults(_searchController.text),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFF1A1A1A), width: 1.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'See All Results',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward,
                                      size: 16, color: Color(0xFF1A1A1A)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  )

                // No Results Found
                else if (_hasSearched && _searchResults.isEmpty)
                  SliverFillRemaining(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.search_off,
                              size: 40, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try searching with different keywords',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  )

                // Initial State - Recent & Popular
                else if (_showRecentSearches && _searchController.text.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.all(14),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Recent Searches (First)
                        if (_recentSearches.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Recent',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextButton(
                                onPressed: _clearRecentSearches,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Clear All',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFEEEEEE), width: 1),
                            ),
                            child: Column(
                              children:
                                  _recentSearches.asMap().entries.map((entry) {
                                return Column(
                                  children: [
                                    _buildRecentSearchItem(entry.value),
                                    if (entry.key < _recentSearches.length - 1)
                                      Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: const Color(0xFFF5F5F5)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Popular Searches (Second)
                        Text(
                          'Popular Searches',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          children:
                              _suggestions.map(_buildSuggestionChip).toList(),
                        ),
                      ]),
                    ),
                  )

                // Filtered Suggestions
                else if (_filteredSuggestions.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final suggestion = _filteredSuggestions[index];
                        return InkWell(
                          onTap: () {
                            _searchController.text = suggestion;
                            _goToSearchResults(suggestion);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.search,
                                    color: Colors.grey[500], size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    suggestion,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF424242),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(Icons.north_west,
                                    size: 14, color: Colors.grey[400]),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: _filteredSuggestions.length,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
