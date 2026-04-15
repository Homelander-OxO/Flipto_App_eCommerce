import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/API%20E-Commerce/Model/rating_model.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/add_rr.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/custom_widgets/loading.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ReviewsScreen extends StatefulWidget {
  final String email;

  const ReviewsScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool _isLoading = true;
  List<RatedProduct> _ratedProducts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // Combine both data loading operations into one
  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load both data sources at the same time
      final reviewsFuture = ApiService.fetchReviews(widget.email);
      final trackingDataFuture = ApiService.fetchTrackingData(widget.email);

      // Wait for both to complete
      final results = await Future.wait([reviewsFuture, trackingDataFuture]);
      final userReviews = results[0] as List<ProductRating>;
      final trackingData = results[1] as Map<String, dynamic>?;

      if (trackingData == null) throw Exception('No tracking data found');

      final Map<String, dynamic> productsMap = trackingData['products'];
      final List<RatedProduct> result = [];

      // Flatten products
      final List<dynamic> allProductLists =
          productsMap.values.expand((list) => list).toList();

      for (var review in userReviews) {
        final productId = review.productId;

        // Find matching product from shipHistory
        final matchingProduct = allProductLists.firstWhere(
          (p) => p['product_id'] == productId,
          orElse: () => null,
        );

        if (matchingProduct != null) {
          final imageList =
              matchingProduct['product_image']['main'] as List<dynamic>;
          final productImage =
              imageList.isNotEmpty ? imageList.first.toString() : '';

          result.add(
            RatedProduct(
              productId: productId,
              productName: matchingProduct['product_name'],
              productImage: productImage,
              review: review,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _ratedProducts = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading review data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshReviews() async {
    return _loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Reviews',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black87),
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReviews,
        color: Color(0xff101d42),
        displacement: 40,
        edgeOffset: 20,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_ratedProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: 16),
      itemCount: _ratedProducts.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _ratedProducts[index];
        return _buildReviewCard(item);
      },
    );
  }

  Widget _buildReviewCard(RatedProduct item) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image (Left side)
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
                      item.productImage,
                      // fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.shopping_bag_outlined,
                            size: 30, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Right side content (Product name, rating, review)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        item.productName,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      // Rating stars and date
                      Row(
                        children: [
                          _buildRatingStars(
                              item.review.ratings?.toDouble() ?? 0),
                          Spacer(),
                          Text(
                            _formatDate(item.review.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      // Review text directly below the rating
                      SizedBox(height: 8),

                      _buildFormattedReviewText(item.review.review),
                    ],
                  ),
                ),
              ],
            ),
          ),
           Divider(height: 1, thickness: 0.8, color: Colors.grey[200]),
          // Action Buttons
          IntrinsicHeight(
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onPressed: () => _editReview(item.review),
                ),
                VerticalDivider(
                    width: 0, thickness: 0.8, color: Colors.grey[200]),
                _buildActionButton(
                  icon: CupertinoIcons.delete,
                  label: 'Delete',
                  onPressed: () => _confirmDeleteReview(item.review),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedReviewText(String reviewText) {
    // Trim the review text
    final String trimmedText = reviewText.trim();

    // Check if we have a title and description format (contains double newline)
    if (trimmedText.contains('\n\n')) {
      final parts = trimmedText.split('\n\n');
      final title = parts[0];
      final description = parts.sublist(1).join('\n');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title in bold
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              // height: 1.2,
            ),
          ),
          // Smaller gap between title and description
          SizedBox(height: 4),
          // Description text
          Text(
            description,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      // Single paragraph format
      return Text(
        trimmedText,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[800],
          height: 1.3,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xff101d42)),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading your reviews',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
            SizedBox(height: 16),
            Text(
              'Couldn\'t load reviews',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshReviews,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff101d42),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Reviews Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your reviews will appear here once you submit them',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          minimumSize: Size(0, 28),
          tapTargetSize:
          MaterialTapTargetSize
              .shrinkWrap,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round()
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, y').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _editReview(ProductRating review) async {
    showDialog(
      barrierColor: Colors.black26.withOpacity(0.3),
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(
            color: Colors.indigoAccent.shade400,
            strokeWidth: 2.7,
            strokeCap: StrokeCap.round,
          ),
        ),
      ),
    );

    try {
      final currentReview = await ApiService.fetchReviewById(review.rid);
      if (currentReview == null) {
        Navigator.pop(context);
        _showErrorDialog('Failed to fetch review details');
        return;
      }

      final allProducts =
          await ApiService.fetchAllProducts(['3', '4', '5', '6', '7', '8']);

      final subcategory = allProducts.firstWhere(
        (item) => item.product_id == currentReview.productId,
        orElse: () => throw Exception('Matching product not found'),
      );

      Navigator.pop(context); // close loader

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddReviewScreen(
            productId: currentReview.productId,
            productName: subcategory.name,
            productImage: subcategory.mainImages.isNotEmpty
                ? subcategory.mainImages.first
                : '',
            email: widget.email,
            existingReview: currentReview,
          ),
        ),
      );

      if (result == true) {
        _refreshReviews();
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _confirmDeleteReview(ProductRating review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Review?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this review?',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff101d42)),
          ),
        ),
      );

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final user = cartProvider.useremail ?? cartProvider.email ?? 'NA';
      final success = await ApiService.removeReview(user, review.rid);

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Immediately update the UI by removing the deleted review
        setState(() {
          _ratedProducts.removeWhere((item) => item.review.rid == review.rid);
        });

        // Optional: Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showErrorDialog('Failed to delete review');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showErrorDialog('Error deleting review: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: Color(0xff101d42),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// You'll need to define this class if not already defined elsewhere
class RatedProduct {
  final String productId;
  final String productName;
  final String productImage;
  final ProductRating review;

  RatedProduct({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.review,
  });
}
