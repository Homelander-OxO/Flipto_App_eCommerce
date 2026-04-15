import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/e-subcategory_model.dart';
import 'package:flutter_app/models/rating_model.dart';
import 'package:flutter_app/screens/add_rr.dart';
import 'package:flutter_app/screens/product_screen.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/custom_widgets/loading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:order_tracker/order_tracker.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart'; // Import animations package

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

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final String productId;
  final String productName;
  final String productImage;
  final String productPrice;
  final String discount;
  final String iDiscount;
  final String discountedPrice;
  final String createdAt;
  final String email;
  final bool showAddress; // Added parameter to control address visibility

  const OrderTrackingScreen({
    Key? key,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.discount,
    required this.iDiscount,
    required this.discountedPrice,
    required this.createdAt,
    required this.email,
    this.showAddress = true, // Default to true for backward compatibility
  }) : super(key: key);

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with TickerProviderStateMixin {
  List<String> _trackingStatuses = [];
  List<String> _shippedCities = [];
  bool _isLoading = true;
  Map<String, dynamic>? _orderItem;
  bool _isTrackingExpanded = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _isDelivered = false;
  String? _formattedAddress; // Added to store formatted address
  ProductRating? _productReview;
  bool _isReviewLoading = false;
  bool _isEditLoading = false; // Add this to your state class
  double _addReviewScale = 1.0; // Add this to your _UserProfileScreenState
  double _downloadScale = 1.0;

  String _getRatingLabel(double rating) {
    switch (rating.round()) {
      case 5:
        return "Great";
      case 4:
        return "Good";
      case 3:
        return "Average";
      case 2:
        return "Terrible";
      case 1:
        return "Bad";
      default:
        return "";
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrderTrackingData(widget.email);
    _isDelivered = false; // initialize

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isDelivered = _trackingStatuses.contains("Delivered");
          });
        }
      });

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    _progressController.forward();
    _fetchProductReview();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

