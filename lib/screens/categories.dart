import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/e-category_model.dart';
import 'package:flutter_app/models/e-subcategory_model.dart';
import 'package:flutter_app/models/images_model.dart';
import 'package:flutter_app/screens/product_list.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/custom_widgets/cart_badge.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:async';

import 'search_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Category>> categories;
  Category? selectedCategory;
  late Future<List<Subcategory>> subcategories;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _borderAnimationController;
  late Animation<double> _borderAnimation;
  Timer? _animationTimer;
  List<bool> _visibleItems = [];

  @override
  void initState() {
    super.initState();
    categories = ApiService.fetchCategories();
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _borderAnimation = CurvedAnimation(
      parent: _borderAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _animationTimer?.cancel();
    super.dispose();
  }

// Add this to your _loadSubcategories method, right after setting subcategories
  void _loadSubcategories(String categoryId) {
    // If the selected category is already loaded, don't reload it
    if (selectedCategory?.id == categoryId) {
      return;
    }

    _animationTimer?.cancel();
    _borderAnimationController.reverse();
    _borderAnimationController.forward();

    categories.then((cats) {
      if (mounted) {
        setState(() {
          selectedCategory = cats.firstWhere((cat) => cat.id == categoryId,
              orElse: () => cats.first);
          subcategories = ApiService.fetchSubcategories(categoryId);

          // Reset visibility for animation
          _visibleItems = [];
        });
      }

      _animationTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _borderAnimationController.reverse();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: Text(
          'All Categories',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 20,
        elevation: 0,
        backgroundColor: Colors.white,
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
          const CartIconWithBadge(),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Category>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLayout();
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No categories available'));
          } else {
            // Initialize with first category if none selected
            if (selectedCategory == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadSubcategories(snapshot.data!.first.id);
              });
              return _buildShimmerLayout();
            }
            return _buildCategoryLayout(snapshot.data!);
          }
        },
      ),
    );
  }

  Widget _buildCategoryLayout(List<Category> categories) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side - Categories list
        Container(
          width: MediaQuery.of(context).size.width / 4,
          decoration: BoxDecoration(
            // color: Colors.grey[100],
            color: Color(0xfff0f4f7),
            border: Border(
              right: BorderSide(color: Colors.grey[200]!),
            ),
          ), //
          child: ListView.builder(
            controller: _scrollController,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryItem(category);
            },
          ),
        ),

        // Right side - Subcategories
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header
                _buildCategoryHeader(),
                const SizedBox(height: 20),

                // Subcategories grid
                FutureBuilder<List<Subcategory>>(
                  future: subcategories,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerGrid();
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No subcategories available'));
                    } else {
                      return _buildSubcategoriesGrid(snapshot.data!);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedCategory!.name,
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 9),
        Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildCategoryItem(Category category) {
    final isSelected = selectedCategory?.id == category.id;

    return InkWell(
      onTap: () => _loadSubcategories(category.id),
      child: AnimatedBuilder(
        animation: _borderAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected
                      ? Colors.indigoAccent
                          .withOpacity(_borderAnimation.value * 0.7 + 0.3)
                      : Colors.transparent,
                  width: isSelected ? 3 * _borderAnimation.value + 1 : 0,
                ),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 2), // Bottom shadow
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, -2), // Top shadow
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                // Add scale animation to the icon
                ScaleTransition(
                  scale: isSelected
                      ? Tween<double>(begin: 1.0, end: 1.1)
                          .animate(_borderAnimation)
                      : AlwaysStoppedAnimation(1.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.network(
                      category.image,
                      height: 45,
                      width: 45,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Add color fade animation to the text
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.manrope(
                    fontSize: isSelected ? 12 : 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.indigoAccent : Colors.grey[700],
                    letterSpacing: 0.1,
                  ),
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubcategoriesGrid(List<Subcategory> subcategories) {
    // Group subcategories by gender/type if they have that property
    final genderSubcategories =
        subcategories.map((subcat) => subcat.gender).toSet().toList();

    // Initialize visibility list if needed
    if (_visibleItems.isEmpty) {
      _visibleItems = List.generate(genderSubcategories.length, (_) => false);

      // Start showing items with cascading effect
      for (int i = 0; i < genderSubcategories.length; i++) {
        Future.delayed(Duration(milliseconds: 30 * i), () {
          if (mounted) {
            setState(() {
              if (i < _visibleItems.length) {
                _visibleItems[i] = true;
              }
            });
          }
        });
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: 0.78,
      ),
      itemCount: genderSubcategories.length,
      itemBuilder: (context, index) {
        final gender = genderSubcategories[index];

        // Apply simple fade animation
        return AnimatedOpacity(
          opacity:
              index < _visibleItems.length && _visibleItems[index] ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeIn,
          child: _buildSubcategoryCard(gender),
        );
      },
    );
  }

  Widget _buildSubcategoryCard(String gender) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.push(
              context,
              CustomCupertinoPageRoute(
                builder: (context) => ProductScreen(
                  categoryId: selectedCategory!.id,
                  gender: gender,
                ),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100]),
            child: _getSubcategoryImage(gender),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          gender,
          style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.1),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _getSubcategoryImage(String gender) {
    final categoryName = selectedCategory?.name ?? '';
    final images = CategoryImages.getImages(categoryName);
    final imagePath = images[gender] ?? CategoryImages.defaultImage;

    return Image.asset(
      imagePath,
      width: 40,
      height: 40,
      // fit: BoxFit.contain,
    );
  }

  Widget _buildShimmerLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side shimmer
        Container(
          width: MediaQuery.of(context).size.width / 4,
          color: Colors.grey[50],
          child: Skeletonizer(
            enabled: true,
            effect: ShimmerEffect(
              duration: Duration(milliseconds: 400),
            ),
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, index) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Column(
                    children: [
                      Bone.circle(
                        size: 45,
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Bone.text(
                        width: 50,
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Right side shimmer
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 11),

                // Header shimmer
                Skeletonizer(
                  child: Bone.button(
                    width: 100,
                    height: 25,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                const SizedBox(height: 23),

                // Grid shimmer
                _buildShimmerGrid(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    return Skeletonizer(
      effect: ShimmerEffect(
        duration: Duration(milliseconds: 400),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
          childAspectRatio: 0.78,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Bone.square(
                  size: 40,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 5),
              Bone.text(
                width: 40,
              ),
            ],
          );
        },
      ),
    );
  }
}
