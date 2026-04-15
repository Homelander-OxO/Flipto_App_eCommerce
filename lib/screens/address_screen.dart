import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/screens/add_address.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

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

    _fetchAddresses();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    await Future.delayed(
        const Duration(milliseconds: 500)); // Simulate network delay

    Provider.of<CartProvider>(context, listen: false)
        .fetchAddresses(cartProvider.email ?? cartProvider.useremail ?? '');

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<CartProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        for (var card in List<_AddressCardState>.from(_openDropdownCards)) {
          card.closeMenu();
        }
        _openDropdownCards.clear();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFE),
        body: GestureDetector(
          onTap: () {
            for (var card in List<_AddressCardState>.from(_openDropdownCards)) {
              card.closeMenu();
            }
            _openDropdownCards.clear();
          },
          child: CustomScrollView(
            slivers: [
              // Compact App Bar
              SliverAppBar(
                expandedHeight: 100,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Colors.black87,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Color(0xFFF8FAFE),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'My Addresses',
                                  style: GoogleFonts.manrope(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manage your delivery locations',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
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

              // Content
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Compact Add New Address Button
                        Container(
                          margin: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                          child: Material(
                            elevation: 0,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () async {
                                for (var card in List<_AddressCardState>.from(
                                    _openDropdownCards)) {
                                  card.closeMenu();
                                }
                                _openDropdownCards.clear();
                                HapticFeedback.mediumImpact();
                                final isSuccess = await Navigator.push(
                                  context,
                                  CustomCupertinoPageRoute(
                                    builder: (context) =>
                                        const ShippingDetailsScreen(
                                      name: '',
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
                                if (isSuccess == true) _fetchAddresses();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF2D3748),
                                      Color(0xFF1A202C),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2D3748)
                                          .withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Add New Address',
                                      style: GoogleFonts.manrope(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Address List or Empty State
                        if (_isLoading)
                          const SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2D3748),
                                ),
                              ),
                            ),
                          )
                        else if (addressProvider.addresses.isEmpty)
                          _buildEmptyState()
                        else
                          _buildAddressList(addressProvider, cartProvider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Lottie.asset(
                  'assets/images/Animation - 1744700226419.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  "No address yet",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Add your first delivery address to get started with seamless shopping experience.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAddressList(
      CartProvider addressProvider, CartProvider cartProvider) {
    return AnimatedList(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      initialItemCount: addressProvider.addresses.length,
      itemBuilder: (context, index, animation) {
        if (index >= addressProvider.addresses.length) return const SizedBox();

        final address = addressProvider.addresses[index];
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: EnhancedAddressCard(
              name: cartProvider.userDetails?.fullName ??
                  cartProvider.googleProfile?.name ??
                  'NA',
              address:
                  "${address.apartmentNo}, ${address.street}, ${address.area}, ${address.city} - ${address.pincode}",
              phone: address.contact,
              email: cartProvider.email ?? '',
              listIndex: index,
              addressKey: address.indexKey,
              isDefault: address.indexKey == cartProvider.defaultAddressKey,
              onEdit: () async {
                HapticFeedback.mediumImpact();

                // Close any open dropdown menus before navigating
                for (var card
                    in List<_AddressCardState>.from(_openDropdownCards)) {
                  card.closeMenu();
                }
                _openDropdownCards.clear();

                final isSuccess = await Navigator.push(
                  context,
                  CustomCupertinoPageRoute(
                    builder: (context) => ShippingDetailsScreen(
                      name: cartProvider.userDetails?.fullName ?? '',
                      contact: address.contact,
                      street: address.street,
                      area: address.area,
                      apartmentNumber: address.apartmentNo,
                      city: address.city,
                      postcode: address.pincode,
                      index: index,
                      isEditing: true,
                    ),
                  ),
                );
                if (isSuccess == true) _fetchAddresses();
              },
            ),
          ),
        );
      },
    );
  }
}

final List<_AddressCardState> _openDropdownCards = [];

class EnhancedAddressCard extends StatefulWidget {
  final String name;
  final String address;
  final String phone;
  final int listIndex; // Position in the addresses list
  final String email;
  final bool isDefault;
  final VoidCallback onEdit;
  final String addressKey; // The API index key ("0", "1", etc.)

  const EnhancedAddressCard({
    super.key,
    required this.name,
    required this.address,
    required this.phone,
    required this.listIndex,
    required this.email,
    required this.isDefault,
    required this.onEdit,
    required this.addressKey,
  });

  @override
  _AddressCardState createState() => _AddressCardState();
}

class _AddressCardState extends State<EnhancedAddressCard>
    with TickerProviderStateMixin {
  bool _isMenuVisible = false;
  late AnimationController _menuController;
  late AnimationController _selectionController;
  late Animation<double> _menuAnimation;
  late Animation<Offset> _menuSlideAnimation;
  late Animation<double> _selectionAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutCubic,
    );
    _menuSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(_menuAnimation);

    _selectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _selectionController,
      curve: Curves.easeInOut,
    ));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _closeAllMenus();
    });
  }

  void _closeAllMenus() {
    for (var card in List<_AddressCardState>.from(_openDropdownCards)) {
      card.closeMenu();
    }
    _openDropdownCards.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _closeAllMenus();
  }

  @override
  void dispose() {
    _menuController.dispose();
    _selectionController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    HapticFeedback.lightImpact();
    setState(() {
      _isMenuVisible = !_isMenuVisible;
      if (_isMenuVisible) {
        _openDropdownCards.add(this);
        _menuController.forward();
      } else {
        _openDropdownCards.remove(this);
        _menuController.reverse();
      }
    });
  }

  void closeMenu() {
    if (_isMenuVisible) {
      setState(() {
        _isMenuVisible = false;
        _menuController.reverse();
      });
      _openDropdownCards.remove(this);
    }
  }

  void _handleMenuAction(String value) async {
    HapticFeedback.mediumImpact();
    if (value == 'edit') {
      _toggleMenu();
      widget.onEdit();
    } else if (value == 'delete') {
      _toggleMenu();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Address',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this address?',
            style: GoogleFonts.manrope(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.manrope(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final addressProvider =
            Provider.of<CartProvider>(context, listen: false);
        bool success = await addressProvider.removeAddress(
          addressProvider.email ?? addressProvider.useremail ?? '',
          widget.listIndex,
        );

        if (success) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Address deleted successfully",
                style: GoogleFonts.manrope(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              backgroundColor: Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: Duration(milliseconds: 1500),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Failed to delete address",
                style: GoogleFonts.manrope(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: Duration(milliseconds: 1500),
            ),
          );
        }
      }
    }
  }

  void _handleSetDefault() async {
    if (_isMenuVisible) {
      _toggleMenu();
    }
    if (widget.isDefault) {
      HapticFeedback.lightImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    _selectionController.forward().then((_) {
      _selectionController.reverse();
    });

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final email = cartProvider.email ?? cartProvider.useremail ?? '';

    bool success =
        await cartProvider.setDefaultAddress(email, widget.listIndex);

    if (success) {
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Default address set successfully",
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1),
          ),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        for (var card in List<_AddressCardState>.from(_openDropdownCards)) {
          if (card != this) {
            card.closeMenu();
          }
        }
        _handleSetDefault();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_selectionAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: widget.isDefault
                          ? Color.lerp(
                              const Color(0xFF2D3748).withOpacity(0.3),
                              const Color(0xFF10B981),
                              _selectionAnimation.value,
                            )!
                          : Colors.grey.withOpacity(0.1),
                      width: widget.isDefault ? 1.8 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isDefault
                            ? Color.lerp(
                                Colors.black.withOpacity(0.04),
                                const Color(0xFF10B981).withOpacity(0.2),
                                _selectionAnimation.value,
                              )!
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 12 + (_selectionAnimation.value * 8),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (widget.isDefault)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: widget.isDefault
                                              ? Color.lerp(
                                                  const Color(0xFF2D3748)
                                                      .withOpacity(0.1),
                                                  const Color(0xFF10B981)
                                                      .withOpacity(0.15),
                                                  _selectionAnimation.value,
                                                )
                                              : const Color(0xFF2D3748)
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.location_on_rounded,
                                          size: 18,
                                          color: widget.isDefault
                                              ? Color.lerp(
                                                  const Color(0xFF2D3748),
                                                  const Color(0xFF10B981),
                                                  _selectionAnimation.value,
                                                )
                                              : const Color(0xFF2D3748),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  widget.name,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black87,
                                                    letterSpacing: -0.1,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (widget.isDefault)
                                                  ScaleTransition(
                                                    scale: Tween<double>(
                                                      begin: 0.8,
                                                      end: 0.85,
                                                    ).animate(
                                                        _selectionAnimation),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xFF10B981),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      child: Text(
                                                        'Default',
                                                        style:
                                                            GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          letterSpacing: 0.1,
                                                          color: Colors.white,
                                                        ),
                                                      ),
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
                                IconButton(
                                  icon: Icon(
                                    Icons.more_vert_rounded,
                                    size: 18,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: _toggleMenu,
                                  padding: const EdgeInsets.all(5),
                                  constraints: const BoxConstraints(
                                    minWidth: 30,
                                    minHeight: 30,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.address,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                color: Colors.black.withOpacity(0.8),
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.1
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  size: 15,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.phone,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_isMenuVisible)
                        Positioned(
                          right: 10,
                          top: 50,
                          child: FadeTransition(
                            opacity: _menuAnimation,
                            child: SlideTransition(
                              position: _menuSlideAnimation,
                              child: ScaleTransition(
                                scale: _menuAnimation,
                                child: Material(
                                  elevation: 12,
                                  borderRadius: BorderRadius.circular(12),
                                  shadowColor: Colors.black.withOpacity(0.15),
                                  child: Container(
                                    width: 115,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Edit option
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () =>
                                                _handleMenuAction('edit'),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(12),
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 9,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit_outlined,
                                                    size: 15,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Edit',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 0.5,
                                          color: Colors.grey[200],
                                        ),
                                        // Set as Default option
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              _toggleMenu();
                                              _handleSetDefault();
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 9,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.home_outlined,
                                                    size: 15,
                                                    color: widget.isDefault
                                                        ? Colors.grey[400]
                                                        : const Color(
                                                            0xFF2D3748),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Default',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: widget.isDefault
                                                          ? Colors.grey[400]
                                                          : const Color(
                                                              0xFF2D3748),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 0.5,
                                          color: Colors.grey[200],
                                        ),
                                        // Delete option
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () =>
                                                _handleMenuAction('delete'),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              bottom: Radius.circular(12),
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 9,
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    size: 15,
                                                    color: Colors.red[400],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Delete',
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.red[400],
                                                    ),
                                                  ),
                                                ],
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
                          ),
                        ),
                    ],
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
