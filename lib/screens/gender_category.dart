import 'dart:convert';
import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/e-subcategory_model.dart';
import 'package:flutter_app/models/images_model.dart';
import 'package:flutter_app/screens/product_list.dart';
import 'package:flutter_app/screens/product_screen.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/screens/search_screen.dart';
import 'package:flutter_app/screens/cart_page.dart';
import 'package:flutter_app/screens/favourite.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/cart_badge.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/custom_widgets/loading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

enum SortOption {
  popular,
  priceLowToHigh,
  priceHighToLow,
  nameAtoZ,
  nameZtoA,
}

class FilterOptions {
  double minPrice;
  double maxPrice;
  double minRating;
  Set<String> genders;
  bool showDiscountedOnly; // Add this line

  FilterOptions({
    this.minPrice = 0,
    this.maxPrice = double.infinity,
    this.minRating = 0,
    this.genders = const {},
    this.showDiscountedOnly = false, // Add this with default false
  });

  FilterOptions copyWith({
    double? minPrice,
    double? maxPrice,
    double? minRating,
    Set<String>? genders,
    bool? showDiscountedOnly, // Add this
  }) {
    return FilterOptions(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      genders: genders ?? this.genders,
      showDiscountedOnly:
          showDiscountedOnly ?? this.showDiscountedOnly, // Add this
    );
  }

  bool get isDefault =>
      minPrice == 0 &&
      maxPrice == double.infinity &&
      minRating == 0 &&
      genders.isEmpty &&
      !showDiscountedOnly; // Add this condition
}