// Add this method to fetch the review
  Future<void> _fetchProductReview() async {
    if (!mounted) return;
    setState(() => _isReviewLoading = true);

    try {
      // Fetch all reviews for the user
      final reviews = await ApiService.fetchReviews(widget.email);

      // Find the review for this specific product
      final productReview = reviews.firstWhere(
        (review) => review.productId == widget.productId,
        orElse: () => ProductRating(
          rid: '',
          userId: '',
          productId: '',
          rating: '0',
          ratings: 0,
          review: '',
          images: [],
          createdAt: '',
          updatedAt: '',
        ),
      );

      if (productReview.rid.isNotEmpty) {
        setState(() {
          _productReview = productReview;
          _isReviewLoading = false;
        });
      } else {
        setState(() {
          _productReview = null;
          _isReviewLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _productReview = null;
        _isReviewLoading = false;
      });
      debugPrint('Error fetching review: $e');
    }
  }

  void fetchOrderTrackingData(String email) async {
    print("Fetching data for Email: $email");

    final trackingData = await ApiService.fetchTrackingData(email);

    if (trackingData != null && trackingData['order'] != null) {
      List<dynamic> orders = trackingData['order'];

      // Find the specific order item for this product
      final orderItem = orders.firstWhere(
        (item) =>
            item['order_id'] == widget.orderId &&
            item['product_id'] == widget.productId,
        orElse: () => {},
      );

      if (orderItem.isNotEmpty) {
        String statusString = orderItem['status'];
        List<String> statuses = [];
        List<String> cities = [];

        for (String item in statusString.split(',')) {
          if (item == "Order Placed" ||
              item == "Packed" ||
              item == "Shipped" ||
              item == "Out for Delivery" ||
              item == "Delivered" ||
              item == "Return Requested" ||
              item == "Picked by Delivery Boy" ||
              item == "Returned") {
            statuses.add(item);
          } else {
            cities.add(item);
          }
        }

        if (cities.isNotEmpty && !statuses.contains("Shipped")) {
          statuses.add("Shipped");
        }

        // Process the address to remove duplication if needed
        String? address = orderItem['selectedAddress'];
        if (address != null && address.isNotEmpty) {
          // Clean up duplicated address by checking for common patterns
          List<String> addressParts = address.split(',');
          List<String> cleanedParts = [];
          Set<String> uniqueParts = {};

          // Remove duplicated parts while preserving order
          for (String part in addressParts) {
            String trimmed = part.trim();
            if (!uniqueParts.contains(trimmed)) {
              uniqueParts.add(trimmed);
              cleanedParts.add(trimmed);
            }
          }

          // Join cleaned parts back with commas
          _formattedAddress = cleanedParts.join(', ');
        }

        setState(() {
          _trackingStatuses = statuses;
          _shippedCities = cities;
          _orderItem = orderItem;
          _isLoading = false;
        });
      } else {
        print("No order item found for product ${widget.productId}");
        setState(() => _isLoading = false);
      }
    } else {
      print("No tracking data found for email: $email");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No tracking data found for this email")),
      );
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final DateTime parsedDate = DateTime.parse(dateTime);
      final String daySuffix = _getDaySuffix(parsedDate.day);
      return DateFormat("EEE, d'$daySuffix' MMM ''yy - h:mma")
          .format(parsedDate);
    } catch (e) {
      return dateTime;
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return "th";
    switch (day % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }

  Future<void> _navigateToEditReview() async {
    if (_isEditLoading) return; // Prevent double tap
    setState(() {
      _isReviewLoading = true;
      _isEditLoading = true;
    });

    try {
      // Fetch the latest review data
      final updatedReview =
          await ApiService.fetchReviewById(_productReview!.rid);

      if (!mounted) return;
      setState(() => _isReviewLoading = false);

      if (updatedReview != null) {
        print(
            'Navigating to edit review screen with data: ${updatedReview.review}');

        // This is the crucial fix - we need to create a proper ProductRating object
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddReviewScreen(
              productId: widget.productId,
              productName: widget.productName,
              productImage: widget.productImage,
              email: widget.email,
              existingReview: updatedReview, // Pass the correctly parsed object
            ),
          ),
        );

        if (result == true && mounted) {
          _fetchProductReview(); // Refresh after editing
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load review details'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isReviewLoading = false);
      debugPrint('Error navigating to edit review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load review details'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isEditLoading = false); // ✅ ensure button spinner stops
      }
    }
  }

  Future<void> _navigateToAddReview() async {
    final result = await Navigator.push(
      context,
      CustomCupertinoPageRoute(
        builder: (context) => AddReviewScreen(
          productId: widget.productId,
          productName: widget.productName,
          productImage: widget.productImage,
          email: widget.email,
        ),
      ),
    );

    if (result == true) {
      _fetchProductReview(); // Refresh after adding
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.all(8),
        ),
        iconTheme: IconThemeData(color: Colors.black),
        toolbarHeight: 56,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            _buildOrderCard(
              title: 'Order Summary',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Order ID', widget.orderId),
                  SizedBox(height: 6),
                  _buildInfoRow(
                      'Order Date', _formatDateTime(widget.createdAt)),
                ],
              ),
            ),

            SizedBox(height: 14),
            if (_trackingStatuses.contains("Delivered"))
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: _downloadScale),
                duration: const Duration(milliseconds: 200),
                curve: _downloadScale < 1.0 ? Curves.easeIn : Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTapDown: (_) => setState(
                              () => _downloadScale = 0.92),
                      onTapUp: (_) async {
                        setState(() => _downloadScale = 1.0);
                        await ApiService.downloadInvoice(_orderItem?['id']);
                      },
                      onTapCancel: () =>
                          setState(() => _downloadScale = 1.0),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const ImageIcon(
                              AssetImage('assets/images/invoice.png'),
                              size: 20,
                              color: Color(0xff101d42),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Download Invoice",
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.file_download_outlined,
                              size: 22,
                              color: Color(0xff101d42),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Product Details Card
            _buildOrderCard(
              title: 'Product Details',
              onTap: _navigateToProduct,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.productImage,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.broken_image, color: Colors.grey[400]),
                        ),
                      )),
                  SizedBox(width: 12),
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: GoogleFonts.manrope(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3),
                        Text(
                          '₹${widget.productPrice}',
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_orderItem?['quantity'] != null)
                          Text(
                            'Qty: ${_orderItem?['quantity']}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        Row(
                          children: [
                            Text(
                              'Color: ${_orderItem?['color']} | ',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Size: ${_orderItem?['size']}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),

            if (_productReview != null && _productReview!.rid.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Text(
                        _getRatingLabel(_productReview!.ratings ?? 0),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Color(0xff101d42),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      StarRating(
                        rating: _productReview!.ratings ?? 0,
                        starSize: 21,
                      ),
                      const SizedBox(height: 4),

                      Spacer(),
                      _isEditLoading
                          ? Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7, vertical: 5),
                        width: MediaQuery.of(context).size.width / 6.6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: Colors.transparent, width: 1.3),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              strokeCap: StrokeCap.round,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff101d42),
                              ),
                            ),
                          ),
                        ),
                      )
                          : InkWell(
                        onTap: _navigateToEditReview,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7, vertical: 5),
                          width: MediaQuery.of(context).size.width / 6.3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: Colors.blueGrey.shade50,
                                width: 1.3),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                              ),
                              Text(
                                'Edit',
                                style: GoogleFonts.poppins(
                                  color: Color(0xff101d42),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_trackingStatuses.contains("Delivered"))
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _addReviewScale = 0.95),
                  onTapUp: (_) {
                    setState(() => _addReviewScale = 1.0);
                    _navigateToAddReview();
                  },
                  onTapCancel: () => setState(() => _addReviewScale = 1.0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 1.0, end: _addReviewScale),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: double.infinity,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xff101d42),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Text(
                            'Add Review',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Order Tracking Card
            _buildOrderCard(
              title: 'Order Status',
              child: OpenContainer(
                closedElevation: 0,
                transitionType: ContainerTransitionType.fade,
                openBuilder: (context, _) => FullScreenOrderTracker(
                  trackingStatuses: _trackingStatuses,
                  shippedCities: _shippedCities,
                  createdAt: widget.createdAt,
                ),
                closedBuilder: (context, VoidCallback openContainer) =>
                    _buildSimplifiedOrderTracker(),
              ),
            ),

            SizedBox(height: 14),

            // Shipping Address Card
            if (_formattedAddress != null && widget.showAddress)
              _buildOrderCard(
                title: 'Shipping Address',
                child: Text(
                  _formattedAddress!,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            if (_formattedAddress != null && widget.showAddress)
              SizedBox(height: 14),

            // Price Details Card
            _buildOrderCard(
              title: 'Price Details',
              child: Builder(
                builder: (context) {
                  final itemTotal =
                      (double.tryParse(widget.discountedPrice) ?? 0) *
                          (int.tryParse(
                              _orderItem?['quantity']?.toString() ?? '1') ??
                              1);

                  return Column(
                    children: [
                      _buildPriceRow('Item Price', '₹${widget.productPrice}'),
                      _buildPriceRow('Discount (${widget.discount}% OFF)',
                          '- ₹${widget.iDiscount}'),
                      _buildPriceRow(
                          'Special Price', '₹${widget.discountedPrice}'),
                      _buildPriceRow(
                          'Item Total (${_orderItem?['quantity']?.toString() ?? '1'} Items)',
                          '₹$itemTotal'),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.015,
                        child: Center(
                          child: CustomPaint(
                            painter: _DashedLinePainter(),
                            size: Size(double.infinity, 1),
                          ),
                        ),
                      ),
                      _buildPriceRow(
                        'Total Amount',
                        '₹${itemTotal}',
                        isTotal: true,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required String title,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(
      String label,
      String value, {
        bool isTotal = false,
        bool isDelivery = false,
        bool isFreeDelivery = false,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: isTotal ? Colors.black : Colors.grey[900],
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isDelivery && isFreeDelivery)
            Row(
              children: [
                Text(
                  '₹40',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * 0.012),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: isTotal ? Colors.black : Colors.grey[800],
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSimplifiedOrderTracker() {
    return Column(
      children: [
        _buildTrackingItem(
          isActive: _trackingStatuses.contains("Order Placed"),
          status: "Order Placed",
          date: _formatDateTime(widget.createdAt),
          isFirst: true,
          isLast: false,
        ),
        Row(
          children: [
            Expanded(
              child: _buildTrackingItem(
                isActive: _trackingStatuses.contains("Delivered"),
                status: "Delivered",
                date: _trackingStatuses.contains("Delivered")
                    ? "Thu, 31th Mar '22 - 3:58pm"
                    : "Pending",
                isFirst: false,
                isLast: true,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
            )
          ],
        ),
      ],
    );
  }

  Widget _buildTrackingItem({
    required bool isActive,
    required String status,
    required String date,
    required bool isFirst,
    required bool isLast,
  }) {
    final isDeliveredStatus = status == "Delivered";
    final showDeliveredAsActive = isDeliveredStatus && _isDelivered;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: showDeliveredAsActive
                    ? Colors.green
                    : (isActive && !isDeliveredStatus)
                    ? Colors.green
                    : Colors.grey[300],
              ),
              child: Center(
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 35,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    if (isDeliveredStatus) {
                      return RotatedBox(
                        quarterTurns: 1,
                        child: LinearProgressIndicator(
                          value: _isDelivered ? 1 : 0,
                          color: Colors.green,
                          backgroundColor: Colors.grey[200],
                        ),
                      );
                    }

                    final shouldAnimate = isActive ||
                        (status == "Order Placed" &&
                            _trackingStatuses.isNotEmpty);

                    return RotatedBox(
                      quarterTurns: 1,
                      child: LinearProgressIndicator(
                        value: shouldAnimate ? _progressAnimation.value : 0,
                        color: Colors.green,
                        backgroundColor: Colors.grey[200],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: showDeliveredAsActive
                    ? Colors.black
                    : (isActive && !isDeliveredStatus)
                    ? Colors.black
                    : Colors.grey[600],
              ),
            ),
            Text(
              date,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Original order tracker
  Widget _buildOrderTracker() {
    List<TextDto> orderList = [];
    if (_trackingStatuses.contains("Order Placed")) {
      orderList.add(TextDto(
          "Your order has been placed", _formatDateTime(widget.createdAt), ""));
    }

    List<TextDto> packedList = [];
    String? packedDate;
    if (_trackingStatuses.contains("Packed")) {
      // Extract the packed date from tracking data if available
      packedDate = _getDateForStatus("Packed");
      packedList.add(
          TextDto("Seller has processed your order", packedDate ?? "", ""));
    }

    List<TextDto> shippedList = [];
    String? shippedDate;
    if (_trackingStatuses.contains("Shipped")) {
      // Extract the shipped date from tracking data if available
      shippedDate = _getDateForStatus("Shipped");
      shippedList
          .add(TextDto("Your order has been shipped", shippedDate ?? "", ""));
      for (String city in _shippedCities) {
        shippedList.add(TextDto("Your item left from $city", "", ''));
      }
    }

    List<TextDto> outOfDeliveryList = [];
    String? outForDeliveryDate;
    if (_trackingStatuses.contains("Out for Delivery")) {
      // Extract the out for delivery date from tracking data if available
      outForDeliveryDate = _getDateForStatus("Out for Delivery");
      outOfDeliveryList.add(TextDto(
          "Your order is out for delivery", outForDeliveryDate ?? "", ""));
    }

    List<TextDto> deliveredList = [];
    String? deliveredDate;
    if (_trackingStatuses.contains("Delivered")) {
      // Extract the delivered date from tracking data if available
      deliveredDate = _getDateForStatus("Delivered");
      deliveredList.add(
          TextDto("Your order has been delivered", deliveredDate ?? "", ""));
    }

    Status orderStatus = Status.order;
    if (_trackingStatuses.contains("Delivered")) {
      orderStatus = Status.delivered;
    } else if (_trackingStatuses.contains("Out for Delivery")) {
      orderStatus = Status.outOfDelivery;
    } else if (_trackingStatuses.contains("Shipped")) {
      orderStatus = Status.shipped;
    } else if (_trackingStatuses.contains("Packed")) {
      orderStatus = Status.packed;
    }

    return OrderTracker(
      status: orderStatus,
      activeColor: Colors.green,
      inActiveColor: Colors.grey,
      orderTitleAndDateList: orderList,
      packedTitleAndDateList: packedList,
      shippedTitleAndDateList: shippedList,
      outOfDeliveryTitleAndDateList: outOfDeliveryList,
      deliveredTitleAndDateList: deliveredList,
      // Pass dynamic dates to the updated OrderTracker
      orderPlacedDate: _formatDateTime(widget.createdAt),
      packagedDate: packedDate,
      shippedDate: shippedDate,
      outForDeliveryDate: outForDeliveryDate,
      deliveredDate: deliveredDate,
    );
  }

  // Helper method to extract dates for each status
  String? _getDateForStatus(String status) {
    // Check if we have the status in our tracking data
    if (_orderItem != null && _orderItem!['statusDates'] != null) {
      Map<String, dynamic> statusDates = _orderItem!['statusDates'];
      if (statusDates.containsKey(status)) {
        return _formatDateTime(statusDates[status]);
      }
    }

    // Fallback to using the current order's date with an offset
    // This is just a placeholder until you implement proper date tracking
    try {
      DateTime orderDate = DateTime.parse(widget.createdAt);

      // Add some days based on the status - just for demonstration
      switch (status) {
        case "Packed":
          return _formatDateTime(orderDate.add(Duration(days: 1)).toString());
        case "Shipped":
          return _formatDateTime(orderDate.add(Duration(days: 2)).toString());
        case "Out for Delivery":
          return _formatDateTime(orderDate.add(Duration(days: 3)).toString());
        case "Delivered":
          return _formatDateTime(orderDate.add(Duration(days: 4)).toString());
        default:
          return null;
      }
    } catch (e) {
      print("Error calculating status date: $e");
      return null;
    }
  }

  void _navigateToProduct() {
    // Create a complete Subcategory object with all required data
    final subcategory = Subcategory(
      id: "0",
      // placeholder category ID
      product_id: widget.productId,
      name: widget.productName,
      type: _orderItem?['product_type'] ?? "",
      gender: _orderItem?['gender_category'] ?? "",
      description: _orderItem?['product_desc'] ?? "",
      price: widget.productPrice,
      discount: _orderItem?['discount']?.toString() ?? "0",
      image: _orderItem?['product_image'] ??
          jsonEncode({
            'main': [widget.productImage],
            'colors': {}
          }),
      productDetails: ProductDetails.fromJson(
        _orderItem?['product_image'] ?? '{"main":[],"colors":{}}',
        _orderItem?['available_sizes'] ?? _orderItem?['size'] ?? '',
      ),
      size: _orderItem?['size']?.toString(),
      color: _orderItem?['color']?.toString(),
    );

    Navigator.push(
      context,
      CustomCupertinoPageRoute(
        builder: (context) => ItemDetailScreen(
          subcategory: subcategory,
        ),
      ),
    );
  }
}

// Full screen order tracker implementation
class FullScreenOrderTracker extends StatefulWidget {
  final List<String> trackingStatuses;
  final List<String> shippedCities;
  final String createdAt;

  const FullScreenOrderTracker({
    Key? key,
    required this.trackingStatuses,
    required this.shippedCities,
    required this.createdAt,
  }) : super(key: key);

  @override
  State<FullScreenOrderTracker> createState() => _FullScreenOrderTrackerState();
}

class _FullScreenOrderTrackerState extends State<FullScreenOrderTracker> {
  Map<String, dynamic>? _orderItem;

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return "th";
    switch (day % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      final DateTime parsedDate = DateTime.parse(dateTime);
      final String daySuffix = _getDaySuffix(parsedDate.day);
      return DateFormat("EEE, d'$daySuffix' MMM ''yy - h:mma")
          .format(parsedDate);
    } catch (e) {
      return dateTime;
    }
  }

  String? _getDateForStatus(String status) {
    // Check if we have the status in our tracking data
    if (_orderItem != null && _orderItem!['statusDates'] != null) {
      Map<String, dynamic> statusDates = _orderItem!['statusDates'];
      if (statusDates.containsKey(status)) {
        return _formatDateTime(statusDates[status]);
      }
    }

    try {
      DateTime orderDate = DateTime.parse(widget.createdAt);

      // Add some days based on the status - just for demonstration
      switch (status) {
        case "Packed":
          return _formatDateTime(orderDate.add(Duration(days: 1)).toString());
        case "Shipped":
          return _formatDateTime(orderDate.add(Duration(days: 2)).toString());
        case "Out for Delivery":
          return _formatDateTime(orderDate.add(Duration(days: 3)).toString());
        case "Delivered":
          return _formatDateTime(orderDate.add(Duration(days: 4)).toString());
        default:
          return null;
      }
    } catch (e) {
      print("Error calculating status date: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TextDto> orderList = [];
    if (widget.trackingStatuses.contains("Order Placed")) {
      orderList.add(TextDto(
          "Your order has been placed", _formatDateTime(widget.createdAt), ""));
    }

    List<TextDto> packedList = [];
    String? packedDate;
    if (widget.trackingStatuses.contains("Packed")) {
      // Extract the packed date from tracking data if available
      packedDate = _getDateForStatus("Packed");
      packedList.add(
          TextDto("Seller has processed your order", packedDate ?? "", ""));
    }

    List<TextDto> shippedList = [];
    String? shippedDate;
    if (widget.trackingStatuses.contains("Shipped")) {
      // Extract the shipped date from tracking data if available
      shippedDate = _getDateForStatus("Shipped");
      shippedList
          .add(TextDto("Your order has been shipped", shippedDate ?? "", ""));
      for (String city in widget.shippedCities) {
        shippedList.add(TextDto("Your item left from $city", "", ''));
      }
    }

    List<TextDto> outOfDeliveryList = [];
    String? outForDeliveryDate;
    if (widget.trackingStatuses.contains("Out for Delivery")) {
      // Extract the out for delivery date from tracking data if available
      outForDeliveryDate = _getDateForStatus("Out for Delivery");
      outOfDeliveryList.add(TextDto(
          "Your order is out for delivery", outForDeliveryDate ?? "", ""));
    }

    List<TextDto> deliveredList = [];
    String? deliveredDate;
    if (widget.trackingStatuses.contains("Delivered")) {
      // Extract the delivered date from tracking data if available
      deliveredDate = _getDateForStatus("Delivered");
      deliveredList.add(
          TextDto("Your order has been delivered", deliveredDate ?? "", ""));
    }

    Status orderStatus = Status.order;
    if (widget.trackingStatuses.contains("Delivered")) {
      orderStatus = Status.delivered;
    } else if (widget.trackingStatuses.contains("Out for Delivery")) {
      orderStatus = Status.outOfDelivery;
    } else if (widget.trackingStatuses.contains("Shipped")) {
      orderStatus = Status.shipped;
    } else if (widget.trackingStatuses.contains("Packed")) {
      orderStatus = Status.packed;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Order Tracking Details',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            OrderTracker(
              status: orderStatus,
              activeColor: Colors.green,
              inActiveColor: Colors.grey[300],
              orderTitleAndDateList: orderList,
              packedTitleAndDateList: packedList,
              shippedTitleAndDateList: shippedList,
              outOfDeliveryTitleAndDateList: outOfDeliveryList,
              deliveredTitleAndDateList: deliveredList,
              // Pass dynamic dates to the updated OrderTracker
              orderPlacedDate: _formatDateTime(widget.createdAt),
              packagedDate: packedDate,
              shippedDate: shippedDate,
              outForDeliveryDate: outForDeliveryDate,
              deliveredDate: deliveredDate,
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
