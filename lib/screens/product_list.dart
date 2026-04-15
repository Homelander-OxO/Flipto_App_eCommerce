import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_app/models/e-subcategory_model.dart';
import 'package:flutter_app/screens/product_screen.dart';
import 'package:flutter_app/screens/search_screen.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/screens/cart_page.dart';
import 'package:flutter_app/screens/favourite.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/cart_badge.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/custom_widgets/loading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
class ProductScreen extends StatefulWidget {
  final String categoryId;
  final String gender;

  const ProductScreen({
    super.key,
    required this.categoryId,
    required this.gender,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<List<Subcategory>> products;
  String selectedType = 'All';
  List<String> productTypes = ['All'];

  @override
  void initState() {
    super.initState();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    products = ApiService.fetchSubcategories(widget.categoryId).then((data) {
      // Filter products by gender
      List<Subcategory> filteredData = data
          .where(
              (item) => item.gender == widget.gender || widget.gender == "All")
          .toList();

      // Extract unique types
      Set<String> types = filteredData.map((e) => e.type).toSet();
      setState(() {
        productTypes.addAll(types); // Dynamically add available types
      });

      for (var product in filteredData) {
        cartProvider.loadProductRating(product.product_id);
      }
      return filteredData;
    });
  }

  String _getThumbnailFromProduct(Subcategory product) {
    try {
      // If your image field contains JSON, parse it
      final imageData = jsonDecode(product.image);
      if (imageData is Map &&
          imageData['main'] is List &&
          imageData['main'].isNotEmpty) {
        return imageData['main'][0];
      }
    } catch (e) {
      // If parsing fails, use the image field directly
      return product.image;
    }
    return product.image; // fallback
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "${widget.gender} Products",
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
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
      body: FutureBuilder<List<Subcategory>>(
        future: products,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: SimpleCircularLoader(color: Colors.indigoAccent));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text("No products found for ${widget.gender}"));
          }
          List<Subcategory> filteredProducts = selectedType == 'All'
              ? snapshot.data!
              : snapshot.data!
                  .where((item) => item.type == selectedType)
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Type Filter (Horizontal)
              Container(
                height: 30,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: productTypes.length,
                  itemBuilder: (context, index) {
                    String type = productTypes[index];
                    bool isSelected = type == selectedType;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedType = type;
                        });
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey, width: 0.8),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Product Grid with Shared Axis Transition
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  child: PageTransitionSwitcher(
                    duration: Duration(milliseconds: 300),
                    transitionBuilder: (
                      Widget child,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                    ) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.vertical,
                        child: child,
                      );
                    },
                    child: GridView.builder(
                      key: ValueKey<String>(selectedType),
                      padding: EdgeInsets.symmetric(vertical: 5),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 1.3,
                        mainAxisSpacing: 1.3,
                        childAspectRatio: 0.53,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final discount =
                            int.tryParse(filteredProducts[index].discount) ?? 0;
                        final originalPrice =
                            int.parse(filteredProducts[index].price);
                        final discountedPrice =
                            originalPrice * (100 - discount) / 100;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CustomCupertinoPageRoute(
                                builder: (context) => ItemDetailScreen(
                                  subcategory: filteredProducts[index],
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                            child: Container(
                              color: Colors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product image with wishlist icon
                                  Stack(
                                    children: [
                                      Container(
                                        height:
                                            MediaQuery.of(context).size.height /
                                                3.5,
                                        // height: 250,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: NetworkImage(
                                                _getThumbnailFromProduct(
                                                    filteredProducts[index])),
                                            // fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Consumer<CartProvider>(
                                          builder: (context, cartProvider, _) {
                                            final isInWishlist = cartProvider
                                                .isProductInWishlist(
                                                    filteredProducts[index]
                                                        .product_id);
                                            final isLoading =
                                                cartProvider.isLoadingWishlist;

                                            return Container(
                                              height: 36,
                                              width: 36,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                              ),
                                              child: Center(
                                                child: IconButton(
                                                  icon: isLoading
                                                      ? SizedBox(
                                                          width: 16,
                                                          height: 16,
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      1.5),
                                                        )
                                                      : Icon(
                                                          isInWishlist
                                                              ? Icons.favorite
                                                              : Icons
                                                                  .favorite_border,
                                                          size: 22,
                                                          color: isInWishlist
                                                              ? Colors.red
                                                              : Colors.black54,
                                                        ),
                                                  onPressed: isLoading
                                                      ? null
                                                      : () async {
                                                          final success =
                                                              await cartProvider
                                                                  .toggleWishlist(
                                                            filteredProducts[
                                                                    index]
                                                                .product_id,
                                                          );

                                                          if (success) {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                content: Text(cartProvider
                                                                        .isProductInWishlist(
                                                                            filteredProducts[index].product_id)
                                                                    ? 'Added to wishlist!'
                                                                    : 'Removed from wishlist!'),
                                                                duration:
                                                                    Duration(
                                                                        seconds:
                                                                            1),
                                                              ),
                                                            );
                                                          } else {
                                                            ScaffoldMessenger
                                                                    .of(context)
                                                                .showSnackBar(
                                                              SnackBar(
                                                                  content: Text(
                                                                      'Failed to update wishlist')),
                                                            );
                                                          }
                                                        },
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Product details
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        // Price section
                                        Row(
                                          children: [
                                            Text(
                                              '₹${discountedPrice}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            if (discount > 0) ...[
                                              SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Text(
                                                    '₹${originalPrice.toStringAsFixed(0)}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    '$discount% OFF',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(height: 2),
                                        // Free delivery
                                        Text(
                                          'Free Delivery',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        // Rating
                                        Row(
                                          children: [
                                            Row(
                                              children: [
                                                Consumer<CartProvider>(
                                                  builder: (context,
                                                      cartProvider, _) {
                                                    final rating = cartProvider
                                                        .getRatingForProduct(
                                                            product.product_id);
                                                    final count = cartProvider
                                                        .getRatingCountForProduct(
                                                            product.product_id);

                                                    return Row(
                                                      children: [
                                                        Container(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal: 7,
                                                                  vertical:
                                                                      1.8),
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
                                                                  width: 2),
                                                              Text(
                                                                rating
                                                                    .toStringAsFixed(
                                                                        1),
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          '($count)',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                            Spacer(),
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
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
}
