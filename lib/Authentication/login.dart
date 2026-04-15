import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Authentication/facebook_login.dart';
import 'package:flutter_app/Authentication/verify_otp.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/Authentication/signup.dart';

class Login extends StatefulWidget {
  final String username;
  final String email;

  const Login({super.key, required this.username, required this.email});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool isVisible = false;
  bool _isLoading = false;
  bool _isOtpSent = false;
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    username.text = widget.username;
    email.text = widget.email;
  }

  void _handleGoogleSignIn() async {
    try {
      await Provider.of<CartProvider>(context, listen: false)
          .signInWithGoogle(context);
    } catch (e) {
      print("Error in login screen: $e");
    }
  }

  Future<void> _sendOtp() async {
    final emailText = email.text;

    if (emailText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

     bool isOtpSent = await ApiService.sendOtp(emailText);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (isOtpSent) {
      // if (emailText.isNotEmpty) {
        Navigator.push(
          context,
          CustomCupertinoPageRoute(
            builder: (context) => OtpVerificationScreen(email: emailText),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send OTP. Please try again.'),
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
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color(0xFFF8F9FF),
                ],
              ),
            ),
          ),

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/mail.png',
                    scale: 1,
                  ),
                  // Logo/Icon
                  // Center(
                  //   child: Container(
                  //     width: 80,
                  //     height: 80,
                  //     decoration: BoxDecoration(
                  //       color: Colors.white,
                  //       borderRadius: BorderRadius.circular(20),
                  //       boxShadow: [
                  //         BoxShadow(
                  //           color: Colors.black.withOpacity(0.05),
                  //           blurRadius: 20,
                  //           spreadRadius: 2,
                  //         ),
                  //       ],
                  //     ),
                  //     child: Icon(
                  //       Icons.lock_outline_rounded,
                  //       size: 40,
                  //       color: Color(0xFF101D42),
                  //     ),
                  //   ),
                  // ),
                  //
                  // const SizedBox(height: 32),

                  // Welcome text
                  Text(
                    "Welcome Back",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101D42),
                      letterSpacing: -0.2
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Login to your account",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                        letterSpacing: -0.1
                    ),
                    textAlign: TextAlign.center,
                  ),

                   SizedBox(height: MediaQuery.of(context).size.height * 0.045),
                  // const SizedBox(height: 35),

                  // Email field
                  Container(
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
                      controller: email,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Email Address",
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[500],
                          fontSize: 15,
                          letterSpacing: -0.1,
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                      cursorOpacityAnimates: true,
                      cursorRadius: Radius.circular(2),
                      cursorWidth: 1.7,
                      cursorColor: Color(0xFF101D42),
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.05
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Get OTP button
                  SizedBox(
                    // height: 50,
                    height: MediaQuery.of(context).size.height * 0.062,
                    child: ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF101D42),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
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
                              "Get OTP",
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Forgot password
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: TextButton(
                  //     onPressed: () {
                  //       Navigator.push(
                  //         context,
                  //         CustomCupertinoPageRoute(
                  //           builder: (context) => Navigation(),
                  //         ),
                  //       );
                  //     },
                  //     style: TextButton.styleFrom(
                  //       padding: EdgeInsets.zero,
                  //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  //     ),
                  //     child: Text(
                  //       'Forgot Password?',
                  //       style: GoogleFonts.inter(
                  //         color: Color(0xFF101D42),
                  //         fontSize: 14,
                  //         fontWeight: FontWeight.w500,
                  //       ),
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Or continue with",
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 14,
                            letterSpacing: -0.1
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Social login buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google
                      InkWell(
                        onTap: _handleGoogleSignIn,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 60,
                          height: 60,
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/google.png'),
                        ),
                      ),

                      const SizedBox(width: 32),

                      // Facebook
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FacebookLogin(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 60,
                          height: 60,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/facebook.png'),
                        ),
                      ),

                      const SizedBox(width: 32),

                      // Twitter/X
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 60,
                          height: 60,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/x.png'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Sign up prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 14,
                          letterSpacing: -0.1
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => Signup(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign Up',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
