import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/models/profile_model.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/custom_widgets/gradient_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/Utilities/bottom_navigation.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({Key? key, required this.email})
      : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (index) => FocusNode());
  bool _isLoading = false;

  void _verifyOtp() async {
    final otp = _otpControllers.map((controller) => controller.text).join();
    // final otp = _otpControllers.text;
    final email = widget.email;

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete OTP.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Navigation()),
        (route) => false,
      );
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.verifyOtp(email, otp);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);

        UserDetailsModel? userDetails =
            await ApiService().fetchUserDetails(email);

        if (userDetails != null) {
          cartProvider.setUserDetails(userDetails);

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool('isLoggedIn', true);
          prefs.setString('full_name', userDetails.fullName);
          prefs.setString('email', userDetails.email);
          prefs.setString('contact', userDetails.contact ?? '');
          prefs.setString('address', userDetails.address ?? '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        await cartProvider.fetchCartItems(email);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP verification failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/otp.png',
                scale: 1,
              ),
              // Illustration
              // Container(
              //   width: 200,
              //   height: 200,
              //   decoration: BoxDecoration(
              //     color: Color(0xFFF5F7FF),
              //     borderRadius: BorderRadius.circular(100),
              //   ),
              //   child: Icon(
              //     Icons.verified_user_rounded,
              //     size: 80,
              //     color: Color(0xFF101D42),
              //   ),
              // ),
              //
              // const SizedBox(height: 32),

              // Title
              Text(
                "Verify OTP",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101D42),
                  letterSpacing: -0.1
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                "Enter the 6-digit code sent to\n${widget.email}",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                    letterSpacing: 0.1

                ),
              ),

              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      // textAlignVertical: TextAlignVertical.center, // Center vertically
                      cursorColor: Color(0xFF101D42),
                      cursorRadius: Radius.circular(8),
                      cursorOpacityAnimates: true,
                      cursorWidth: 1.7,
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      textAlign: TextAlign.center,
                      // Center horizontally
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 1,
                      style: GoogleFonts.poppins(
                        color: Color(0xFF101D42),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFF101D42),
                            width: 1.5,
                          ),
                        ),
                        contentPadding:
                            EdgeInsets.only(left: 3), // Remove default padding
                      ),
                      onChanged: (value) {
                        if (value.length == 1 && index < 5) {
                          FocusScope.of(context)
                              .requestFocus(_otpFocusNodes[index + 1]);
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(context)
                              .requestFocus(_otpFocusNodes[index - 1]);
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              // Verify Button
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.062,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF101D42),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify OTP',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 0.5
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: GoogleFonts.inter(
                      color: Colors.grey[600],
                      fontSize: 14,
                      letterSpacing: -0.1
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Resend OTP logic
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Resend OTP',
                      style: GoogleFonts.inter(
                        color: Color(0xFF101D42),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                          letterSpacing: -0.1

                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Timer (optional)
              Text(
                "Code expires in 9:59",
                style: GoogleFonts.inter(
                  color: Colors.grey[500],
                  fontSize: 13,
                    letterSpacing: -0.1

                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
