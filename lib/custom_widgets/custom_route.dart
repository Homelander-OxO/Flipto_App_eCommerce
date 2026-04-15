import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  CustomCupertinoPageRoute({required WidgetBuilder builder})
      : super(builder: builder);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    // Get the screen content
    final Widget page = super.buildPage(context, animation, secondaryAnimation);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          color: Colors.grey[50], // Match your app's background color
          child: Stack(
            children: [
              // Background layer ensures no black screen
              Container(color: Colors.grey[50]),
              // The actual page content
              page,
            ],
          ),
        );
      },
      child: page,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    // Keep the original Cupertino slide transition
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      // Wrap child to ensure background consistency
      Container(
        color: Colors.grey[50],
        child: child,
      ),
    );
  }
}