class GenderCategory extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const GenderCategory({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<GenderCategory> createState() => _GenderCategoryState();
}

class _GenderCategoryState extends State<GenderCategory> {
  late Future<List<Subcategory>> subcategories;
  List<String> subcategoryGender = [];
  SortOption currentSortOption = SortOption.popular;
  FilterOptions filterOptions = FilterOptions();
  bool showFilters = false;
  bool _filtersChanged = false;
  late ValueNotifier<bool> _filtersNotifier;

  List<Subcategory> _applySortingAndFiltering(List<Subcategory> products) {
    // Apply filters
    List<Subcategory> filteredProducts = products.where((product) {
      // Parse price with better error handling
      final price =
          double.tryParse(product.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0;
      final discount = double.tryParse(
              product.discount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          0;
      final discountedPrice = price * (100 - discount) / 100;

      // Get rating with default value
      final rating = Provider.of<CartProvider>(context, listen: false)
              .getRatingForProduct(product.product_id) ??
          0;

      // Price filter
      final priceFilter = discountedPrice >= filterOptions.minPrice &&
          discountedPrice <= filterOptions.maxPrice;

      // Rating filter
      final ratingFilter = rating >= filterOptions.minRating;

      // Gender filter (case insensitive)
      final genderFilter = filterOptions.genders.isEmpty ||
          filterOptions.genders
              .any((g) => g.toLowerCase() == product.gender.toLowerCase());
      final discountFilter = !filterOptions.showDiscountedOnly || discount > 0;

      return priceFilter && ratingFilter && genderFilter && discountFilter;
    }).toList();

    // Apply sorting
    switch (currentSortOption) {
      case SortOption.popular:
        filteredProducts.sort((a, b) {
          final ratingA = Provider.of<CartProvider>(context, listen: false)
                  .getRatingCountForProduct(a.product_id) ??
              0;
          final ratingB = Provider.of<CartProvider>(context, listen: false)
                  .getRatingCountForProduct(b.product_id) ??
              0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case SortOption.priceLowToHigh:
        filteredProducts.sort((a, b) {
          final priceA =
              (double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                      0) *
                  (100 -
                      (double.tryParse(
                              a.discount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                          0)) /
                  100;
          final priceB =
              (double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                      0) *
                  (100 -
                      (double.tryParse(
                              b.discount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                          0)) /
                  100;
          return priceA.compareTo(priceB);
        });
        break;
      case SortOption.priceHighToLow:
        filteredProducts.sort((a, b) {
          final priceA =
              (double.tryParse(a.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                      0) *
                  (100 -
                      (double.tryParse(
                              a.discount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                          0)) /
                  100;
          final priceB =
              (double.tryParse(b.price.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                      0) *
                  (100 -
                      (double.tryParse(
                              b.discount.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                          0)) /
                  100;
          return priceB.compareTo(priceA);
        });
        break;
      case SortOption.nameAtoZ:
        filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameZtoA:
        filteredProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
    }

    return filteredProducts;
  }

  // Make sure to update your 'sorting' logic to also use the notifier
  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Colors.grey[50],
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                'Sort By',
                style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600, fontSize: 18),
              ),
              SizedBox(height: 12),
              ...SortOption.values.map((option) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _getSortOptionText(option),
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      color: currentSortOption == option
                          ? Colors.indigoAccent
                          : Colors.black87,
                      fontWeight: currentSortOption == option
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      currentSortOption = option;
                      _filtersNotifier.value = !_filtersNotifier.value;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  child: Text('Cancel',
                      style: TextStyle(color: Colors.red, fontSize: 14)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    double tempMinPrice = filterOptions.minPrice;
    double tempMaxPrice = filterOptions.maxPrice == double.infinity
        ? 10000
        : filterOptions.maxPrice;
    double tempMinRating = filterOptions.minRating;
    Set<String> tempGenders = Set.from(filterOptions.genders);
    bool tempShowDiscountedOnly = filterOptions.showDiscountedOnly;

    Navigator.of(context).push(
      CupertinoSheetRoute(
        builder: (context) {
          return Material(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final primaryColor = Color(0xFF6366F1); // Modern indigo
                  final surfaceColor =
                      isDark ? Color(0xFF1E293B) : Color(0xFFF8FAFC);
                  final cardColor = isDark ? Color(0xFF334155) : Colors.white;
                  final textColor = isDark ? Colors.white : Color(0xFF1E293B);
                  final subtitleColor =
                      isDark ? Color(0xFF94A3B8) : Color(0xFF64748B);

                  return Column(
                    children: [
                      // Modern Drag Handle
                      Container(
                        width: 48,
                        height: 4,
                        margin: EdgeInsets.only(top: 12, bottom: 8),
                        decoration: BoxDecoration(
                          color: subtitleColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header Section
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filter Products',
                                    style: GoogleFonts.manrope(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    'Find exactly what you\'re looking for',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: subtitleColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        height: 1,
                        margin: EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              subtitleColor.withOpacity(0.1),
                              subtitleColor.withOpacity(0.3),
                              subtitleColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Price Range Section
                              _buildFilterSection(
                                title: 'Price Range',
                                icon: Icons.payments_outlined,
                                primaryColor: primaryColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                child: Column(
                                  children: [
                                    SizedBox(height: 16),
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: surfaceColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: subtitleColor.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildPriceChip(
                                                  '₹${tempMinPrice.toInt()}',
                                                  primaryColor),
                                              Container(
                                                width: 24,
                                                height: 2,
                                                decoration: BoxDecoration(
                                                  color: primaryColor
                                                      .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(1),
                                                ),
                                              ),
                                              _buildPriceChip(
                                                  '₹${tempMaxPrice.toInt()}',
                                                  primaryColor),
                                            ],
                                          ),
                                          SizedBox(height: 20),
                                          SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                              activeTrackColor: primaryColor,
                                              inactiveTrackColor:
                                                  primaryColor.withOpacity(0.2),
                                              thumbColor: primaryColor,
                                              overlayColor:
                                                  primaryColor.withOpacity(0.1),
                                              thumbShape: RoundSliderThumbShape(
                                                  enabledThumbRadius: 12),
                                              overlayShape:
                                                  RoundSliderOverlayShape(
                                                      overlayRadius: 20),
                                              rangeThumbShape:
                                                  RoundRangeSliderThumbShape(
                                                      enabledThumbRadius: 12),
                                              trackHeight: 4,
                                            ),
                                            child: RangeSlider(
                                              values: RangeValues(
                                                  tempMinPrice, tempMaxPrice),
                                              min: 0,
                                              max: 10000,
                                              divisions: 20,
                                              onChanged: (values) {
                                                setModalState(() {
                                                  tempMinPrice = values.start;
                                                  tempMaxPrice = values.end;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 32),

                              // Rating Section
                              _buildFilterSection(
                                title: 'Minimum Rating',
                                icon: Icons.star_outline_rounded,
                                primaryColor: primaryColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                child: Column(
                                  children: [
                                    SizedBox(height: 16),
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: surfaceColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: subtitleColor.withOpacity(0.1),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: List.generate(6, (index) {
                                              return Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: tempMinRating >= index
                                                      ? primaryColor
                                                      : primaryColor
                                                          .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.star_rounded,
                                                  size: 16,
                                                  color: tempMinRating >= index
                                                      ? Colors.white
                                                      : primaryColor
                                                          .withOpacity(0.5),
                                                ),
                                              );
                                            }),
                                          ),
                                          SizedBox(height: 20),
                                          SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                              activeTrackColor: primaryColor,
                                              inactiveTrackColor:
                                                  primaryColor.withOpacity(0.2),
                                              thumbColor: primaryColor,
                                              overlayColor:
                                                  primaryColor.withOpacity(0.1),
                                              thumbShape: RoundSliderThumbShape(
                                                  enabledThumbRadius: 12),
                                              overlayShape:
                                                  RoundSliderOverlayShape(
                                                      overlayRadius: 20),
                                              trackHeight: 4,
                                            ),
                                            child: Slider(
                                              value: tempMinRating,
                                              min: 0,
                                              max: 5,
                                              divisions: 5,
                                              onChanged: (value) =>
                                                  setModalState(() =>
                                                      tempMinRating = value),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 32),

                              // Discount Section
                              _buildFilterSection(
                                title: 'Special Offers',
                                icon: Icons.local_offer_outlined,
                                primaryColor: primaryColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                child: Column(
                                  children: [
                                    SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: () => setModalState(() =>
                                          tempShowDiscountedOnly =
                                              !tempShowDiscountedOnly),
                                      child: Container(
                                        padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: tempShowDiscountedOnly
                                              ? primaryColor.withOpacity(0.1)
                                              : surfaceColor,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: tempShowDiscountedOnly
                                                ? primaryColor.withOpacity(0.3)
                                                : subtitleColor
                                                    .withOpacity(0.1),
                                            width:
                                                tempShowDiscountedOnly ? 2 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: tempShowDiscountedOnly
                                                    ? primaryColor
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: tempShowDiscountedOnly
                                                      ? primaryColor
                                                      : subtitleColor
                                                          .withOpacity(0.4),
                                                  width: 2,
                                                ),
                                              ),
                                              child: tempShowDiscountedOnly
                                                  ? Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Discounted Items Only',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Show products with active discounts',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 13,
                                                      color: subtitleColor,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 32),

                              // Gender Section
                              _buildFilterSection(
                                title: 'Categories',
                                icon: Icons.category_outlined,
                                primaryColor: primaryColor,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                child: Column(
                                  children: [
                                    SizedBox(height: 16),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: subcategoryGender.map((gender) {
                                        final selected =
                                            tempGenders.contains(gender);
                                        return GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              selected
                                                  ? tempGenders.remove(gender)
                                                  : tempGenders.add(gender);
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration:
                                                Duration(milliseconds: 200),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? primaryColor
                                                  : surfaceColor,
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              border: Border.all(
                                                color: selected
                                                    ? primaryColor
                                                    : subtitleColor
                                                        .withOpacity(0.2),
                                                width: selected ? 2 : 1,
                                              ),
                                              boxShadow: selected
                                                  ? [
                                                      BoxShadow(
                                                        color: primaryColor
                                                            .withOpacity(0.3),
                                                        blurRadius: 12,
                                                        offset: Offset(0, 4),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (selected)
                                                  Container(
                                                    width: 16,
                                                    height: 16,
                                                    margin: EdgeInsets.only(
                                                        right: 8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(
                                                      Icons.check,
                                                      size: 12,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                Text(
                                                  gender,
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 14,
                                                    fontWeight: selected
                                                        ? FontWeight.w600
                                                        : FontWeight.w500,
                                                    color: selected
                                                        ? Colors.white
                                                        : textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // Action Buttons
                      Container(
                        margin: EdgeInsets.only(bottom: 34),
                        padding: EdgeInsets.fromLTRB(18, 15, 18, 44),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 0,
                              child: Container(
                                height: 55,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: subtitleColor.withOpacity(0.3),
                                        width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      filterOptions = FilterOptions();
                                      _filtersNotifier.value =
                                          !_filtersNotifier.value;
                                    });
                                  },
                                  child: Text(
                                    'Reset All',
                                    style: GoogleFonts.manrope(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    shadowColor: primaryColor.withOpacity(0.3),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      filterOptions = FilterOptions(
                                        minPrice: tempMinPrice,
                                        maxPrice: tempMaxPrice == 10000
                                            ? double.infinity
                                            : tempMaxPrice,
                                        minRating: tempMinRating,
                                        genders: tempGenders,
                                        showDiscountedOnly:
                                            tempShowDiscountedOnly,
                                      );
                                      _filtersNotifier.value =
                                          !_filtersNotifier.value;
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.tune_rounded,
                                          size: 20, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Apply Filter',
                                        style: GoogleFonts.manrope(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

// Helper method for filter sections
  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Color primaryColor,
    required Color textColor,
    required Color subtitleColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }

// Helper method for price chips
  Widget _buildPriceChip(String price, Color primaryColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
        ),
      ),
      child: Text(
        price,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
      ),
    );
  }

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.popular:
        return 'Popular';
      case SortOption.priceLowToHigh:
        return 'Price: Low to High';
      case SortOption.priceHighToLow:
        return 'Price: High to Low';
      case SortOption.nameAtoZ:
        return 'Name: A to Z';
      case SortOption.nameZtoA:
        return 'Name: Z to A';
    }
  }

  @override
  void initState() {
    super.initState();
    subcategories =
        ApiService.fetchSubcategories(widget.categoryId).then((data) {
      Set<String> genders = data.map((e) => e.gender).toSet();
      setState(() {
        subcategoryGender = genders.toList(); // Removed "All" option
      });
      return data;
    });
    _filtersNotifier = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _filtersNotifier.dispose();
    super.dispose();
  }

  String _getThumbnailFromProduct(Subcategory product) {
    try {
      // The image is already stored as JSON string, decode it
      final imageData = jsonDecode(product.image);
      if (imageData is Map &&
          imageData['main'] is List &&
          imageData['main'].isNotEmpty) {
        return imageData['main'][0];
      }
    } catch (e) {
      // Fallback to first main image from productDetails if available
      if (product.productDetails.mainImages.isNotEmpty) {
        return product.productDetails.mainImages.first;
      }
    }
    // Ultimate fallback - return empty string or placeholder
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final bgColor = isDark ? Colors.grey[850]! : Colors.grey[50]!;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.categoryName,
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
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
                  builder: (context) => SearchScreen100(),
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
      bottomNavigationBar: BottomAppBar(
        height: 65,
        color: isDark ? Colors.grey[900] : Colors.white,
        elevation: 4,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showSortBottomSheet,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.sort_down, size: 24),
                  Text('Sort', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showFilterBottomSheet,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.slider_horizontal_3, size: 24),
                  Text('Filter', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Active Filters
          _buildActiveFiltersIndicator(),

          // Gender Categories
          Container(
            height: 100,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subcategoryGender.length,
              itemBuilder: (context, index) {
                String gender = subcategoryGender[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            CustomCupertinoPageRoute(
                              builder: (context) => ProductScreen(
                                categoryId: widget.categoryId,
                                gender: gender,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            image: DecorationImage(
                              image: AssetImage(
                                CategoryImages.getImages(
                                        widget.categoryName)[gender] ??
                                    CategoryImages.defaultImage,
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        gender,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Products Grid
          Expanded(
            child: FutureBuilder<List<Subcategory>>(
              future: subcategories,
              builder: (context, snapshot) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _filtersNotifier,
                  builder: (context, _, __) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child:
                              SimpleCircularLoader(color: Colors.indigoAccent));
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading products',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No products available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      );
                    } else {
                      List<Subcategory> productList =
                          _applySortingAndFiltering(snapshot.data!);

                      if (productList.isEmpty) {
                        return Center(
                          child: Text(
                            'No products match your filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        );
                      }

                      final cartProvider =
                          Provider.of<CartProvider>(context, listen: false);
                      for (var product in productList) {
                        cartProvider.loadProductRating(product.product_id);
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: BouncingScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 0,
                            mainAxisSpacing: 0,
                            childAspectRatio: 0.57,
                          ),
                          itemCount: productList.length,
                          itemBuilder: (context, index) {
                            final discount =
                                int.tryParse(productList[index].discount) ?? 0;
                            final originalPrice =
                                int.parse(productList[index].price);
                            final discountedPrice =
                                originalPrice * (100 - discount) / 100;

                            return OpenContainer(
                              closedColor: Colors.transparent,
                              openColor: bgColor,
                              closedElevation: 0,
                              openElevation: 0,
                              closedBuilder: (context, action) {
                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: cardColor,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Product Image
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                              child: Container(
                                                height: 205,
                                                width: double.infinity,
                                                child: Image.network(
                                                  _getThumbnailFromProduct(
                                                      productList[index]),
                                                  // fit: BoxFit.cover,
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Consumer<CartProvider>(
                                                builder:
                                                    (context, cartProvider, _) {
                                                  final isInWishlist =
                                                      cartProvider
                                                          .isProductInWishlist(
                                                              productList[index]
                                                                  .product_id);
                                                  return GestureDetector(
                                                    onTap: () async {
                                                      final success =
                                                          await cartProvider
                                                              .toggleWishlist(
                                                                  productList[
                                                                          index]
                                                                      .product_id);
                                                      if (success) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(isInWishlist
                                                                ? 'Removed from wishlist'
                                                                : 'Added to wishlist'),
                                                            duration: Duration(
                                                                seconds: 1),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: cardColor
                                                            .withOpacity(0.8),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        isInWishlist
                                                            ? Icons.favorite
                                                            : Icons
                                                                .favorite_border,
                                                        size: 20,
                                                        color: isInWishlist
                                                            ? Colors.red
                                                            : textColor,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Product Details
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                productList[index].name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.manrope(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: textColor,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    '₹${discountedPrice.toStringAsFixed(1)}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.white
                                                          : Colors.black,
                                                      letterSpacing: 0.1
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  if (discount > 0)
                                                    Text(
                                                      '₹${originalPrice.toStringAsFixed(1)}',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        color: Colors.grey[600],
                                                              letterSpacing: -0.1

                                                      ),
                                                    ),
                                                  SizedBox(width: 6),
                                                  if (discount > 0)
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green[50],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        '$discount% OFF',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 10,
                                                          color:
                                                              Colors.green[800],
                                                          fontWeight:
                                                              FontWeight.w600,
                                                                letterSpacing: -0.1

                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Consumer<CartProvider>(
                                                    builder: (context,
                                                        cartProvider, _) {
                                                      final rating = cartProvider
                                                          .getRatingForProduct(
                                                              productList[index]
                                                                  .product_id);
                                                      final count = cartProvider
                                                          .getRatingCountForProduct(
                                                              productList[index]
                                                                  .product_id);
                                                      return Row(
                                                        children: [
                                                          Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        1),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .green[500],
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.star,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 13),
                                                                SizedBox(
                                                                    width: 1),
                                                                Text(
                                                                  rating
                                                                      .toStringAsFixed(
                                                                          1),
                                                                  style: GoogleFonts.poppins(
                                                                      fontSize:
                                                                          12,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            '(${count.toString()})',
                                                            style: TextStyle(
                                                              letterSpacing:
                                                                  0.01,
                                                              fontSize: 13,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                              openBuilder: (context, action) {
                                return ItemDetailScreen(
                                    subcategory: productList[index]);
                              },
                            );
                          },
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Updated _buildActiveFiltersIndicator with modern design
  Widget _buildActiveFiltersIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: _filtersNotifier,
      builder: (context, _, __) {
        if (filterOptions.isDefault) return SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Filters:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (filterOptions.minPrice > 0 ||
                      filterOptions.maxPrice < double.infinity)
                    Chip(
                      label: Text(
                        'Price: ₹${filterOptions.minPrice.toInt()} - ${filterOptions.maxPrice == double.infinity ? '∞' : '₹${filterOptions.maxPrice.toInt()}'}',
                      ),
                      onDeleted: () {
                        setState(() {
                          filterOptions = filterOptions.copyWith(
                            minPrice: 0,
                            maxPrice: double.infinity,
                          );
                          _filtersNotifier.value = !_filtersNotifier.value;
                        });
                      },
                      backgroundColor:
                          Theme.of(context).chipTheme.backgroundColor,
                      deleteIconColor: Theme.of(context).iconTheme.color,
                    ),
                  if (filterOptions.minRating > 0)
                    Chip(
                      label: Text(
                          'Rating: ${filterOptions.minRating.toStringAsFixed(1)}+'),
                      onDeleted: () {
                        setState(() {
                          filterOptions = filterOptions.copyWith(minRating: 0);
                          _filtersNotifier.value = !_filtersNotifier.value;
                        });
                      },
                      backgroundColor:
                          Theme.of(context).chipTheme.backgroundColor,
                      deleteIconColor: Theme.of(context).iconTheme.color,
                    ),
                  ...filterOptions.genders.map(
                    (gender) => Chip(
                      label: Text(gender),
                      onDeleted: () {
                        setState(() {
                          filterOptions = filterOptions.copyWith(
                            genders: Set.from(filterOptions.genders)
                              ..remove(gender),
                          );
                          _filtersNotifier.value = !_filtersNotifier.value;
                        });
                      },
                      backgroundColor:
                          Theme.of(context).chipTheme.backgroundColor,
                      deleteIconColor: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
