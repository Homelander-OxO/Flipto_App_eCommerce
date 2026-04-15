import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/screens/history.dart';
import 'package:flutter_app/Utilities/bottom_navigation.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/gradient_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart'; // Import the audio player package

class OrderConfirmationScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> addressDetails; // Make this required


  const OrderConfirmationScreen({Key? key, required this.orderId, required this.addressDetails})
      : super(key: key);

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with TickerProviderStateMixin {
  bool _showUserData = false;
  bool _moveUp = false;

  late DateTime _orderDate;
  late DateTime _expectedDelivery;

  // ✅ Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _orderDate = DateTime.now();
    _expectedDelivery = _orderDate.add(const Duration(days: 4));

    // ✅ Play sound when the Lottie animation starts
    Future.delayed(const Duration(milliseconds: 550), () {
      _playOrderPlacedSound();
    });

    // ✅ Start animations AFTER Lottie finishes
    Future.delayed(const Duration(milliseconds: 1200), () {
      setState(() {
        _moveUp = true; // Move "Order Placed" up
      });

      Future.delayed(const Duration(milliseconds: 650), () {
        setState(() {
          _showUserData = true; // Show user details
        });
      });
    });
  }

  // ✅ Play the "order placed" sound
  void _playOrderPlacedSound() async {
    await _audioPlayer.play(AssetSource('sound/success.mp3'));
    await _audioPlayer.setPlaybackRate(0.80);
   }

  @override
  void dispose() {
    // ✅ Dispose the audio player to release resources
    _audioPlayer.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String getShippingAddress() {
    final user = Provider.of<CartProvider>(context, listen: false).userDetails;
    return '${widget.addressDetails['apartmentNo']}, '
        '${widget.addressDetails['street']}, '
        '${widget.addressDetails['area']}, '
        '${widget.addressDetails['city']} - '
        '${widget.addressDetails['pincode']}';
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        cartProvider
            .fetchCartItems(cartProvider.email ?? cartProvider.useremail ?? '');
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
              (route) => false,
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          centerTitle: true,
          title: Text(
            'Order Placed',
            style: GoogleFonts.raleway(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 14, 50),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Order Placed Section (Initially Center → Moves Up)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(
                        0,
                        _moveUp ? -20 : 180,
                        // Initial position is 80 pixels below center
                        0),
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            return (Lottie.asset(
                              'assets/images/Animation - 1741860923092.json',
                              width: 170,
                              height: 170,
                              repeat: false,
                            ) as Widget)
                                .animate()
                                .fadeIn(duration: 800.ms);
                          },
                        ),

                        // ✅ Order Placed Section
                        Text(
                          'Order Placed!',
                          style: GoogleFonts.raleway(
                            letterSpacing: 0.2,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                        const SizedBox(height: 2),

                        Text(
                          'Your order has been placed successfully.',
                          style: GoogleFonts.raleway(
                              letterSpacing: 0.1,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600]),
                        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                      ],
                    ),
                  ),

                  // ✅ User Details Section (Appears Smoothly Below)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _showUserData ? 1.0 : 0.0,
                    child: Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          padding: const EdgeInsets.all(12), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            // Slightly rounded
                            border: Border.all(color: Colors.blueGrey[50]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(Icons.receipt_long, 'Order ID',
                                  widget.orderId),
                              _buildDetailRow(Icons.date_range, 'Order Date',
                                  formatDate(_orderDate)),
                              _buildDetailRow(Icons.person, 'Username',
                                  cartProvider.username ?? ''),
                              _buildDetailRow(
                                Icons.location_on,
                                'Shipping Address',
                                getShippingAddress(),

                              ),
                              _buildDetailRow(
                                  Icons.local_shipping,
                                  'Expected Delivery',
                                  formatDate(_expectedDelivery)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20), // ✅ Reduced spacing

                        // ✅ Continue Shopping Button (Appears Together)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: GradientButton(
                            text: 'Continue Shopping',
                            onPressed: () async {
                              cartProvider.fetchCartItems(cartProvider.email ??
                                  cartProvider.useremail ??
                                  '');
                              await Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Navigation()),
                                    (route) => false,
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 5,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  colors: [Colors.grey[50]!, Colors.grey[300]!],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter, // Disabled state
                                )),
                            child: ElevatedButton(
                              onPressed: () async {
                                cartProvider.fetchCartItems(
                                    cartProvider.email ??
                                        cartProvider.useremail ??
                                        '');
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShippingHistoryScreen(
                                      email: cartProvider.useremail ??
                                          cartProvider.email ??
                                          '',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: Colors.transparent,
                                // Allows gradient to show
                                disabledBackgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'My Orders',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Helper widget for User Details
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade700,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                // Value - Single line with text overflow handling
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }}