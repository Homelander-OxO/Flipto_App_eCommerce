import 'dart:convert';
import 'dart:math';
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/address_screen.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/gender_category.dart';
import 'package:flutter_app/Utilities/ai.dart';
import 'package:flutter_app/Utilities/fcm.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/search_screen.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/banner_carousel.dart';
import 'package:flutter_app/custom_widgets/cart_badge.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/custom_widgets/loading.dart';
import 'package:flutter_app/custom_widgets/my_location.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:transparent_image/transparent_image.dart';
import '../Model/e-subcategory_model.dart';
import 'product_screen.dart';
import '../../Utilities/api_service.dart';
import '../Model/e-category_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController searchBar = TextEditingController();
  late Future<List<Category>> categories;
  late Future<List<Subcategory>> allProducts;

  // Add these missing future variables
  late Future<List<Subcategory>> _trendingProducts;
  late Future<List<Subcategory>> _bestSellers;
  late Future<List<Subcategory>> _newArrivals;
  late RecommendationService recommendationService;

  // Define category IDs for each section
  List<String> categoryIds = [
    '3',
    '4',
    '5',
    '6',
    '7',
    '8'
  ]; // General category IDs

  // Section-specific category IDs
  List<String> featuredCategoryIds = ['4', '5'];
  List<String> trendingCategoryIds = ['5', '6'];
  List<String> bestSellerCategoryIds = ['3', '5'];
  List<String> newArrivalCategoryIds = ['7', '6'];

  Future<List<Subcategory>> fetchDiscountedProducts(
      List<String> categoryIds) async {
    final allProducts = await ApiService.fetchAllProducts(categoryIds);
    allProducts.shuffle();
    return allProducts.where((product) {
      final discount = int.tryParse(product.discount) ?? 0;
      return discount > 0;
    }).toList();
  }

  Future<List<Subcategory>> fetchRecommendedProducts(
      List<String> categoryIds) async {
    final allProducts = await ApiService.fetchAllProducts(categoryIds);
    allProducts.shuffle();
    return allProducts.take(6).toList();
  }

  Future<List<Subcategory>> fetchTopRatedProducts(
      List<String> categoryIds) async {
    final allProducts = await ApiService.fetchAllProducts(categoryIds);
    allProducts
        .sort((a, b) => (b.averageRating ?? 0).compareTo(a.averageRating ?? 0));
    return allProducts.take(5).toList();
  }

// Grid layout for trending products
  Widget buildTrendingGridSection(
      String title, Future<List<Subcategory>> future) {
    var sHeight = MediaQuery.of(context).size.height;
    var sWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: ResponsiveValue<double>(
                    context,
                    defaultValue: 20.0,
                    conditionalValues: [
                      const Condition.smallerThan(name: TABLET, value: 18.0),
                      const Condition.smallerThan(name: MOBILE, value: 16.0),
                    ],
                  ).value,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: sHeight / 60),
          FutureBuilder<List<Subcategory>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildShimmerEffect(isGrid: true, itemCount: 4);
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("No products available");
              }
              return GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveValue<int>(
                      context,
                      defaultValue: 2,
                      conditionalValues: [
                        const Condition.smallerThan(name: TABLET, value: 2),
                        const Condition.largerThan(name: TABLET, value: 3),
                      ],
                    ).value,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: ResponsiveValue<double>(
                      context,
                      defaultValue: 0.75,
                      conditionalValues: [
                        const Condition.smallerThan(name: TABLET, value: 0.75),
                      ],
                    ).value),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(snapshot.data![index]);
                },
              );
            },
          )
        ],
      ),
    );
  }

