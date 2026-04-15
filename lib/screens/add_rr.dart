import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/rating_model.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

class AddReviewScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final String productImage;
  final String email;
  final ProductRating? existingReview;

  const AddReviewScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.email,
    this.existingReview,
  }) : super(key: key);

  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 0;
  final TextEditingController _reviewTitleController = TextEditingController();
  final TextEditingController _reviewMessageController =
      TextEditingController();
  List<File> _images = [];
  bool _isSubmitting = false;
  List<String> previousImageUrls =
      []; // For existing image URLs from the server
  double _submitReviewScale = 1.0; // Add this to your state class

  @override
  void initState() {
    super.initState();

    // Initialize with existing review data if available
    if (widget.existingReview != null) {
      print(
          "Initializing review form with existing data: ${widget.existingReview!.review}");

      // Set rating
      _rating = widget.existingReview!.ratings ??
          double.tryParse(widget.existingReview!.rating) ??
          0;
      print("Setting rating to: $_rating");

      // Process review text - often contains both title and content
      String reviewText = widget.existingReview!.review;
      List<String> reviewParts = reviewText.split('\n\n');

      if (reviewParts.length > 1) {
        // If review has multiple paragraphs, use first as title
        _reviewTitleController.text = reviewParts[0];
        _reviewMessageController.text = reviewParts.sublist(1).join('\n\n');
      } else {
        // Otherwise just put everything in the message
        _reviewMessageController.text = reviewText;
      }

      print("Title set to: ${_reviewTitleController.text}");
      print("Review message set to: ${_reviewMessageController.text}");

      // Handle existing image URLs if they exist
      if (widget.existingReview!.images.isNotEmpty) {
        // Just store them as URLs, no need to convert to File here
        previousImageUrls = List<String>.from(widget.existingReview!.images);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // Check and request permissions
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 32) {
          // For Android 12 and below
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (await status.isPermanentlyDenied) {
              await openAppSettings();
            }
            return;
          }
        } else {
          // For Android 13 and above
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            if (await status.isPermanentlyDenied) {
              await openAppSettings();
            }
            return;
          }
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (!status.isGranted) return;
      }

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _images.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitReview() async {
    if (_formKey.currentState!.validate() && _rating > 0) {
      setState(() => _isSubmitting = true);

      try {
        // Combine title and message for the API
        String combinedReview;
        if (_reviewTitleController.text.isNotEmpty &&
            _reviewMessageController.text.isNotEmpty) {
          combinedReview =
              '${_reviewTitleController.text}\n\n${_reviewMessageController.text}';
        } else {
          // If no title, just use the message
          combinedReview = _reviewMessageController.text;
        }

        // Determine if this is an edit or a new review
        final isEdit = widget.existingReview != null &&
            widget.existingReview!.rid.isNotEmpty;

        dynamic response;

        if (isEdit) {
          // Call update review endpoint
          response = await ApiService.updateReview(
            productId: widget.productId,
            reviewId: widget.existingReview!.rid,
            rating: _rating.toStringAsFixed(1),
            reviewM: combinedReview,
            images: _images,
            previousImages: previousImageUrls,
          );
        } else {
          // Call add review endpoint
          response = await ApiService.addReview(
            email: widget.email,
            productId: widget.productId,
            rating: _rating.toStringAsFixed(1),
            reviewT: _reviewTitleController.text,
            reviewM: _reviewMessageController.text,
            images: _images,
          );
        }

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        // Handle the response - check if it contains HTML errors first
        if (response is String &&
            response.contains('<div style="border:1px solid #990000')) {
          // Extract the JSON part from the response
          final jsonStart = response.lastIndexOf('{');
          final jsonEnd = response.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd != -1) {
            final jsonString = response.substring(jsonStart, jsonEnd + 1);
            try {
              response = json.decode(jsonString);
            } catch (e) {
              debugPrint('Error parsing response: $e');
            }
          }
        }

        // Check if the operation was successful
        if (response is Map &&
            (response['Suceess'] != null || response['success'] != null)) {
          await _showSuccessDialog(isEdit);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to submit review'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error in submitReview: $e');
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } else if (_rating == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _showSuccessDialog(bool isEdit) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated checkmark
                Lottie.asset(
                  'assets/images/Animation - 1744710217639.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
                SizedBox(height: 20),

                // Title
                Text(
                  isEdit ? 'Review Updated!' : 'Thank You!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),

                // Message
                Text(
                  isEdit
                      ? 'Your review has been updated successfully.'
                      : 'Your review has been submitted successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Close button
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Continue button
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(
                            context, true); // Pop review screen with result
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff101d42),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Key changes in AddReviewScreen - replace the build method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Add Review',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name Header (Compact)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: widget.productImage.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.productImage,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Icon(
                      Icons.image,
                      color: Colors.grey[400],
                      size: 50,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.productName,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Divider(color: Colors.grey[200]),
              SizedBox(height: 12),

              // Rating Section (Compact)
              Text(
                'How would you rate this product?',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 6),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = index + 1.0;
                        });
                      },
                      child: SizedBox(
                        width: 58,
                        height: 62,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              index < _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 36,
                              color: index < _rating
                                  ? Colors.transparent
                                  : Colors.grey[400],
                            ),
                            if (index < _rating)
                              Lottie.asset(
                                'assets/images/Animation - 1744698113138.json',
                                width: 62,
                                height: 62,
                                repeat: false,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: 18),

              // Review Title (Compact)
              Text(
                'Review Title',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueGrey.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _reviewTitleController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Summarize your experience',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),

              // Review Message (Compact)
              Text(
                'Your Review',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueGrey.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _reviewMessageController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share details about your experience',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your review';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 18),

              // Photo Upload Section (Compact)
              Text(
                'Add Photos (Optional)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Upload up to 5 photos',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // Previous images
                  ...previousImageUrls.map((url) => Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.broken_image, color: Colors.grey[400]),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 3,
                        right: 3,
                        child: GestureDetector(
                          onTap: () => setState(() => previousImageUrls.remove(url)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(3),
                            child: Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  )),

                  // New images
                  ..._images.map((image) => Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(image, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 3,
                        right: 3,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(image)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(3),
                            child: Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  )),

                  // Upload Button
                  if ((_images.length + previousImageUrls.length) < 5)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 22, color: Colors.grey[500]),
                            SizedBox(height: 3),
                            Text(
                              'Add',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: GestureDetector(
          onTapDown: _isSubmitting ? null : (_) => setState(() => _submitReviewScale = 0.95),
          onTapUp: _isSubmitting
              ? null
              : (_) {
            setState(() => _submitReviewScale = 1.0);
            _submitReview();
          },
          onTapCancel: _isSubmitting ? null : () => setState(() => _submitReviewScale = 1.0),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: _submitReviewScale),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 52,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xff101d42),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isSubmitting
                        ? []
                        : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'SUBMIT REVIEW',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewTitleController.dispose();
    _reviewMessageController.dispose();
    super.dispose();
  }
}

class _StarSparkleEffect extends StatefulWidget {
  @override
  __StarSparkleEffectState createState() => __StarSparkleEffectState();
}

class __StarSparkleEffectState extends State<_StarSparkleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(
              Icons.star_rounded,
              size: 36,
              color: Colors.amber.withOpacity(0.6),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
