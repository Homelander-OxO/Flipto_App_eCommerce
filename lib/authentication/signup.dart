import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/custom_widgets/gradient_button.dart';
import 'package:flutter_app/Authentication/login.dart';
import 'package:google_fonts/google_fonts.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool isVisible = false;
  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  bool isLoading = false;

  void registerUser() async {
    if (username.text.isEmpty || email.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your details',
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
          backgroundColor: Color(0xff01AC66),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    var response = await ApiService.addUser(username.text, email.text);

    setState(() {
      isLoading = false;
    });

    print('Raw API response: $response');

    if (response.containsKey("Failure")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response["Failure"],
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Registration successful! Please log in.",
            style: TextStyle(color: Colors.white, fontSize: 17),
          ),
          backgroundColor: Color(0xff01AC66),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => const Login(
              username: '',
              email: '',
            ),
          ),
        );
      });
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
                    'assets/images/signUp.png',
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
                  //       Icons.person_add_alt_1_rounded,
                  //       size: 40,
                  //       color: Color(0xFF101D42),
                  //     ),
                  //   ),
                  // ),
                  //
                  // const SizedBox(height: 32),

                  // Welcome text
                  Text(
                    "Create Account",
                    style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101D42),
                        letterSpacing: -0.2),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Join us to get started",
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
                        letterSpacing: -0.1),
                    textAlign: TextAlign.center,
                  ),

                  // const SizedBox(height: 35),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.045),

                  // Username field
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
                      controller: username,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Username",
                        hintStyle: GoogleFonts.inter(
                            color: Colors.grey[500],
                            fontSize: 15,
                            letterSpacing: -0.1),
                        prefixIcon: Icon(
                          Icons.account_circle_outlined,
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
                          letterSpacing: -0.05),
                    ),
                  ),

                  const SizedBox(height: 20),

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
                            letterSpacing: -0.1),
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
                          letterSpacing: -0.05),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Sign Up button
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.062,
                    child: ElevatedButton(
                      onPressed: registerUser,
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
                      child: isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Sign Up",
                              style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  height: 0.5),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

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

                  //
                  // // Login prompt
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Text(
                  //       "Already have an account? ",
                  //       style: GoogleFonts.inter(
                  //         color: Colors.grey[600],
                  //         fontSize: 14,
                  //         letterSpacing: -0.1
                  //
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width: 5,
                  //     ),
                  //     Text(
                  //       'Log In',
                  //       style: GoogleFonts.inter(
                  //         color: Color(0xFF101D42),
                  //         fontSize: 14,
                  //         fontWeight: FontWeight.w600,
                  //         letterSpacing: -0.1
                  //
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
