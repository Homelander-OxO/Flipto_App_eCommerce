import 'package:animations/animations.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_app/API%20E-Commerce/Screen/categories.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/profile_screen.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/cart_page.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/favourite.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/home_page.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/Authentication/login.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class Navigation extends StatefulWidget {
  const Navigation({Key? key}) : super(key: key);

  @override
  NavigationState createState() => NavigationState();
}

final GlobalKey<NavigationState> navigationKey = GlobalKey<NavigationState>();

// Changed from _NavigationState to NavigationState (public)
class NavigationState extends State<Navigation> {
  int currentindex = 0;

  // Public method to change tabs
  void changeTab(int index) {
    setState(() {
      currentindex = index;
    });
  }

  @override
  void initState() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final email = cartProvider.email ?? cartProvider.useremail ?? '';
    super.initState();
    cartProvider.fetchCartItems(email);
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final user = cartProvider.userDetails;
    final googleUser = cartProvider.googleProfile;

    // Screens list
    final List<Widget> screens = [
      const HomePage(),
      CartScreen(),
      CategoriesScreen(),
      FavoriteScreen(),
      (user != null || googleUser != null)
          ? ProfilePage()
          : Scaffold(
              backgroundColor: Colors.grey[50],
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_circle,
                        size: 50, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No user data available.\nPlease log in to see your profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          CustomCupertinoPageRoute(
                            builder: (context) =>
                                const Login(email: '', username: ''),
                          ),
                        );
                      },
                      child: Container(
                        height: MediaQuery.of(context).size.height / 19,
                        width: MediaQuery.of(context).size.width / 4.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.redAccent.shade100, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            'Log In',
                            style: TextStyle(
                                color: Colors.redAccent[200],
                                fontWeight: FontWeight.w500,
                                fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (currentindex != 0) {
          setState(() {
            currentindex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return FadeTransition(
              opacity: primaryAnimation,
              child: child,
            );
          },
          child: screens[currentindex],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(top: 1),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.grey[50],
            unselectedItemColor: Colors.grey[500],
            unselectedLabelStyle: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            showUnselectedLabels: true,
            selectedFontSize: 12.5,
            selectedLabelStyle: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.01,
            ),
            currentIndex: currentindex,
            onTap: (index) {
              setState(() {
                currentindex = index;
              });
            },
            selectedItemColor: Colors.indigoAccent[400],
            elevation: 5,
            items: [
              BottomNavigationBarItem(
                icon: currentindex == 0
                    ? GradientIcon(
                        assetName: "assets/images/home(1).png",
                        size: 26,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent,
                            Colors.indigoAccent.shade400
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      )
                    : ImageIcon(
                        AssetImage("assets/images/home.png"),
                        size: 26,
                      ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: currentindex == 1
                    ? GradientIcon(
                        assetName: "assets/images/cart.png",
                        size: 26,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent,
                            Colors.indigoAccent.shade400
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      )
                    : ImageIcon(
                        AssetImage("assets/images/cart(1).png"),
                        size: 26,
                      ),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: currentindex == 2
                    ? GradientIcon(
                        assetName: "assets/images/cate.png",
                        size: 26,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent,
                            Colors.indigoAccent.shade400
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      )
                    : ImageIcon(
                        AssetImage("assets/images/cate1.png"),
                        size: 26,
                      ),
                label: 'Categories',
              ),
              BottomNavigationBarItem(
                icon: currentindex == 3
                    ? GradientIcon(
                        assetName: "assets/images/heart(2).png",
                        size: 26,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent,
                            Colors.indigoAccent.shade400
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      )
                    : ImageIcon(
                        AssetImage("assets/images/heart(3).png"),
                        size: 26,
                      ),
                label: 'Favorite',
              ),
              BottomNavigationBarItem(
                icon: currentindex == 4
                    ? GradientIcon(
                        assetName: "assets/images/user.png",
                        size: 26,
                        gradient: LinearGradient(
                          colors: [
                            Colors.blueAccent,
                            Colors.indigoAccent.shade400
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      )
                    : ImageIcon(
                        AssetImage("assets/images/user(1).png"),
                        size: 26,
                      ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GradientIcon extends StatelessWidget {
  final String assetName;
  final double size;
  final Gradient gradient;

  const GradientIcon({
    Key? key,
    required this.assetName,
    required this.size,
    required this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: ImageIcon(
        AssetImage(assetName),
        size: size,
        color: Colors.white, // Color will be overridden by gradient
      ),
    );
  }
}
