import 'package:flutter/material.dart';
import 'dart:math';

class SimpleCircularLoader extends StatefulWidget {
  final Color color;
  final double strokeWidth; // New parameter for thickness

  const SimpleCircularLoader({
    Key? key,
    required this.color,
    this.strokeWidth = 4.0, // Default thickness
  }) : super(key: key);

  @override
  _SimpleCircularLoaderState createState() => _SimpleCircularLoaderState();
}

class _SimpleCircularLoaderState extends State<SimpleCircularLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3), // Adjusted for smoother speed
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 35,
        height: 35,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * pi, // Rotates smoothly
              child: CircularProgressIndicator(
                strokeWidth: widget.strokeWidth, // Custom stroke width
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                backgroundColor: Colors.transparent, // Keeps it clean
                strokeCap: StrokeCap.round, // Ensures smooth rounded edges
              ),
            );
          },
        ),
      ),
    );
  }
}
