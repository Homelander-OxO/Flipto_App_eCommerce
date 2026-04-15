import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/screens/product_screen.dart';
import 'package:flutter_app/Utilities/api_service.dart';

class Search extends StatefulWidget {
  final List<String> categoryIds;

  const Search({Key? key, required this.categoryIds}) : super(key: key);

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isEmpty) {
        setState(() {
          _searchResults = [];
          _suggestions = [];
        });
        return;
      }

      _getSuggestions();
      _searchProducts();
    });
  }

  void _getSuggestions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _suggestions = ApiService.searchKeywords
          .where((keyword) => keyword.toLowerCase().contains(query))
          .take(5) // Limit to 5 suggestions
          .toList();
    });
  }

  Future<void> _searchProducts() async {
    try {
      final results = await ApiService.searchProducts(_searchController.text);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching products: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _searchController,
            autofocus: true,
            cursorColor: Colors.indigoAccent[400],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              hintText: "Search for products...",
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  Icons.search_rounded,
                  color: Colors.indigoAccent[400],
                  size: 26,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _buildSearchResults(),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Text(
          'Start typing to search products',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_searchResults.isEmpty && _suggestions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        if (_suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Suggestions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _suggestions
                      .map((suggestion) => GestureDetector(
                            onTap: () {
                              _searchController.text = suggestion;
                              _searchProducts();
                            },
                            child: Chip(
                              label: Text(suggestion),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        if (_searchResults.isNotEmpty)
          ..._searchResults
              .map((product) => ProductItem(
                    product: product,
                    onTap: () {
                      // Navigate to product detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailScreen(
                            productId: product['id'].toString(),
                            subcategory: product['subcategory'],
                          ),
                        ),
                      );
                    },
                  ))
              .toList(),
      ],
    );
  }
}

class ProductItem extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;

  const ProductItem({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: product['image'] != null
          ? Image.network(product['image'], width: 50, height: 50)
          : Icon(Icons.image),
      title: Text(product['name'] ?? 'No name'),
      subtitle: Text('\$${product['price']?.toStringAsFixed(2) ?? '0.00'})'),
      onTap: onTap,
    );
  }
}
