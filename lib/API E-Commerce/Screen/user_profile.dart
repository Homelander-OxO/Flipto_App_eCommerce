import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/API%20E-Commerce/Model/profile_model.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  UserDetailsModel? latestUser;
  final GoogleModel? gUser;

  UserProfileScreen({Key? key, this.latestUser, this.gUser}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  double _scale = 1.0;
  final _formKey = GlobalKey<FormState>();
  bool _hasChanges = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _nameController = TextEditingController(
      text: widget.gUser != null
          ? widget.gUser!.name
          : widget.latestUser?.fullName ?? "",
    );
    _emailController = TextEditingController(
      text: widget.gUser != null
          ? widget.gUser!.email
          : widget.latestUser?.email ?? "",
    );

    _nameController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);

    _loadUserDetails();
    _animationController.forward();
  }

  void _onTextChanged() {
    final originalName = widget.gUser?.name ?? widget.latestUser?.fullName ?? "";
    final originalEmail = widget.gUser?.email ?? widget.latestUser?.email ?? "";

    final hasChanges = _nameController.text != originalName ||
        _emailController.text != originalEmail ||
        _imageChanged;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  bool _isLoading = false;
  String? _imagePath;

  Future<void> _loadUserDetails() async {
    final email = widget.gUser?.email ?? widget.latestUser?.email;
    if (email == null || email.isEmpty) return;

    final user = await ApiService().fetchUserDetails(email);
    if (user != null) {
      setState(() {
        widget.latestUser = user;
        _nameController.text = user.fullName;
        _emailController.text = user.email;
      });
    }
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildImageSourceSheet(),
    );

    if (source != null) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
          _imageChanged = true;
        });
        _pulseController.forward().then((_) => _pulseController.reverse());
        _onTextChanged();
      }
    }
  }

  Widget _buildImageSourceSheet() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Choose Photo',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildImageOption(
                        'Camera',
                        Icons.camera_alt_outlined,
                            () => Navigator.pop(context, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildImageOption(
                        'Gallery',
                        Icons.photo_library_outlined,
                            () => Navigator.pop(context, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageOption(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black87, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      File? imageFile;

      if (_imagePath != null) {
        imageFile = File(_imagePath!);
        final fileSize = await imageFile.length();

        if (fileSize > 2 * 1024 * 1024) {
          throw Exception('Image exceeds 2MB limit');
        }
      }

      await ApiService.updateUserProfileMultipart(
        fullName: _nameController.text,
        email: _emailController.text,
        user_id: widget.latestUser?.userId ?? widget.gUser?.email ?? '9',
        imageFile: imageFile,
      );

      final updatedUser = await ApiService().fetchUserDetails(_emailController.text);

      if (updatedUser == null) {
        throw Exception('Failed to fetch updated profile');
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.setUserDetails(updatedUser);

      setState(() {
        widget.latestUser = updatedUser;
        _imagePath = null;
        _imageChanged = false;
        _hasChanges = false;
      });

      _showSuccessSnackBar();
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'Profile updated successfully',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.replaceAll('Exception: ', ''),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final googleUserData = cartProvider.googleProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Profile",
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: () {
                setState(() {
                  _nameController.text = widget.gUser?.name ?? widget.latestUser?.fullName ?? "";
                  _emailController.text = widget.gUser?.email ?? widget.latestUser?.email ?? "";
                  _imagePath = null;
                  _imageChanged = false;
                  _hasChanges = false;
                });
              },
              child: Text(
                'Reset',
                style: GoogleFonts.inter(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Profile Image Section
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.06),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Colors.grey[100],
                                              radius: 56,
                                              backgroundImage: _imagePath != null
                                                  ? FileImage(File(_imagePath!))
                                                  : googleUserData?.image != null
                                                  ? NetworkImage(googleUserData!.image)
                                                  : widget.latestUser?.image != null &&
                                                  widget.latestUser!.image.isNotEmpty
                                                  ? NetworkImage(widget.latestUser!.image)
                                                  : const AssetImage('assets/images/profile.png') as ImageProvider,
                                            ),
                                            if (_isLoading)
                                              AnimatedBuilder(
                                                animation: _shimmerAnimation,
                                                builder: (context, child) {
                                                  return Container(
                                                    width: 112,
                                                    height: 112,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: LinearGradient(
                                                        begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
                                                        end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.white.withOpacity(0.3),
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Name Display
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : "Your Name",
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            _emailController.text.isNotEmpty
                                ? _emailController.text
                                : "your.email@example.com",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),

                          if (_hasChanges) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 14, color: Colors.amber[800]),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Unsaved changes',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 40),

                          // Form Fields
                          _buildTextField(
                            "Full Name",
                            _nameController,
                            Icons.person_outline,
                            maxLength: 50,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              if (value.trim().length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          _buildTextField(
                            "Email Address",
                            _emailController,
                            Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),

      // Save Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTapDown: _isLoading || !_hasChanges ? null : (_) => setState(() => _scale = 0.96),
          onTapUp: _isLoading || !_hasChanges
              ? null
              : (_) {
            setState(() => _scale = 1.0);
            _updateProfile();
          },
          onTapCancel: _isLoading || !_hasChanges ? null : () => setState(() => _scale = 1.0),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: _scale),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? Colors.grey[300]
                        : _hasChanges
                        ? Colors.black87
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    _hasChanges ? 'Save Changes' : 'No Changes',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _hasChanges ? Colors.white : Colors.grey[600],
                      letterSpacing: 0.1
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

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        int? maxLength,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          onTap: () => HapticFeedback.selectionClick(),
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1
          ),
          cursorOpacityAnimates: true,
          cursorRadius: Radius.circular(2),
          cursorWidth: 1.7,
          cursorColor: Color(0xFF101D42),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black45, width: 1.3),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
        ),
      ],
    );
  }
}