// Call in your initState
  late Future<List<Subcategory>> _discountProducts;
  late Future<List<Subcategory>> _recommendedProducts;
  late Future<List<Subcategory>> _topRatedProducts;

  @override
  void initState() {
    super.initState();
    categories = ApiService.fetchCategories();
    allProducts = ApiService.fetchAllProducts(
        featuredCategoryIds); // Use featured for main products

    // Initialize each section with different category IDs
    _trendingProducts = ApiService.fetchAllProducts(trendingCategoryIds);
    _bestSellers = ApiService.fetchAllProducts(bestSellerCategoryIds);
    _newArrivals = ApiService.fetchAllProducts(newArrivalCategoryIds);

    _discountProducts = fetchDiscountedProducts(categoryIds);
    _recommendedProducts = fetchRecommendedProducts(categoryIds);
    _topRatedProducts = fetchTopRatedProducts(categoryIds);

    _fetchAddresses();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppInitializer.sendFCMTokenOnce(context);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.initWishlist(); // 👈 Await here
      setState(() {}); // 👈 Force rebuild after loading wishlist
    });
    recommendationService = RecommendationService();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userId = cartProvider.email ?? cartProvider.useremail ?? '';
    recommendationService
        .init(userId); // String? fcmToken = FirebaseApi.fcmToken;
    // if (fcmToken != null) {
    //    ApiService.sendFCMNotification(
    //     title: "",
    //     main:
    //     "",
    //     deviceToken: fcmToken,
    //      userId: 'hiren.tmbs@gmail.com'// ✅ Send FCM token dynamically
    //   );
    // } else {
    //   print("❌ FCM Token is null, notification not sent.");
    // }
  }

  void _fetchAddresses() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    Provider.of<CartProvider>(context, listen: false)
        .fetchAddresses(cartProvider.email ?? cartProvider.useremail ?? '');
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

  // Widget for product sections
  Widget _buildProductSection({
    required String title,
    required Future<List<Subcategory>> productsFuture,
    String? viewAllRoute,
  }) {
    var sHeight = MediaQuery.of(context).size.height;
    var sWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveValue<double>(
                    context,
                    defaultValue: 20.0,
                    conditionalValues: [
                      const Condition.smallerThan(name: TABLET, value: 18.0),
                      const Condition.smallerThan(name: MOBILE, value: 16.0),
                    ],
                  ).value,
                  fontWeight: FontWeight.w600, letterSpacing: 0.1
                ),
              ),
              if (viewAllRoute != null)
                GestureDetector(
                  onTap: () {
                    // Navigate to view all page for this section
                    // Navigator.push(
                    //   context,
                    //   CustomCupertinoPageRoute(
                    //     builder: (context) => ViewAll(
                    //       sectionType: viewAllRoute, // Fixed this parameter
                    //     ),
                    //   ),
                    // );
                  },
                  child: Text(
                    "View All",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: sHeight / 80),
          FutureBuilder<List<Subcategory>>(
            future: productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Skeletonizer(
                  enabled: true,
                  effect: ShimmerEffect(
                    duration: Duration(milliseconds: 400),
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height / 3.4,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 1.5),
                          // Add some spacing

                          width: MediaQuery.of(context).size.width / 2.6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image placeholder with rounded top corners
                              ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Container(
                                  height:
                                      MediaQuery.of(context).size.height / 5.8,
                                  width:
                                      MediaQuery.of(context).size.width / 2.7,
                                  color: Colors.grey[100],
                                ),
                              ),
                              // Text placeholders
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 16,
                                      color: Colors.grey[200],
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      width: 60,
                                      height: 16,
                                      color: Colors.grey[200],
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      width: 100,
                                      height: 14,
                                      color: Colors.grey[200],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("No products available"));
              } else {
                return SizedBox(
                  height: ResponsiveValue<double>(
                    context,
                    defaultValue: MediaQuery.of(context).size.height / 3.4,
                    conditionalValues: [
                      const Condition.smallerThan(name: TABLET, value: 235.0),
                    ],
                  ).value,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: ResponsiveValue<double>(
                          context,
                          defaultValue: MediaQuery.of(context).size.width / 2.6,
                          conditionalValues: [
                            const Condition.smallerThan(
                                name: TABLET, value: 138.0),
                            const Condition.largerThan(
                                name: TABLET, value: 180.0),
                          ],
                        ).value,
                        child: _buildProductCard(snapshot.data![index]),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Product card widget
  Widget _buildProductCard(Subcategory product) {
    final cartProvider = Provider.of<CartProvider>(context);
    final uEmail = cartProvider.email ?? cartProvider.useremail;
    final discount = int.tryParse(product.discount) ?? 0;
    final originalPrice = double.parse(product.price);
    final discountedPrice = originalPrice * (100 - discount) / 100;
    var sHeight = MediaQuery.of(context).size.height;
    var sWidth = MediaQuery.of(context).size.width;
    return Container(
      width: ResponsiveValue<double>(
        context,
        defaultValue: sWidth / 2.6,
        conditionalValues: [
          const Condition.smallerThan(name: TABLET, value: 150.0),
          const Condition.largerThan(name: TABLET, value: 180.0),
        ],
      ).value,
      child: GestureDetector(
        onTap: () async {
          await recommendationService.trackUserAction(
              product.product_id, 'purchase', uEmail ?? 'hiren.tmbs@gmail.com');
          print(
              'TRACKED: ${recommendationService.trackUserAction(product.product_id, 'purchase', uEmail ?? 'hiren.tmbs@gmail.com')}');
          Navigator.push(
            context,
            CustomCupertinoPageRoute(
              builder: (context) => ItemDetailScreen(subcategory: product),
            ),
          );
        },
        child: Card(
          surfaceTintColor: Colors.grey[100],
          color: Colors.grey[50],
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                child: Stack(
                  children: [
                    Container(
                      height: ResponsiveValue<double>(
                        context,
                        defaultValue: MediaQuery.of(context).size.height / 6,
                        conditionalValues: [
                          const Condition.smallerThan(
                              name: TABLET, value: 133.0),
                        ],
                      ).value,
                      width: double.infinity,
                      child: FadeInImage(
                        placeholder: MemoryImage(kTransparentImage),
                        image: NetworkImage(_getThumbnailFromProduct(product)),
                        // fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<CartProvider>(
                        builder: (context, cartProvider, _) {
                          final isInWishlist = cartProvider
                              .isProductInWishlist(product.product_id);
                          return GestureDetector(
                            onTap: () async {
                              await recommendationService.trackUserAction(
                                  product.product_id,
                                  'wishlist',
                                  uEmail ?? 'NA');
                              print(
                                  'ABC: ${recommendationService.trackUserAction(product.product_id, 'wishlist', uEmail ?? 'NA')}');
                              final success = isInWishlist
                                  ? await cartProvider
                                      .removeFromWishlist(product.product_id)
                                  : await cartProvider
                                      .addToWishlist(product.product_id);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isInWishlist
                                        ? 'Removed from wishlist'
                                        : 'Added to wishlist'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              child: Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isInWishlist ? Colors.red : Colors.black,
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Product Details
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveValue<double>(
                          context,
                          defaultValue: 12.0,
                          conditionalValues: [
                            const Condition.smallerThan(
                                name: TABLET, value: 12.5),
                          ],
                        ).value,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1
                      ),
                    ),
                    Text(
                      '₹${discountedPrice.toStringAsFixed(1)}',
                      style: GoogleFonts.poppins(
                        fontSize: ResponsiveValue<double>(
                          context,
                          defaultValue: 15.0,
                          conditionalValues: [
                            const Condition.smallerThan(
                                name: TABLET, value: 14.0),
                          ],
                        ).value,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (discount > 0) ...[
                      SizedBox(height: sHeight * 0.002),
                      Row(
                        children: [
                          Text(
                            '₹${originalPrice.toStringAsFixed(1)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(width: sWidth / 60),
                          Text(
                            '$discount% OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: sHeight / 200),
                    // Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Consumer<CartProvider>(
                          builder: (context, cartProvider, _) {
                            final rating = cartProvider
                                .getRatingForProduct(product.product_id);
                            final count = cartProvider
                                .getRatingCountForProduct(product.product_id);
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
                                SizedBox(width: sWidth / 60),
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
                        // Spacer(),
                        // Container(
                        //   padding: EdgeInsets.symmetric(
                        //       horizontal: 4, vertical: 2),
                        //   decoration: BoxDecoration(
                        //     color: Colors.purple[50],
                        //     borderRadius:
                        //     BorderRadius.circular(2),
                        //   ),
                        //   child: Row(
                        //     children: [
                        //       Icon(
                        //         Icons.verified,
                        //         color: Colors.purple,
                        //         size: 12,
                        //       ),
                        //       SizedBox(width: 2),
                        //       Text(
                        //         'Trusted',
                        //         style: TextStyle(
                        //           fontSize: 11,
                        //           color: Colors.purple,
                        //           fontWeight:
                        //           FontWeight.w500,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
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
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<CartProvider>(context).userDetails;
    var sHeight = MediaQuery.of(context).size.height;
    var sWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: true, // Ensure status bar area is protected
        bottom: false, // Optional, based on your needs
        child: CustomScrollView(
          slivers: [
            // Regular SliverAppBar that will scroll away
            SliverAppBar(
              pinned: false,
              floating: false,
              snap: false,
              elevation: 0,
              backgroundColor: Colors.grey[50],
              automaticallyImplyLeading: false,
              collapsedHeight: kToolbarHeight + 42,
              expandedHeight: kToolbarHeight + 42,
              // Add extra space
              flexibleSpace: Column(
                children: [
                  // This row will scroll up
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: ResponsiveValue<double>(
                          context,
                          defaultValue: sWidth / 26,
                          conditionalValues: [
                            const Condition.smallerThan(
                                name: TABLET, value: 10.0),
                          ],
                        ).value,
                      ),
                      MyLocation(),
                      Spacer(),
                      CartIconWithBadge(),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveValue<double>(
                        context,
                        defaultValue: 15.0,
                        conditionalValues: [
                          const Condition.smallerThan(
                              name: TABLET, value: 14.0),
                        ],
                      ).value,
                      8,
                      ResponsiveValue<double>(
                        context,
                        defaultValue: 15.0,
                        conditionalValues: [
                          const Condition.smallerThan(
                              name: TABLET, value: 14.0),
                        ],
                      ).value,
                      0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CustomCupertinoPageRoute(
                            builder: (context) => AddressScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.home_rounded,
                              color: Colors.black,
                              size: 19,
                            ),
                            SizedBox(width: sWidth * 0.0090),
                            Text(
                              "HOME",
                              style: GoogleFonts.manrope(
                                  letterSpacing: 0.1,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            SizedBox(width: sWidth / 60),
                            Expanded(
                              child: Consumer<CartProvider>(
                                builder: (context, cartProvider, child) {
                                  final defaultAddress =
                                      cartProvider.defaultAddress;

                                  return Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.8,
                                    ),
                                    child: Text(
                                      defaultAddress != null
                                          ? '${defaultAddress.apartmentNo}, ${defaultAddress.street}, ${defaultAddress.area}, ${defaultAddress.city} - ${defaultAddress.pincode}'
                                          : 'Add delivery address',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        letterSpacing: -0.1,
                                        fontSize: 14.2,
                                        // fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: 22,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pinned search bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchBarDelegate(
                child: SizedBox(
                  height: 65, // Match delegate's extent
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      ResponsiveValue<double>(
                        context,
                        defaultValue: 15.0,
                        conditionalValues: [
                          const Condition.smallerThan(
                              name: TABLET, value: 14.0),
                        ],
                      ).value,
                      0,
                      ResponsiveValue<double>(
                        context,
                        defaultValue: 15.0,
                        conditionalValues: [
                          const Condition.smallerThan(
                              name: TABLET, value: 14.0),
                        ],
                      ).value,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
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
                              onTap: () {
                                Navigator.of(context).push(
                                  CustomCupertinoPageRoute(
                                    builder: (context) => SearchScreen100(),
                                  ),
                                );
                              },
                              readOnly: true,
                              cursorColor: Colors.indigoAccent[400],
                              controller: searchBar,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade800,
                              ),
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                hintText: "Search for products...",
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                prefixIcon: Padding(
                                  padding:
                                      const EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: Colors.indigoAccent[400],
                                    size: 26,
                                  ),
                                ),
                                prefixIconConstraints:
                                    BoxConstraints(minWidth: sWidth / 40),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: sWidth * 0.0022,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: sWidth * 0.0022,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      // Banner Carousel
                      SizedBox(
                        height: ResponsiveValue<double>(
                          context,
                          defaultValue: sHeight / 40,
                          conditionalValues: [
                            const Condition.smallerThan(
                                name: TABLET, value: 10.0),
                          ],
                        ).value,
                      ),
                      MyBannerCarousel(),
                      SizedBox(
                        height: ResponsiveValue<double>(
                          context,
                          defaultValue: sHeight / 80,
                          conditionalValues: [
                            const Condition.smallerThan(
                                name: TABLET, value: 10.0),
                          ],
                        ).value,
                      ),

                      // Category Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 6, 15, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Categories",
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 0.1),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Navigator.push(
                                //     context,
                                //     CustomCupertinoPageRoute(
                                //         builder: (context) =>
                                //             ViewAll())); // Fixed: No parameter needed if ViewAll() handles it internally
                              },
                              child: Text(
                                "View All",
                                style: GoogleFonts.poppins(
                                  letterSpacing: 0.01,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sHeight / 55),

                      // Categories List (Horizontal Scroll)
                      // Replace the existing FutureBuilder for categories with this responsive version

                      FutureBuilder<List<Category>>(
                        future: categories,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Skeletonizer(
                              enabled: true,
                              child: SizedBox(
                                height: MediaQuery.of(context).size.height / 9,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 6,
                                  itemBuilder: (context, index) {
                                    return SizedBox(
                                      width: ResponsiveValue<double>(
                                        context,
                                        defaultValue:
                                            MediaQuery.of(context).size.width /
                                                4.5,
                                        conditionalValues: [
                                          const Condition.smallerThan(
                                            name: MOBILE,
                                            value: 80.0,
                                          ),
                                          const Condition.largerThan(
                                            name: MOBILE,
                                            value: 100.0,
                                          ),
                                        ],
                                      ).value,
                                      child: Column(
                                        children: [
                                          Bone.circle(size: 55),
                                          SizedBox(height: 8),
                                          Bone.text(width: 60),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return Center(
                                child: Text("No categories available"));
                          } else {
                            List<Category> categoryList = snapshot.data!;
                            return SizedBox(
                              height: MediaQuery.of(context).size.height / 9,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: categoryList.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        CustomCupertinoPageRoute(
                                          builder: (context) => GenderCategory(
                                            categoryId: categoryList[index].id,
                                            categoryName:
                                                categoryList[index].name,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: ResponsiveValue<double>(
                                        context,
                                        defaultValue:
                                            MediaQuery.of(context).size.width /
                                                4.5,
                                        conditionalValues: [
                                          const Condition.smallerThan(
                                            name: MOBILE,
                                            value: 80.0,
                                          ),
                                          const Condition.largerThan(
                                            name: MOBILE,
                                            value: 100.0,
                                          ),
                                        ],
                                      ).value,
                                      child: Column(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            child: Image.network(
                                              categoryList[index].image,
                                              height: ResponsiveValue<double>(
                                                context,
                                                defaultValue: 55.0,
                                                conditionalValues: [
                                                  const Condition.smallerThan(
                                                    name: MOBILE,
                                                    value: 45.0,
                                                  ),
                                                ],
                                              ).value,
                                              width: ResponsiveValue<double>(
                                                context,
                                                defaultValue: 55.0,
                                                conditionalValues: [
                                                  const Condition.smallerThan(
                                                    name: MOBILE,
                                                    value: 45.0,
                                                  ),
                                                ],
                                              ).value,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            categoryList[index].name,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              letterSpacing: -0.05,
                                              fontSize: ResponsiveValue<double>(
                                                context,
                                                defaultValue: 13.5,
                                                conditionalValues: [
                                                  const Condition.smallerThan(
                                                    name: MOBILE,
                                                    value: 11.0,
                                                  ),
                                                ],
                                              ).value,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  _buildProductSection(
                      title: "Featured",
                      productsFuture: allProducts,
                      viewAllRoute: 'featured'),
                  buildTrendingGridSection("Trending Now", _trendingProducts),
                  _buildProductSection(
                      title: "Best Sellers",
                      productsFuture: _bestSellers,
                      viewAllRoute: 'bestsellers'),
                  _buildProductSection(
                      title: "New Arrivals",
                      productsFuture: _newArrivals,
                      viewAllRoute: 'newarrivals'),
                  _buildProductSection(
                      title: "Discount Deals",
                      productsFuture: _discountProducts,
                      viewAllRoute: 'discount'),
                  _buildProductSection(
                      title: "Recommended For You",
                      productsFuture: _recommendedProducts),
                  _buildProductSection(
                      title: "Top Rated", productsFuture: _topRatedProducts),

                  // Widget for product sections

                  // 🛍 Product List (Below Categories)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 5, 12, 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Featured",
                          style: GoogleFonts.poppins(
                              letterSpacing: 0.1,
                              fontSize: 20,
                              fontWeight: FontWeight.w600),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            "View All",
                            style: GoogleFonts.poppins(
                              letterSpacing: 0.01,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Product Grid

            SliverToBoxAdapter(
              child: FutureBuilder<List<Subcategory>>(
                future: allProducts,
                // Use the future stored in the state
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child:
                            SimpleCircularLoader(color: Colors.indigoAccent));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("No products available"));
                  } else {
                    List<Subcategory> productList = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
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
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.all(0),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ResponsiveValue<int>(
                              context,
                              defaultValue: 2,
                              conditionalValues: [
                                const Condition.smallerThan(
                                    name: TABLET, value: 2),
                                const Condition.largerThan(
                                    name: TABLET, value: 3),
                              ],
                            ).value,
                            crossAxisSpacing: 1.5,
                            mainAxisSpacing: 1,
                            childAspectRatio: ResponsiveValue<double>(
                              context,
                              defaultValue: 0.53,
                              conditionalValues: [
                                const Condition.smallerThan(
                                    name: TABLET, value: 0.53),
                              ],
                            ).value,
                          ),
                          itemCount: productList.length,
                          itemBuilder: (context, index) {
                            final product = productList[index];

                            final isInCart = Provider.of<CartProvider>(context)
                                .isProductInCart(product.product_id);
                            final discount =
                                int.tryParse(product.discount) ?? 0;
                            final originalPrice = double.parse(product.price);
                            final discountedPrice =
                                originalPrice * (100 - discount) / 100;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CustomCupertinoPageRoute(
                                    builder: (context) => ItemDetailScreen(
                                      subcategory: productList[index],
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Product image with wishlist icon
                                      Stack(
                                        children: [
                                          Container(
                                            height: 220,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                    _getThumbnailFromProduct(
                                                        productList[index])),
                                                // fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.favorite_border,
                                                  color: Colors.black,
                                                  size: 22,
                                                ),
                                                onPressed: () {},
                                                padding: EdgeInsets.all(8),
                                                constraints: BoxConstraints(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Product details
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              productList[index].name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.manrope(
                                                fontSize:
                                                    ResponsiveValue<double>(
                                                  context,
                                                  defaultValue: 13.0,
                                                  conditionalValues: [
                                                    const Condition.smallerThan(
                                                        name: TABLET,
                                                        value: 13.0),
                                                  ],
                                                ).value,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            // Price section
                                            Row(
                                              children: [
                                                Text(
                                                  '₹${discountedPrice.toStringAsFixed(2)}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize:
                                                        ResponsiveValue<double>(
                                                      context,
                                                      defaultValue: 14.5,
                                                      conditionalValues: [
                                                        const Condition
                                                            .smallerThan(
                                                            name: TABLET,
                                                            value: 14.5),
                                                      ],
                                                    ).value,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(width: 5),
                                                if (discount > 0) ...[
                                                  SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '₹${originalPrice.toStringAsFixed(2)}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 12,
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),

                                            // Free delivery
                                            if (discount > 0) ...[
                                              SizedBox(height: 2),
                                              Row(
                                                children: [
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
                                            SizedBox(height: 4),
                                            // Rating
                                            SizedBox(height: 4),
                                            // Rating
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
                                                            letterSpacing: 0.01,
                                                            fontSize: 13,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                ),
                                                Spacer(),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
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
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect({
    bool isGrid = false,
    int itemCount = 6,
  }) {
    return Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        duration: Duration(milliseconds: 400),
      ),
      child: isGrid
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
                childAspectRatio: 0.75,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) => _buildShimmerCard(),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: itemCount,
              itemBuilder: (context, index) => _buildShimmerCard(),
            ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      width: ResponsiveValue<double>(
        context,
        defaultValue: MediaQuery.of(context).size.width / 2.6,
        conditionalValues: [
          const Condition.smallerThan(name: TABLET, value: 150.0),
        ],
      ).value,
      child: Card(
        surfaceTintColor: Colors.grey[100],
        color: Colors.grey[50],
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: ResponsiveValue<double>(
                context,
                defaultValue: MediaQuery.of(context).size.height / 6,
                conditionalValues: [
                  const Condition.smallerThan(name: TABLET, value: 120.0),
                ],
              ).value,
              width: double.infinity,
              color: Colors.grey[200],
            ),
            // Text placeholders
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.grey[200],
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 20,
                    color: Colors.grey[200],
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 14,
                    color: Colors.grey[200],
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

class AppInitializer {
  static bool _fcmTokenSent = false;

  static Future<void> sendFCMTokenOnce(BuildContext context) async {
    if (_fcmTokenSent) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    String? fcmToken = FirebaseApi.fcmToken;

    // Ensure we have all required data
    if (fcmToken == null) {
      debugPrint("⚠️ FCM token not available");
      return;
    }

    final userId = cartProvider.email ?? cartProvider.useremail;
    if (userId == null || userId.isEmpty) {
      debugPrint("⚠️ User email not available");
      return;
    }

    try {
      await ApiService.sendFCMNotification(
        deviceToken: fcmToken,
        userId: userId,
        // Optional: Add default title and message if needed
        // title: 'App Launched',
        // main: 'User opened the app',
      );
      _fcmTokenSent = true;
      debugPrint("✅ FCM token sent to backend");
    } catch (e) {
      debugPrint("❌ Error sending FCM token: $e");
      // Reset flag to try again next time
      _fcmTokenSent = false;
    }
  }
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.grey[50],
      child: child,
    );
  }

  @override
  double get maxExtent => 65; // Increased from 60 to 80

  @override
  double get minExtent => 65; // Same as maxExtent for fixed height

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
