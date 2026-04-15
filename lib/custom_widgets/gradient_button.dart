import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'loading.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color loaderColor; // New property for custom loader color
  final double loaderThickness; // New property for loader thickness

  const GradientButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.loaderColor = Colors.white, // Default loader color
    this.loaderThickness = 4.0, // Default thickness
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueAccent,
            Colors.indigoAccent.shade400,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed, // Disable button when loading
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: SimpleCircularLoader(
                    color: loaderColor,
                    strokeWidth: loaderThickness), // Custom color
              )
            : Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
