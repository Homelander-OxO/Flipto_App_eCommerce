import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/profile_model.dart';
import 'package:flutter_app/screens/address_screen.dart';
import 'package:flutter_app/screens/history.dart';
import 'package:flutter_app/screens/ratings_reviews.dart';
import 'package:flutter_app/screens/rcdm.dart';
import 'package:flutter_app/screens/user_profile.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/ai.dart';
import 'package:flutter_app/screens/chat_bot.dart';

import 'package:flutter_app/Utilities/bottom_navigation.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/config/app_config.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/custom_widgets/loading.dart';
import 'package:flutter_app/Authentication/login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isProfileLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _refreshUserDataIfNeeded();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      if (cartProvider.googleProfile != null) {
        await cartProvider.signOutGoogle();
        print('Google logged out');
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      cartProvider.clearCart();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const Login(email: '', username: '')),
          (route) => false,
        );
      }
      cartProvider.clearUser();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully signed out!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      print("Error logging out: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error signing out. Please try again.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _refreshUserDataIfNeeded() async {
    setState(() => _isProfileLoading = true);

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final email =
        cartProvider.userDetails?.email ?? cartProvider.googleProfile?.email;

    if (email == null || email.isEmpty) {
      setState(() => _isProfileLoading = false);
      return;
    }

    final updatedUser = await ApiService().fetchUserDetails(email);
    if (updatedUser != null) {
      cartProvider.setUserDetails(updatedUser);
    }

    setState(() => _isProfileLoading = false);

    // Start animations after loading
    _fadeController.forward();
    _slideController.forward();
  }

  void _showLogoutConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [

                  // const SizedBox(height: 20),
                  Text(
                    'Log Out',
                    style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                        letterSpacing: -0.2
                    ),
                  ),
                  Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text(
                'Are you sure you want to sign out of your account?',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.1
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                            letterSpacing: -0.1

                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Log Out',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final userData = cartProvider.userDetails;
    final googleUserData = cartProvider.googleProfile;
    final uEmail = cartProvider.email ?? cartProvider.useremail;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: _isProfileLoading
          ? const Center(
              child: SimpleCircularLoader(
                color: Colors.black87,
                strokeWidth: 2,
              ),
            )
          : Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Modern header with glassmorphism effect
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      expandedHeight: 150,
                      stretch: true,
                      pinned: true,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [StretchMode.zoomBackground],
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black87,
                                Colors.black.withOpacity(0.8),
                                Colors.grey.shade900,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: _buildProfileHeader(
                                    userData, googleUserData),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Content with staggered animations
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 16, bottom: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildQuickActions(cartProvider, uEmail),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildAccountSection(
                                  userData, googleUserData),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildSupportSection(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildModernLogoutButton(),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),

                // Modern loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Signing out...',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildProfileHeader(userData, googleUserData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 34,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: _getProfileImage(userData, googleUserData),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(userData, googleUserData),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getDisplayEmail(userData, googleUserData),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Premium Member',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
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

  Widget _buildQuickActions(cartProvider, uEmail) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Orders',
                  subtitle: 'View history',
                  color: Colors.blue.shade600,
                  onTap: () {
                    final email =
                        cartProvider.email ?? cartProvider.useremail ?? '';
                    Navigator.push(
                      context,
                      CustomCupertinoPageRoute(
                        builder: (context) =>
                            ShippingHistoryScreen(email: email),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  subtitle: 'Manage',
                  color: Colors.green.shade600,
                  onTap: () {
                    Navigator.push(
                      context,
                      CustomCupertinoPageRoute(
                        builder: (context) => AddressScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.star_outline_rounded,
                  title: 'Reviews',
                  subtitle: 'My ratings',
                  color: Colors.orange.shade600,
                  onTap: () {
                    Navigator.push(
                      context,
                      CustomCupertinoPageRoute(
                        builder: (context) =>
                            ReviewsScreen(email: uEmail ?? ''),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.1),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(userData, googleUserData) {
    return _buildModernSection(
      title: 'Account',
      children: [
        _buildModernOption(
          icon: Icons.person_outline_rounded,
          title: 'Profile Settings',
          subtitle: 'Update your information',
          onTap: () {
            Navigator.push(
              context,
              CustomCupertinoPageRoute(
                builder: (context) => UserProfileScreen(
                  latestUser: userData,
                  gUser: googleUserData,
                ),
              ),
            );
          },
        ),
        _buildModernOption(
          icon: Icons.security_rounded,
          title: 'Privacy & Security',
          subtitle: 'Manage your privacy settings',
          onTap: () {},
        ),
        _buildModernOption(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Customize your alerts',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return _buildModernSection(
      title: 'Support',
      children: [
        _buildModernOption(
          icon: Icons.help_outline_rounded,
          title: 'Help Center',
          subtitle: 'Get help and support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecommendationDemoScreen(),
              ),
            );
          },
        ),
        _buildModernOption(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Contact Us',
          subtitle: 'Chat with our support team',
          onTap: () {
            Navigator.push(
              context,
              CustomCupertinoPageRoute(
                builder: (context) => ChatScreen(),
              ),
            );
          },
        ),
        _buildModernOption(
          icon: Icons.info_outline_rounded,
          title: 'About',
          subtitle: 'App version 1.0.0',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildModernSection(
      {required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildModernOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                          letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.1),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernLogoutButton() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: _showLogoutConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              shadowColor: Colors.red.withOpacity(0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // const Icon(Icons.logout_rounded, size: 18),
                // const SizedBox(width: 10),
                Text(
                  'Log Out',
                  style: GoogleFonts.manrope(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    wordSpacing: 0.5
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods
  ImageProvider _getProfileImage(userData, googleUserData) {
    if (googleUserData?.image != null &&
        googleUserData!.image.trim().isNotEmpty) {
      return NetworkImage(googleUserData.image);
    } else if (userData?.image != null && userData!.image.trim().isNotEmpty) {
      return NetworkImage(userData.image);
    } else {
      return const AssetImage('assets/images/profile.png');
    }
  }

  String _getDisplayName(userData, googleUserData) {
    if (userData != null) {
      return userData.fullName ?? 'User';
    } else if (googleUserData != null) {
      return googleUserData.name ?? 'User';
    }
    return 'User';
  }

  String _getDisplayEmail(userData, googleUserData) {
    if (userData != null) {
      return userData.email ?? '';
    } else if (googleUserData != null) {
      return googleUserData.email ?? '';
    }
    return '';
  }
}
