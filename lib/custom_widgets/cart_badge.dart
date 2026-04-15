import 'package:flutter/material.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/cart_page.dart';
import 'package:flutter_app/Utilities/bottom_navigation.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/Utilities/provider.dart'; // Import your CartProvider

class CartIconWithBadge extends StatelessWidget {
  const CartIconWithBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItemCount = cartProvider.cartItems.length;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            icon: ImageIcon(
              AssetImage('assets/images/cart5.png'),
              size: 24,
              color: Colors.black,
            ),
            onPressed: () {
              // Navigate back to the root (Navigation screen) and then to cart
              Navigator.popUntil(context, (route) => route.isFirst);

              // Then change to cart tab using the global key
              if (navigationKey.currentState != null) {
                navigationKey.currentState!.changeTab(1); // Assuming cart is index 1
              } else {
                // Fallback if something goes wrong
                Navigator.push(
                  context,
                  CustomCupertinoPageRoute(builder: (context) => CartScreen()),
                );
              }
            },
          ),
        ),
        if (cartItemCount > 0)
          Positioned(
            right: 15.5,
            top: 9.5,
            child: Container(
              padding: EdgeInsets.only(bottom: 0),
              constraints: BoxConstraints(
                minWidth: 13.5,
                minHeight: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$cartItemCount',
                style: GoogleFonts.inter(
                  height: 1.4,
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w500
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class CustomBadge extends StatelessWidget {
  final int value; // Number to display in the badge
  final Widget child; // The widget to overlay the badge on

  const CustomBadge({
    Key? key,
    required this.value,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (value > 0)
          Positioned(
            left: 11.8,
            bottom: 11.7,
            child: Container(
              height: 10,
              width: 10,
              padding: EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: Colors.red, // Badge color
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: 12.3,
                minHeight: 12.3,
              ),
              child: Text(
                '$value',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
