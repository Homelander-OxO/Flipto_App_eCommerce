import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/add_rr.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/order_traking.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class ShippingHistoryScreen extends StatefulWidget {
  final String email;

  const ShippingHistoryScreen({Key? key, required this.email})
      : super(key: key);

  @override
  _ShippingHistoryScreenState createState() => _ShippingHistoryScreenState();
}

class _ShippingHistoryScreenState extends State<ShippingHistoryScreen> {
  Map<String, dynamic>? _shippingHistory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchShippingHistory();
  }

  void fetchShippingHistory() async {
    try {
      final data = await ApiService.fetchTrackingData(widget.email);
      setState(() {
        _shippingHistory = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load shipping history: $e')),
      );
    }
  }

  String _getFirstProductImage(dynamic imageData) {
    if (imageData == null) return '';

    // Case 1: If it's already a proper URL string
    if (imageData is String && imageData.startsWith('http')) {
      return imageData.replaceAll(r'\/', '/').replaceAll('Apis./', 'Apis/');
    }

    // Case 2: If it's a JSON string
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

    // Case 3: If it's already parsed JSON
    if (imageData is Map &&
        imageData['main'] is List &&
        imageData['main'].isNotEmpty) {
      return imageData['main'][0]
          .toString()
          .replaceAll(r'\/', '/')
          .replaceAll('Apis./', 'Apis/');
    }

    return ''; // No valid image found
  }

  String _getOrderStatus(String status) {
    if (status == null || status.isEmpty) return 'Processing';

    final statuses =
    status.split(',').map((s) => s.trim().toLowerCase()).toList();
    const completedStatuses = ['delivered', 'completed', 'fulfilled'];

    // Check if any status (not just last) indicates completion
    if (statuses.any((s) => completedStatuses.contains(s))) {
      return 'Completed';
    }

    return 'Processing';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        title: Text(
          'My Orders',
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Lottie.asset(
          'assets/images/Animation - 1746177894717.json',
          width: 180,
          height: 180,
          frameRate: FrameRate.max,
        ),
      )
          : _shippingHistory == null
          ? const Center(child: Text('No shipping history found'))
          : _buildShippingHistory(),
    );
  }

  Widget _buildShippingHistory() {
    final products = _shippingHistory!['products'];
    final orders = _shippingHistory!['order'];

    // Group orders by order_id first
    final orderGroups = <String, List<dynamic>>{};
    for (var order in orders) {
      orderGroups.putIfAbsent(order['order_id'], () => []).add(order);
    }

    // Create a list of all products with order information
    List<Map<String, dynamic>> allProducts = [];
    orderGroups.forEach((orderId, orderItems) {
      final orderProducts = products[orderId] ?? [];
      final createdAt = orderItems.first['created_at'];
      final status = orderItems.first['status'];

      for (var product in orderProducts) {
        final orderItem = orderItems.firstWhere(
              (item) => item['product_id'] == product['product_id'],
          orElse: () => {'quantity': '1'},
        );

        allProducts.add({
          ...product,
          'order_id': orderId,
          'created_at': createdAt,
          'status': status,
          'quantity': orderItem['quantity'],
        });
      }
    });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: allProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = allProducts[index];
        final imageUrl = _getFirstProductImage(product['product_image']);
        final createdAt = _formatDateTime(product['created_at']);

        return _buildOrderCard(
          context: context,
          product: product,
          imageUrl: imageUrl,
          createdAt: createdAt,
        ).animate().fadeIn(delay: (50 * index).ms).slideX(
          begin: 0.1,
          curve: Curves.easeOutCubic,
          duration: 250.ms,
        );
      },
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required Map<String, dynamic> product,
    required String imageUrl,
    required String createdAt,
  }) {
    final status = _getOrderStatus(product['status'] ?? 'Order Placed');
    final isCompleted = status == 'Completed';
    final discount = int.tryParse(product['discount']) ?? 0;
    final originalPrice = double.parse(product['product_price']);
    final discountedPrice = originalPrice * (100 - discount) / 100;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.08),
          width: 1.25,
        ),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToOrderTracking(context, product, imageUrl),
        highlightColor: Colors.black.withOpacity(0.015),
        splashColor: Colors.black.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    createdAt.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.08)
                          : Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCompleted
                              ? Icons.check_circle_outline
                              : Icons.access_time,
                          size: 13,
                          color: isCompleted
                              ? Colors.green[600]
                              : Colors.orange[600],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          status,
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: isCompleted
                                ? Colors.green[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Product image
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildProductImage(imageUrl),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Product details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['product_name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Text(
                              '₹${discountedPrice.toStringAsFixed(1)}',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (discount > 0) ...[
                              Text(
                                '₹${product['product_price']}',
                                style: GoogleFonts.manrope(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${product['quantity']} items',
                                style: GoogleFonts.manrope(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chevron
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 28,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        return progress == null
            ? child
            : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[50]!,
                Colors.grey[100]!,
              ],
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[400],
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[50]!,
                Colors.grey[100]!,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 28,
              color: Colors.grey[400],
            ),
          ),
        );
      },
    );
  }

  void _navigateToOrderTracking(BuildContext context,
      Map<String, dynamic> product, String imageUrl) {
    final discount = int.tryParse(product['discount']) ?? 0;
    final originalPrice = double.parse(product['product_price']);
    final iDiscount = originalPrice * (discount) / 100;
    final discountedPrice = originalPrice * (100 - discount) / 100;

    Navigator.push(
      context,
      CustomCupertinoPageRoute(
        builder: (context) =>
            OrderTrackingScreen(
              email: widget.email,
              orderId: product['order_id'],
              productName: product['product_name'],
              productImage: imageUrl,
              productPrice: product['product_price'],
              discount: product['discount'],
              iDiscount: iDiscount.toString(),
              discountedPrice: discountedPrice.toString(),
              createdAt: product['created_at'],
              productId: product['product_id'],
            ),
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime);
    final String daySuffix = _getDaySuffix(parsedDate.day);
    return DateFormat("EEE, d'$daySuffix' MMM ''yy - h:mma").format(parsedDate);
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return "th";
    }
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
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50], // Match your background color
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
        ),
      ),
    );
  }
}
