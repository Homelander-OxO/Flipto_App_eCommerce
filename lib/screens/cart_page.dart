import 'dart:convert';
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/cart_items.dart';
import 'package:flutter_app/models/e-category_model.dart';
import 'package:flutter_app/models/e-subcategory_model.dart';
import 'package:flutter_app/screens/add_address.dart';
import 'package:flutter_app/screens/checkout.dart';
import 'package:flutter_app/screens/product_screen.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/ai.dart';
import 'package:flutter_app/screens/search_screen.dart';
import 'package:flutter_app/screens/favourite.dart';
import 'package:flutter_app/screens/home_page.dart';
import 'package:flutter_app/Utilities/bottom_navigation.dart';
import 'package:flutter_app/custom_widgets/cart_badge.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/custom_widgets/progress_indicator.dart';
import 'package:flutter_app/Authentication/login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:countup/countup.dart';

String cleanUrl(String url) {
  url = url.replaceAll(r'\/', '/');
  url = url.replaceAll('Apis./', 'Apis/');
  url = url.replaceAll(
      '//192.', '/192.'); // in case triple slash issue creeps back
  if (url.startsWith('http:/') && !url.startsWith('http://')) {
    return url.replaceFirst('http:/', 'http://');
  } else if (!url.startsWith('http')) {
    return 'http://$url';
  }
  return url;
}

class CartScreen extends StatefulWidget {
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  List<Subcategory> subcategoryList = [];
  bool _isLoading = true;
  bool _isCheckingAddress = false;
  late TabController _tabController;
  int _currentTabIndex = 0;
  late RecommendationService recommendationService;

  @override
  void initState() {
    super.initState();
    _loadCartData();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    recommendationService = RecommendationService();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userId = cartProvider.email ?? cartProvider.useremail ?? '';
    recommendationService.init(userId);
  }

  Future<void> _loadCartData() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final userId = cartProvider.email ?? cartProvider.useremail ?? '';

