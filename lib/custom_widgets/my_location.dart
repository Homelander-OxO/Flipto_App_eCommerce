import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyLocation extends StatelessWidget {
  const MyLocation({super.key});

  @override
  Widget build(BuildContext context) {
    final Shader linearGradient = LinearGradient(
      colors: <Color>[
        Colors.blueAccent, // Blue
        Colors.blueAccent, // Blue
        Colors.deepPurpleAccent.shade700,
        Colors.deepPurpleAccent.shade700
        // Colors.purple.shade900,
        // Color(0xFF9C27B0),// Purple
      ],
    ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/logo3.png',
            scale: 12,
          ),
          SizedBox(
            width: 6,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Flipto",
                style: GoogleFonts.lobster(
                  fontSize: 30,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.01,
                  height: 1.15,
                  foreground: Paint()..shader = linearGradient,
                ),
              ),
              SizedBox(height: 0.1), // reduce spacing here

              Text(
                'Shop Smart, Flip Fast',
                style: GoogleFonts.poppins(
                    letterSpacing: 0.1,
                    fontSize: 14,
                    // color: Colors.blueGrey,
                    foreground: Paint()..shader = linearGradient,

                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
