import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/config/app_config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:provider/provider.dart';

class ShippingDetailsScreen extends StatefulWidget {
  final String name;
  final String contact;
  final String street;
  final String area;
  final String apartmentNumber;
  final String city;
  final String postcode;
  final int? index;
  final bool isEditing;

  const ShippingDetailsScreen({
    super.key,
    required this.contact,
    required this.name,
    required this.street,
    required this.area,
    required this.apartmentNumber,
    required this.city,
    required this.postcode,
    this.index,
    this.isEditing = false,
  });

  @override
  _ShippingDetailsScreenState createState() => _ShippingDetailsScreenState();
}

class _ShippingDetailsScreenState extends State<ShippingDetailsScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditing;
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late AnimationController _fieldAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _areaController;
  late TextEditingController _apartmentNumberController;
  late TextEditingController _cityController;
  late TextEditingController _postcodeController;

  List<String> _citySuggestions = [];
  Timer? _debounce;
  bool _isLoading = false;
  final FocusNode _cityFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isEditing;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fieldAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _fieldAnimationController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
          parent: _buttonAnimationController, curve: Curves.elasticOut),
    );

    _phoneController = TextEditingController(text: widget.contact);
    _streetController = TextEditingController(text: widget.street);
    _areaController = TextEditingController(text: widget.area);
    _apartmentNumberController =
        TextEditingController(text: widget.apartmentNumber);
    _cityController = TextEditingController(text: widget.city);
    _postcodeController = TextEditingController(text: widget.postcode);

    _animationController.forward();
    _fieldAnimationController.forward();
    _buttonAnimationController.forward();

    _cityFocusNode.addListener(() {
      if (!_cityFocusNode.hasFocus && _citySuggestions.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _citySuggestions.clear());
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animationController.dispose();
    _buttonAnimationController.dispose();
    _fieldAnimationController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _apartmentNumberController.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCitySuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => _citySuggestions = []);
      return;
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final response = await http.post(
          Uri.parse('${AppConfig.baseUrl}/Apis/cities'),
          // Uri.parse('http://10.30.226.167/Apis/cities'),
          body: {'query': query},
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            _citySuggestions = data.cast<String>();
          });
        }
      } catch (e) {
        print('Error fetching city suggestions: $e');
      }
    });
  }

  void _submitForm() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final addressProvider = Provider.of<CartProvider>(context, listen: false);
    final email = cartProvider.email ?? cartProvider.useremail ?? '';

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        HapticFeedback.lightImpact();
      }

      bool success;
      String message;

      try {
        if (_isEditing && widget.index != null) {
          final response = await ApiService.updateAddress(
            email: email,
            index: widget.index!,
            contact: _phoneController.text,
            apartmentNo: _apartmentNumberController.text,
            street: _streetController.text,
            area: _areaController.text,
            city: _cityController.text,
            pincode: _postcodeController.text,
          );

          success = response.containsKey("Success") ||
              response.containsKey("success");
          message = success
              ? "Address updated successfully!"
              : "Failed to update address";
        } else {
          final response = await ApiService.addAddress(
            email: email,
            contact: _phoneController.text,
            apartmentNo: _apartmentNumberController.text,
            street: _streetController.text,
            area: _areaController.text,
            city: _cityController.text,
            pincode: _postcodeController.text,
          );

          success = (response.containsKey("success") &&
                  response["success"] == "Address added successfully") ||
              (response.containsKey("Success") &&
                  response["Success"] == "Address added successfully");
          message = success
              ? "Address added successfully!"
              : response["message"] ?? "Failed to add address";
        }

        _showCustomSnackBar(message, success);

        if (success) {
          await addressProvider.fetchAddresses(email);
          Future.delayed(const Duration(milliseconds: 1200), () {
            Navigator.pop(context, true);
          });
        }
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      _buttonAnimationController.reset();
      _buttonAnimationController.forward();
    }
  }

  void _showCustomSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSuccess ? 'Success!' : 'Oops!',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      message,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 8,
      ),
    );
  }

  Widget _buildAnimatedFormField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int index = 0,
  }) {
    return AnimatedBuilder(
      animation: _fieldAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * (index + 1) * 0.1),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            icon,
                            size: 14,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: controller,
                      keyboardType: keyboardType,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111827),
                          letterSpacing: 0.1),
                      cursorOpacityAnimates: true,
                      cursorRadius: Radius.circular(2),
                      cursorWidth: 1.7,
                      cursorColor: Color(0xFF101D42),
                      decoration: InputDecoration(
                        hintText: 'Enter your $label',
                        hintStyle: GoogleFonts.manrope(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: const Color(0xFFE5E7EB).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'This field is required'
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCityField() {
    return AnimatedBuilder(
      animation: _fieldAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.5),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.location_city_rounded,
                            size: 14,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'City',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _cityController,
                      focusNode: _cityFocusNode,
                      keyboardType: TextInputType.text,
                      onChanged: _fetchCitySuggestions,
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111827),
                          letterSpacing: 0.1),
                      decoration: InputDecoration(
                        suffixIcon: Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ),
                        hintText: 'Search and select your city',
                        hintStyle: GoogleFonts.manrope(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: const Color(0xFFE5E7EB).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please select a city'
                          : null,
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _citySuggestions.isNotEmpty ? null : 0,
                    child: _citySuggestions.isNotEmpty
                        ? Container(
                            margin: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _citySuggestions.length,
                              itemBuilder: (context, index) {
                                final city = _citySuggestions[index];
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() {
                                        _cityController.text = city;
                                        _citySuggestions.clear();
                                      });
                                      _cityFocusNode.unfocus();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.location_on_rounded,
                                              color: Color(0xFF3B82F6),
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              city,
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF374151),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8),
          child: Material(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Color(0xFF374151),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        title: Container(
          margin: const EdgeInsets.only(top: 8),
          child: Text(
            _isEditing ? 'Edit Address' : 'Add New Address',
            style: GoogleFonts.manrope(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF3B82F6),
                        const Color(0xFF1D4ED8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shipping Information',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Provide accurate delivery details',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildAnimatedFormField(
                        _phoneController,
                        'Contact Number',
                        Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        index: 0,
                      ),
                      _buildAnimatedFormField(
                        _apartmentNumberController,
                        'House/Apartment No.',
                        Icons.home_rounded,
                        index: 1,
                      ),
                      _buildAnimatedFormField(
                        _streetController,
                        'Street Address',
                        Icons.location_on_rounded,
                        index: 2,
                      ),
                      _buildAnimatedFormField(
                        _areaController,
                        'Area/Colony',
                        Icons.map_rounded,
                        index: 3,
                      ),
                      _buildCityField(),
                      _buildAnimatedFormField(
                        _postcodeController,
                        'Postal Code',
                        Icons.markunread_mailbox_rounded,
                        keyboardType: TextInputType.number,
                        index: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isLoading ? 0.95 : _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 32,
                    offset: const Offset(0, -8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isLoading
                          ? [
                              const Color(0xFF9CA3AF),
                              const Color(0xFF6B7280),
                            ]
                          : [
                              const Color(0xFF3B82F6),
                              const Color(0xFF1D4ED8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_isLoading
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF3B82F6))
                            .withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoading ? null : _submitForm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isEditing ? 'Updating...' : 'Saving...',
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _isEditing
                                            ? Icons.update_rounded
                                            : Icons.save_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isEditing
                                          ? 'Update Address'
                                          : 'Save Address',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