    if (userId.isNotEmpty) {
      await fetchAllCategories();
      await fetchCartItems(userId);

      // Get all product IDs from cart
      final productIds = cartProvider.cartItems1
          .map((item) => item.productId)
          .where((id) => id != null && id.isNotEmpty)
          .toList();

      // Load ratings for all products in cart
      await cartProvider.loadProductRatings(productIds);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchAllCategories() async {
    try {
      List<Category> categories = await ApiService.fetchCategories();
      for (var category in categories) {
        await fetchSubcategories(category.id);
      }
    } catch (e) {
      print('🚨 Error fetching categories: $e');
    }
  }

  Future<void> fetchSubcategories(String categoryId) async {
    try {
      List<Subcategory> fetchedSubcategories =
          await ApiService.fetchSubcategories(categoryId);

      // Only add new subcategories that don't already exist
      for (var subcategory in fetchedSubcategories) {
        if (!subcategoryList
            .any((item) => item.product_id == subcategory.product_id)) {
          subcategoryList.add(subcategory);
        }
      }
    } catch (e) {
      print('🚨 Error fetching subcategories: $e');
    }
  }

  Future<void> fetchCartItems(String userId) async {
    try {
      List<CartItem> fetchedItems = await ApiService().searchCart(userId);

      // First fetch all products if not already done
      if (subcategoryList.isEmpty) {
        await fetchAllCategories();
      }

      List<Subcategory> combinedItems = [];

      for (var cartItem in fetchedItems) {
        try {
          // Try to find matching product in subcategoryList
          var product = subcategoryList.firstWhere(
            (product) => product.product_id == cartItem.productId,
            orElse: () => Subcategory(
              id: '',
              product_id: cartItem.productId,
              name: cartItem.name ?? 'Unknown Product',
              type: '',
              gender: '',
              description: '',
              price: cartItem.price,
              discount: '0',
              image: jsonEncode({'main': [], 'colors': {}}),
              productDetails: ProductDetails.fromJson(
                {'main': [], 'colors': {}},
                cartItem.size ?? '',
              ),
            ),
          );

          // Create a new Subcategory with cart-specific details
          combinedItems.add(Subcategory(
            id: product.id,
            product_id: product.product_id,
            name: product.name.isNotEmpty
                ? product.name
                : cartItem.name ?? 'Unknown Product',
            type: product.type,
            gender: product.gender,
            description: product.description,
            price: cartItem.price,
            discount: product.discount,
            image: product.image,
            size: cartItem.size,
            color: cartItem.color,
            productDetails: product.productDetails,
          ));
        } catch (e) {
          print('🚨 Error processing cart item ${cartItem.productId}: $e');
        }
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.cartItems1.clear();
      cartProvider.cartItems1.addAll(fetchedItems);
      cartProvider.cartItems.clear();
      cartProvider.cartItems.addAll(combinedItems);
      cartProvider.notifyListeners();
    } catch (e) {
      print('🚨 Error fetching cart: $e');
    }
  }

  String _getProductThumbnail(dynamic imageData) {
    if (imageData == null) return '';
    if (imageData is String && imageData.startsWith('http')) {
      return imageData.replaceAll(r'\/', '/').replaceAll('Apis./', 'Apis/');
    }
    if (imageData is String) {
      try {
        final parsed = jsonDecode(imageData);
        if (parsed['main'] is List && parsed['main'].isNotEmpty) {
          return parsed['main'][0]
              .toString()
              .replaceAll(r'\/', '/')
              .replaceAll('Apis./', 'Apis/');
        }
      } catch (e) {
        print('Error parsing image JSON: $e');
      }
    }
    if (imageData is Map &&
        imageData['main'] is List &&
        imageData['main'].isNotEmpty) {
      return imageData['main'][0]
          .toString()
          .replaceAll(r'\/', '/')
          .replaceAll('Apis./', 'Apis/');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final user = cartProvider.userDetails;
    final guser = cartProvider.googleProfile;

    // Filter items based on category
    final groceryItems =
        cartProvider.cartItems.where((item) => item.id == "3").toList();
    final nonGroceryItems =
        cartProvider.cartItems.where((item) => item.id != "3").toList();

    final groceryCartItems = cartProvider.cartItems1.where((item) {
      final product = cartProvider.cartItems.firstWhere(
        (p) => p.product_id == item.productId,
        orElse: () => Subcategory(
          id: '',
          product_id: '',
          name: '',
          type: '',
          gender: '',
          description: '',
          price: '',
          discount: '',
          image: '',
          productDetails:
              ProductDetails(mainImages: [], colorImages: {}, sizes: []),
        ),
      );
      return product.id == "3";
    }).toList();

    final nonGroceryCartItems = cartProvider.cartItems1.where((item) {
      final product = cartProvider.cartItems.firstWhere(
        (p) => p.product_id == item.productId,
        orElse: () => Subcategory(
          id: '',
          product_id: '',
          name: '',
          type: '',
          gender: '',
          description: '',
          price: '',
          discount: '',
          image: '',
          productDetails:
              ProductDetails(mainImages: [], colorImages: {}, sizes: []),
        ),
      );
      return product.id != "3";
    }).toList();

    // Filter cart items by tab type
    final regularItems =
        cartProvider.cartItems.where((item) => item.id != "3").toList();
    final groceryItems1 =
        cartProvider.cartItems.where((item) => item.id == "3").toList();

    // Determine current tab's items
    final currentItems = _currentTabIndex == 0 ? regularItems : groceryItems1;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 40,
        title: Text(
          'My Cart',
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 20,
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
            icon: ImageIcon(
              AssetImage('assets/images/heart.png'),
              size: 28,
            ),
            // Reduced
            onPressed: () {
              Navigator.push(
                  context,
                  CustomCupertinoPageRoute(
                      builder: (context) => FavoriteScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildShimmerEffect()
          : cartProvider.cartItems1.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/images/Animation - 1743674816462.json',
                        width: 250,
                        height: 250,
                        fit: BoxFit.contain,
                        frameRate: FrameRate.max,
                      ),
                      Text(
                        'Your Cart is Empty',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Looks like you haven\'t added anything to your cart yet',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff101d42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Navigation()),
                            (route) => false,
                          );
                        },
                        child: Text(
                          'Continue Shopping',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    CheckoutProgress(currentStep: 1),
                    // CheckoutProgressIndicator(currentStep: 1),
                    TabBar(
                      physics: NeverScrollableScrollPhysics(),
                      onTap: (index) {
                        setState(() {
                          _currentTabIndex = index;
                        });
                      },
                      controller: _tabController,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xff101d42),
                      labelStyle:
                          GoogleFonts.manrope(fontWeight: FontWeight.w700),
                      tabs: [
                        Tab(
                          text: nonGroceryItems.isNotEmpty
                              ? 'Flipto (${nonGroceryItems.length})'
                              : 'Flipto',
                        ),
                        Tab(
                          text: groceryItems.isNotEmpty
                              ? 'Grocery (${groceryItems.length})'
                              : 'Grocery',
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        controller: _tabController,
                        children: [
                          // Regular Items Tab
                          _buildItemsList(nonGroceryItems, nonGroceryCartItems),
                          // Grocery Items Tab
                          _buildItemsList(groceryItems, groceryCartItems),
                        ],
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _isLoading || cartProvider.cartItems1.isEmpty
          ? null
          : Builder(
              builder: (context) {
                final items =
                    _currentTabIndex == 0 ? nonGroceryItems : groceryItems;
                final cartItems = _currentTabIndex == 0
                    ? nonGroceryCartItems
                    : groceryCartItems;
                if (items.isEmpty || cartItems.isEmpty)
                  return SizedBox.shrink();

                double itemTotal = 0;
                double totalDiscount = 0;
                double originalTotal = 0;

                for (int i = 0; i < items.length; i++) {
                  final item = items[i];
                  final cartData = cartItems
                      .firstWhere((c) => c.productId == item.product_id);
                  final price = double.tryParse(item.price) ?? 0.0;
                  final discount = int.tryParse(item.discount) ?? 0;
                  final quantity = int.tryParse(cartData.quantity) ?? 1;

                  originalTotal += price * quantity;
                  final discountedPrice = price * (100 - discount) / 100;
                  itemTotal += discountedPrice * quantity;
                  totalDiscount += (price - discountedPrice) * quantity;
                }

                final deliveryCharge = itemTotal >= 500 ? 0 : 40;
                final totalAmount = itemTotal + deliveryCharge;

                return Container(
                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: Offset(0, -3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff101d42),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (_isCheckingAddress) return;
                      setState(() => _isCheckingAddress = true);

                      final userEmail =
                          cartProvider.email ?? cartProvider.useremail;
                      if (userEmail == null || userEmail.isEmpty) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    Login(email: '', username: '')));
                        setState(() => _isCheckingAddress = false);
                        return;
                      }

                      try {
                        await cartProvider.fetchAddresses(userEmail);
                        if (cartProvider.addresses.isEmpty) {
                          final addressAdded = await Navigator.push(
                            context,
                            CustomCupertinoPageRoute(
                              builder: (context) => ShippingDetailsScreen(
                                name: cartProvider.userDetails?.fullName ?? '',
                                contact: '',
                                street: '',
                                area: '',
                                apartmentNumber: '',
                                city: '',
                                postcode: '',
                                isEditing: false,
                              ),
                            ),
                          );

                          if (addressAdded == true) {
                            Navigator.push(
                              context,
                              CustomCupertinoPageRoute(
                                builder: (context) => SetAddressScreen(
                                  email: userEmail,
                                  cartItems: items,
                                  cartItems1: cartItems,
                                  totalAmount: totalAmount,
                                ),
                              ),
                            );
                          }
                        } else {
                          Navigator.push(
                            context,
                            CustomCupertinoPageRoute(
                              builder: (context) => SetAddressScreen(
                                email: userEmail,
                                cartItems: items,
                                cartItems1: cartItems,
                                totalAmount: totalAmount,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error checking addresses: $e')),
                        );
                      } finally {
                        setState(() => _isCheckingAddress = false);
                      }
                    },
                    child: _isCheckingAddress
                        ? SizedBox(
                            width: 21,
                            height: 21,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 1.8,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Checkout',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 6),
                              Countup(
                                begin: 0,
                                end: totalAmount,
                                duration: const Duration(milliseconds: 200),
                                separator: ',',
                                prefix: '₹',
                                suffix: '.00',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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

  Widget _buildCartItem(Subcategory item, CartItem cartData) {
    final cartProvider = Provider.of<CartProvider>(context);

    final selectedColor = item.color?.trim().toLowerCase();
    final colorImages = item.productDetails.colorImages.map(
      (k, v) => MapEntry(k.toLowerCase(), v),
    );
    final hasValidColor =
        cartData.color != null && cartData.color!.trim().isNotEmpty;
    final hasValidSize =
        cartData.size != null && cartData.size!.trim().isNotEmpty;

    final price = double.tryParse(item.price) ?? 0.0;
    final discount = int.tryParse(item.discount) ?? 0;
    final discountedPrice = price * (100 - discount) / 100;

    String imageUrl = '';
    if (selectedColor != null &&
        selectedColor.isNotEmpty &&
        colorImages.containsKey(selectedColor)) {
      imageUrl = colorImages[selectedColor]!;
    } else if (item.productDetails.mainImages.isNotEmpty) {
      imageUrl = item.productDetails.mainImages.first;
    }

    imageUrl = cleanUrl(imageUrl);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
      child: GestureDetector(
        onTap: () => _navigateToProduct(item),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // ✅ Product Image Section
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(5),
                        width: 80,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[50],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageUrl.isEmpty
                              ? Center(
                                  child: Icon(
                                    Icons.shopping_bag,
                                    color: Colors.grey[400],
                                    size: 22,
                                  ),
                                )
                              : Image.network(
                                  imageUrl,
                                  // fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('❌ Failed to load image: $imageUrl');
                                    return Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey[400],
                                        size: 22,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),

                  // Product Details (Compact)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8, 4, 10, 0),
                      child: Column(
                        spacing: 6,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, _) {
                              final rating = cartProvider
                                  .getRatingForProduct(item.product_id);
                              final count = cartProvider
                                  .getRatingCountForProduct(item.product_id);
                              return Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.green[500],
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.white, size: 11),
                                        SizedBox(width: 1),
                                        Text(
                                          rating.toStringAsFixed(1),
                                          style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: -0.2

                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 4),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '₹${discountedPrice}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2
                                    ),
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  if (discount > 0)
                                    Text(
                                      '₹${price}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey,
                                          letterSpacing: -0.2

                                      ),
                                    ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Decrease Button
                                  Material(
                                    borderRadius: BorderRadius.circular(5),
                                    clipBehavior: Clip.hardEdge,
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(5),
                                      onTap: () async {
                                        try {
                                          final cartItemIndex = cartProvider
                                              .cartItems1
                                              .indexWhere(
                                            (cartItem) =>
                                                cartItem.productId ==
                                                item.product_id,
                                          );
                                          if (cartItemIndex == -1) return;

                                          final cartItem = cartProvider
                                              .cartItems1[cartItemIndex];
                                          int currentQuantity =
                                              int.tryParse(cartItem.quantity) ??
                                                  0;

                                          if (currentQuantity > 1) {
                                            int newQuantity =
                                                currentQuantity - 1;
                                            cartProvider.updateQuantity(
                                                item.product_id, newQuantity);
                                            await ApiService.updateCart(
                                              cartItem.cartId,
                                              item.product_id,
                                              newQuantity,
                                              item.price.toString(),
                                            );
                                          } else {
                                            await ApiService.removeCart(
                                                cartItem.cartId);
                                            cartProvider.cartItems1
                                                .removeAt(cartItemIndex);
                                            cartProvider.cartItems.removeWhere(
                                                (product) =>
                                                    product.product_id ==
                                                    cartItem.productId);
                                            cartProvider.notifyListeners();
                                          }
                                        } catch (e) {
                                          print('🚨 Error: $e');
                                        }
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 15,
                                          color: Color(0xFF101D42),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Quantity Display with Animation
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: AnimatedFlipCounter(
                                      value: int.tryParse(cartProvider
                                                  .cartItems1
                                                  .firstWhere((e) =>
                                                      e.productId ==
                                                      item.product_id)
                                                  .quantity ??
                                              '0') ??
                                          0,
                                      textStyle: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                      fractionDigits: 0,
                                      thousandSeparator: '',
                                    ),
                                  ),

                                  // Increase Button
                                  Material(
                                    borderRadius: BorderRadius.circular(5),
                                    clipBehavior: Clip.hardEdge,
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(5),
                                      onTap: () async {
                                        int currentQuantity = int.tryParse(
                                                cartProvider.cartItems1
                                                    .firstWhere((cartItem) =>
                                                        cartItem.productId ==
                                                        item.product_id)
                                                    .quantity) ??
                                            0;
                                        int newQuantity = currentQuantity + 1;
                                        cartProvider.updateQuantity(
                                            item.product_id, newQuantity);
                                        await ApiService.updateCart(
                                          cartProvider.cartItems1
                                              .firstWhere((cartItem) =>
                                                  cartItem.productId ==
                                                  item.product_id)
                                              .cartId,
                                          item.product_id,
                                          newQuantity,
                                          item.price.toString(),
                                        );
                                      },
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          color: Color(0xFF101D42),
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (hasValidColor || hasValidSize)
                                Text(
                                  '${hasValidColor ? 'Color: ${cartData.color!.trim()}' : 'Color: Original | '}'
                                  '${(hasValidColor && hasValidSize) ? ' | ' : ''}'
                                  '${hasValidSize ? 'Size: ${cartData.size!.trim()}' : ''}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: Colors.grey[700],
                                    letterSpacing: 0.1
                                  ),
                                )
                              else
                                SizedBox(),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.0015,
              ),
              Divider(
                color: Colors.grey[300],
                height: 1,
                thickness: 0.8,
                indent: 10,
                endIndent: 10,
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Add to Wishlist Button
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(
                          Icons.favorite_border_rounded,
                          size: 18,
                          color: Colors.grey[700],
                        ),
                        label: Text(
                          'Save for Later',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          // Wishlist functionality
                        },
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.grey[300],
                    ),

                    // Remove Button
                    Expanded(
                      child: TextButton.icon(
                        icon: Icon(
                          CupertinoIcons.delete,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: Text(
                          'Remove',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          final userId = cartProvider.email ??
                              cartProvider.useremail ??
                              '';
                          if (userId.isNotEmpty) {
                            await ApiService.removeCart(
                              cartProvider.cartItems1
                                  .firstWhere((cartItem) =>
                                      cartItem.productId == item.product_id)
                                  .cartId,
                            );
                            await fetchCartItems(userId);
                          }
                        },
                      ),
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

  Widget _buildItemsList(List<Subcategory> items, List<CartItem> cartItems) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/emptyb.png',
              scale: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Your Basket is empty',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return _buildPriceSummary(items, cartItems);
        }

        final item = items[index];
        final cartData = cartItems.firstWhere(
          (cartItem) => cartItem.productId == item.product_id,
          orElse: () => CartItem(
            cartId: '',
            userId: '',
            productId: '',
            quantity: '1',
            price: item.price,
            totalPrice: item.price,
            addedAt: '',
            updatedAt: '',
            name: item.name,
            image: ProductDetails.fromJson(
                {'main': [], 'colors': {}}, item.size ?? ''),
            color: item.color,
            size: item.size,
          ),
        );

        return _buildCartItem(item, cartData);
      },
    );
  }

  Widget _buildPriceSummary(List<Subcategory> items, List<CartItem> cartItems) {
    double itemTotal = 0;
    double originalTotal = 0;
    double totalDiscount = 0;
    int totalQuantity = 0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final cartData =
          cartItems.firstWhere((c) => c.productId == item.product_id);
      final price = double.tryParse(item.price) ?? 0.0;
      final discount = int.tryParse(item.discount) ?? 0;
      final quantity = int.tryParse(cartData.quantity) ?? 1;

      totalQuantity += quantity;
      originalTotal += price * quantity;

      final discountedPrice = price * (100 - discount) / 100;
      itemTotal += discountedPrice * quantity;
      totalDiscount += (price - discountedPrice) * quantity;
    }

    final deliveryCharge = itemTotal >= 500 ? 0 : 40;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Details',
              style: GoogleFonts.manrope(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          SizedBox(height: 10),
          _buildPriceRow('Item Price ($totalQuantity items)',
              '₹${originalTotal.toStringAsFixed(1)}'),
          _buildPriceRow('Discount', '- ₹${totalDiscount.toStringAsFixed(1)}',
              isDiscount: true),
          _buildPriceRow('Item Total', '₹${itemTotal.toStringAsFixed(1)}'),
          _buildPriceRow(
            'Delivery Charges',
            deliveryCharge == 0 ? 'Free' : '₹$deliveryCharge',
            isDelivery: true,
            isFreeDelivery: deliveryCharge == 0,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.022,
            child: Center(
              child: CustomPaint(
                painter: _DashedLinePainter(),
                size: Size(double.infinity, 1),
              ),
            ),
          ),
          _buildPriceRow('Total Amount',
              '₹${(itemTotal + deliveryCharge).toStringAsFixed(2)}',
              isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isDelivery = false,
    bool isFreeDelivery = false,
    bool isDiscount = false, // Added new parameter for discount
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: isTotal ? 15.5 : 14.5,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? Colors.grey[900] : Colors.grey[700],
              letterSpacing: -0.1,
            ),
          ),
          // Text(
          //     value, // This will be "Free"
          //     style: GoogleFonts.manrope(
          //       fontSize: 14,
          //       color: Colors.green,
          //       fontWeight: FontWeight.w500,
          //     ),),
          if (isDelivery && isFreeDelivery)
            Row(
              children: [
                Text(
                  '₹40',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                    letterSpacing: -0.5
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.012),
                value.startsWith('₹')
                    ? Countup(
                        begin: 0,
                        end: double.tryParse(value.replaceAll('₹', '')) ?? 0.0,
                        duration: const Duration(milliseconds: 200),
                        separator: ',',
                        prefix: '₹',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              isTotal ? FontWeight.w600 : FontWeight.w500,
                          color: isTotal ? Colors.black : Colors.grey[600],
                        ),
                      )
                    : Text(
                        value, // This will be "Free"
                        style: GoogleFonts.manrope(
                          fontSize: 14.5,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1
                        ),
                      ),
              ],
            )
          else
            value.startsWith('₹')
                ? Countup(
                    begin: 0,
                    end: double.tryParse(value.replaceAll('₹', '')) ?? 0.0,
                    duration: const Duration(milliseconds: 300),
                    separator: ',',
                    prefix: '₹',
                    suffix: isTotal ? '.00' : '',
                    style: GoogleFonts.inter(
                      fontSize: isTotal ? 16 : 14,
                      fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                      color: isTotal ? Colors.black : Colors.grey[600],
                      letterSpacing: -0.2
                    ),
                  )
                : isDiscount
                    ? Countup(
                        begin: 0,
                        end: double.tryParse(
                                value.replaceAll(RegExp(r'[^\d.]'), '')) ??
                            0,
                        duration: const Duration(milliseconds: 300),
                        separator: ',',
                        prefix: '₹',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2
                        ),
                      )
                    : Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: isTotal ? 16 : 14,
                          color: isDiscount
                              ? Colors.green
                              : (isTotal ? Colors.black : Colors.grey[800]),
                          fontWeight:
                              isTotal ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(29, 2, 38, 20),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: Colors
                        .transparent, // Placeholder for progress indicator
                  ),
                  Row(
                    // spacing: 30,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        List.generate(3, (index) => Bone.circle(size: 26)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Bone.square(size: 100, uniRadius: 12),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone.text(width: double.infinity),
                            SizedBox(height: 8),
                            Bone.text(width: 80),
                            SizedBox(height: 12),
                            Bone.text(
                              width: 120,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(width: double.infinity),
                  SizedBox(height: 16),
                  Bone.text(width: double.infinity),
                  SizedBox(height: 8),
                  Bone.text(width: double.infinity),
                  SizedBox(height: 8),
                  Bone.text(width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProduct(Subcategory item) async {
    // await recommendationService.trackUserAction(item.product_id, 'view');
    // print(recommendationService.trackUserAction(item.product_id, 'view'));
    Navigator.push(
      context,
      CustomCupertinoPageRoute(
        builder: (context) => ItemDetailScreen(
          subcategory: item.copyWith(
            // Preserve the selected size but keep all size options in productDetails
            size: item.size, // keeps the selected size
            // Ensure image data is properly passed
            image: item.image.isNotEmpty
                ? item.image
                : jsonEncode({
                    'main': item.productDetails.mainImages,
                    'colors': item.productDetails.colorImages,
                  }),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    const dashWidth = 5;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
