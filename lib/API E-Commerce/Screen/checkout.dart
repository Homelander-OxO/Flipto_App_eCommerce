import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/API%20E-Commerce/Model/cart_items.dart';
import 'package:flutter_app/API%20E-Commerce/Model/e-subcategory_model.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/add_address.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/payment_screen.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/custom_widgets/gradient_button.dart';
import 'package:flutter_app/custom_widgets/progress_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

String cleanUrl(String url) {
  url = url.replaceAll(r'\/', '/').replaceAll('Apis./', 'Apis/');
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  } else if (url.startsWith('http:/')) {
    return url.replaceFirst('http:/', 'http://');
  } else {
    return 'http://$url';
  }
}

class SetAddressScreen extends StatefulWidget {
  final String email;
  final List<Subcategory> cartItems;
  final List<CartItem> cartItems1;
  final double totalAmount; // Add this parameter

  const SetAddressScreen({
    Key? key,
    required this.email,
    required this.cartItems,
    required this.cartItems1,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _SetAddressScreenState createState() => _SetAddressScreenState();
}

class _SetAddressScreenState extends State<SetAddressScreen> {
  List<Subcategory> subcategoryList = [];
  int? _selectedAddressIndex;
  bool _isLoading = true;
  bool _showDotAnimation = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _preprocessCartItems();
    for (var item in widget.cartItems) {
      print('Cart Item: ${item.name}');
      print('- Image: ${item.image}');
      print('- ProductDetails mainImages: ${item.productDetails.mainImages}');
    }
  }

  void _preprocessCartItems() {
    for (int i = 0; i < widget.cartItems.length; i++) {
      // Try to ensure we have valid image data for each cart item
      final item = widget.cartItems[i];

      // If the productDetails.mainImages is empty, try to extract from raw image string
      if (item.productDetails.mainImages.isEmpty && item.image.isNotEmpty) {
        try {
          // Simple check if it could be JSON
          if (item.image.contains('{') && item.image.contains('}')) {
            var processed = _getProductThumbnail(item.image);
            if (processed.isNotEmpty) {
              print('Found image URL: $processed for ${item.name}');
              // This is just for logging - we'll use this logic in _buildProductImage
            }
          }
        } catch (e) {
          print('Error preprocessing image: $e');
        }
      }
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

  Future<void> _loadAddresses() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await cartProvider.fetchAddresses(widget.email);
    setState(() {
      // Automatically select first address if available
      _selectedAddressIndex = cartProvider.addresses.isNotEmpty ? 0 : null;
      _isLoading = false;
    });
  }

  void _navigateToAddAddress({bool isEditing = false, int? index}) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final result = await Navigator.push(
      context,
      CustomCupertinoPageRoute(
        builder: (context) {
          if (isEditing &&
              index != null &&
              cartProvider.addresses.length > index) {
            final address = cartProvider.addresses[index];
            return ShippingDetailsScreen(
              name: cartProvider.userDetails?.fullName ?? '',
              contact: address.contact,
              street: address.street,
              area: address.area,
              apartmentNumber: address.apartmentNo,
              city: address.city,
              postcode: address.pincode,
              index: index,
              isEditing: true,
            );
          } else {
            return const ShippingDetailsScreen(
              name: '',
              contact: '',
              street: '',
              area: '',
              apartmentNumber: '',
              city: '',
              postcode: '',
              isEditing: false,
            );
          }
        },
      ),
    );

    if (result == true) {
      await _loadAddresses();
    }
  }

  void _selectAddress(int index) {
    setState(() {
      _selectedAddressIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Checkout',
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildShimmerEffect()
          : Column(
              children: [
                // Progress indicator
                CheckoutProgress(currentStep: 2, previousStep: 1),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Address Section
                        _buildAddressSection(cartProvider),

                        // Order Summary
                        _buildOrderSummarySection(cartProvider),

                        // Price Details
                        _buildPriceDetailsSection(cartProvider),

                        SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // Proceed to Pay Button
      bottomSheet: _buildBottomButton(cartProvider),
    );
  }

  Widget _buildAddressSection(CartProvider cartProvider) {
    return Container(
      margin: EdgeInsets.all(12), // Reduced margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6, // Reduced blur
            offset: Offset(0, 2), // Smaller offset
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 5, 12, 0), // Reduced padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Delivery Address',
                  style: GoogleFonts.manrope(
                    fontSize: 15, // Slightly smaller font
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToAddAddress(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, // Remove default padding
                    minimumSize: Size.zero, // Remove minimum size constraints
                  ),
                  child: Text(
                    '+ Add New',
                    style: GoogleFonts.manrope(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13, // Smaller font
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.blue[700],
                  strokeWidth: 2,
                ),
              ),
            )
          else if (cartProvider.addresses.isEmpty)
            _buildEmptyAddressState()
          else
            _buildCompactAddressCard(
              address: cartProvider.addresses[_selectedAddressIndex ?? 0],
              index: _selectedAddressIndex ?? 0,
            ),
        ],
      ),
    );
  }

  Widget _buildCompactAddressCard({
    required dynamic address,
    required int index,
  }) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 0), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  color: Colors.blue[700], size: 18), // Smaller icon
              SizedBox(width: 6), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cartProvider.userDetails?.fullName ??
                          cartProvider.googleProfile?.name ??
                          'NA',
                      style: GoogleFonts.manrope(
                        fontSize: 14, // Smaller font
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2), // Reduced spacing
                    Text(
                      address.contact,
                      style: GoogleFonts.manrope(
                        fontSize: 12, // Smaller font
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, size: 20),
                onPressed: () => _showAddressBottomSheet(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: 6), // Reduced spacing
          Text(
            "${address.apartmentNo}, ${address.street}, ${address.area},",
            style: GoogleFonts.manrope(fontSize: 12), // Smaller font
          ),
          Text(
            " ${address.city} - ${address.pincode}",
            style: GoogleFonts.manrope(fontSize: 12), // Smaller font
          ),

          Row(
            children: [
              TextButton(
                onPressed: () =>
                    _navigateToAddAddress(isEditing: true, index: index),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Edit',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
              SizedBox(width: 8),
              TextButton(
                onPressed: () => _showAddressBottomSheet(),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Change',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection(CartProvider cartProvider) {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 5),
            child: Text(
              'Order Summary',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildModernOrderItemsList(cartProvider),
        ],
      ),
    );
  }

  Widget _buildModernOrderItemsList(CartProvider cartProvider) {
    // Determine which list is active and cast it properly
    final activeCartItems =
        widget.cartItems.isNotEmpty ? widget.cartItems : widget.cartItems1;
    final isSubcategoryList = widget.cartItems.isNotEmpty;
    final itemCount = activeCartItems.length;

    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: Colors.grey[100]),
      itemBuilder: (context, index) {
        // Handle Subcategory items
        final item = widget.cartItems[index] as Subcategory;
        final discount = int.tryParse(item.discount) ?? 0;
        final originalPrice = double.parse(item.price);
        final discountedPrice = originalPrice * (100 - discount) / 100;

        return Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildProductImage(item),
                ),
              ),
              SizedBox(width: 12),
              // Rest of your Subcategory item UI
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '₹${discountedPrice.toStringAsFixed(1)}',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600, letterSpacing: -0.5),
                        ),
                        SizedBox(width: 8),
                        if (discount > 0)
                          Text(
                            '₹${originalPrice.toStringAsFixed(1)}',
                            style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.lineThrough,
                                letterSpacing: -0.5),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Qty: ${widget.cartItems1.isNotEmpty ? widget.cartItems1[index].quantity : 1}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductImage(Subcategory item) {
    String imageUrl = '';

    try {
      final selectedColor = item.color?.toLowerCase().trim();
      final colorImages = item.productDetails.colorImages.map(
        (k, v) => MapEntry(k.toLowerCase(), v),
      );

      // ✅ Step 1: Try to get color-specific image
      if (selectedColor != null &&
          selectedColor.isNotEmpty &&
          colorImages.containsKey(selectedColor)) {
        imageUrl = colorImages[selectedColor]!;
      }

      // ✅ Step 2: Fallback to main image
      if (imageUrl.isEmpty && item.productDetails.mainImages.isNotEmpty) {
        imageUrl = item.productDetails.mainImages.first;
      }

      // ✅ Step 3: Fallback to parsed legacy image string
      if (imageUrl.isEmpty && item.image.isNotEmpty) {
        if (item.image.contains('{') && item.image.contains('}')) {
          final imageData = jsonDecode(item.image.replaceAll(r'\"', '"'))
              as Map<String, dynamic>;
          if (imageData['main'] is List && imageData['main'].isNotEmpty) {
            imageUrl = imageData['main'][0]
                .toString()
                .replaceAll(r'\/', '/')
                .replaceAll('Apis./', 'Apis/');
          }
        } else if (item.image.startsWith('http')) {
          imageUrl = item.image;
        }
      }

      // ✅ Clean up malformed URL
      imageUrl = cleanUrl(imageUrl);
    } catch (e) {
      print('❌ Error in _buildProductImage: $e');
    }

    // ✅ Return image or fallback icon
    return imageUrl.isEmpty
        ? Center(
            child: Icon(Icons.shopping_bag, color: Colors.grey[400], size: 22),
          )
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            height: 60,
            width: 60,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Image load error: $error for URL: $imageUrl');
              return Center(
                child:
                    Icon(Icons.broken_image, color: Colors.grey[400], size: 22),
              );
            },
          );
  }

  Widget _buildPriceDetailsSection(CartProvider cartProvider) {
    // Use the passed totalAmount instead of calculating it
    final subtotal = widget.totalAmount - (widget.totalAmount >= 500 ? 0 : 40);
    final deliveryCharge = widget.totalAmount >= 500 ? 0 : 40;
    final total = widget.totalAmount; // Use the passed total directly

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Details',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.015),
            _buildPriceRow('Subtotal', '₹${subtotal.toStringAsFixed(1)}'),
            SizedBox(height: 8),
            _buildPriceRow(
              'Delivery Charges',
              deliveryCharge == 0 ? 'Free Delivery' : '₹$deliveryCharge',
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
            _buildPriceRow(
              'Total Amount',
              '₹${total.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
    bool isDelivery = false,
    bool isFreeDelivery = false,
  }) {
    return Row(
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
        if (isDelivery && isFreeDelivery)
          Text(
            value, // This will be "Free"
            style: GoogleFonts.manrope(
              fontSize: 14.5,
              color: Colors.green,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1
            ),
          )
        else
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ?? (isTotal ? Colors.black : Colors.grey[800]),
              letterSpacing: -0.2
            ),
          ),
      ],
    );
  }

  Widget _buildBottomButton(CartProvider cartProvider) {
    // Automatically use first address if available
    final hasAddress = cartProvider.addresses.isNotEmpty;
    final selectedAddress =
        hasAddress ? cartProvider.addresses[_selectedAddressIndex ?? 0] : null;
    final subtotal = widget.totalAmount - (widget.totalAmount >= 500 ? 0 : 40);
    final deliveryCharge = widget.totalAmount >= 500 ? 0 : 40;
    final total = widget.totalAmount; // Use the passed total directly
// Infer cartType based on first cart item’s category_id
    final cartType =
        widget.cartItems.isNotEmpty && widget.cartItems.first.id == "3"
            ? 'grocery'
            : 'regular';
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12, // Reduced from 16
            offset: Offset(0, -3), // Reduced
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: hasAddress
              ? () {
                  Navigator.push(
                    context,
                    CustomCupertinoPageRoute(
                      builder: (context) => RazorPay(
                        amount: total,
                        cartType: cartType,
                        cartProvider: cartProvider,
                        selectedAddress: selectedAddress!,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: hasAddress ? Color(0xff101d42) : Colors.grey[400],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            'Proceed to Payment',
            style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, letterSpacing: -0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAddressState() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No addresses saved yet',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _navigateToAddAddress(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff101d42),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Add New Address',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressBottomSheet() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final addressCount = cartProvider.addresses.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Calculate dynamic height based on number of addresses
        final double baseHeight = 220.0; // Height for header + button
        final double addressItemHeight = 155.0; // Height per address item
        final double maxHeight = MediaQuery.of(context).size.height * 0.81;

        // Calculate ideal height (show 1.5 items if only 1 exists, 2.5 if more)
        // double idealHeight = baseHeight + (addressItemHeight * addressCount);

        // Don't exceed max height or screen height
        final double contentHeight =
            (baseHeight + (addressItemHeight * addressCount))
                .clamp(0.0, maxHeight);

        return Container(
          height: contentHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Select Address',
                        style: GoogleFonts.manrope(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Address list with dynamic sizing
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    ...cartProvider.addresses.map(
                      (address) => _buildCompactAddressTile(
                        address: address,
                        index: cartProvider.addresses.indexOf(address),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),

              // Add new button (always visible)
              Padding(
                padding: EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToAddAddress();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff101d42),
                    minimumSize: Size(double.infinity, 56),
                  ),
                  child: Text('Add New Address',
                      style: GoogleFonts.manrope(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactAddressTile({
    required dynamic address,
    required int index,
  }) {
    final isSelected = index == _selectedAddressIndex;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue[200]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.blue[700]! : Colors.grey[400]!,
              width: isSelected ? 6 : 2,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cartProvider.userDetails?.fullName ??
                  cartProvider.googleProfile?.name ??
                  'NA',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 2),
            Text(
              address.contact,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${address.apartmentNo}, ${address.street}, ${address.area}',
                  style: GoogleFonts.manrope(fontSize: 13)),
              // Text('${address.street},  ${address.area}',
              //     style: GoogleFonts.manrope(fontSize: 13)),
              Text('${address.city} - ${address.pincode}',
                  style: GoogleFonts.manrope(fontSize: 13)),
            ],
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit_outlined, size: 20, color: Colors.blue[700]),
          onPressed: () {
            Navigator.pop(context);
            _navigateToAddAddress(isEditing: true, index: index);
          },
        ),
        onTap: () {
          setState(() => _selectedAddressIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Skeletonizer(
      enabled: true,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Progress indicator shimmer
            Container(
              padding: EdgeInsets.fromLTRB(65, 6, 78, 20),
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
                        List.generate(3, (index) => Bone.circle(size: 30)),
                  ),
                ],
              ),
            ),

            // Address section shimmer
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(width: 150),
                  SizedBox(height: 16),
                  Container(
                    height: MediaQuery.of(context).size.height / 9,
                    width: double.infinity,
                    child: Bone.iconButton(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),

            // Order summary shimmer
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(width: 150),
                  SizedBox(height: 16),
                  ...List.generate(
                    3,
                    (index) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Bone.square(size: 60, uniRadius: 8),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Bone.text(width: double.infinity),
                                SizedBox(height: 4),
                                Bone.text(width: 80),
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

            // Price details shimmer
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ...List.generate(
                    4,
                    (index) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Bone.text(width: 80),
                          Bone.text(width: 60),
                        ],
                      ),
                    ),
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
