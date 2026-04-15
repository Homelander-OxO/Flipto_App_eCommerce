import 'dart:convert';
import 'dart:developer';
import 'package:flutter_app/API%20E-Commerce/Model/address_model.dart';
import 'package:flutter_app/API%20E-Commerce/Model/cart_items.dart';
import 'package:flutter_app/API%20E-Commerce/Model/e-subcategory_model.dart';
import 'package:flutter_app/API%20E-Commerce/Model/profile_model.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/bottom_navigation.dart';
import 'package:flutter_app/config/app_config.dart';
import 'package:flutter_app/Authentication/login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider extends ChangeNotifier {
  UserModel? _userProfile;

  UserModel? get userProfile => _userProfile;

  GoogleModel? _googleProfile; // ✅ Use GoogleModel here
  GoogleModel? get googleProfile =>
      _googleProfile; // ✅ Getter for Google profile

  PaymentRequest? _orderId;

  PaymentRequest? get orderId => _orderId;

  String? _userEmail; // Store login email
  String? get userEmail => _userEmail; // Getter for email

  // ✅ Add this getter to retrieve user_id dynamically
  // String? get id => _userProfile?.id;
  String? get email => _googleProfile?.email;

  String? get name => _googleProfile?.name;

  String? get uEmail => _userProfile?.email;

  String? get uName => _userProfile?.name;

  String? get oId => _orderId?.orderId;

  List<Subcategory> _cartItems = [];

  List<Subcategory> get cartItems => _cartItems;
  List<CartItem> _cartItems1 = [];

  List<CartItem> get cartItems1 => _cartItems1;

  Map<String, int> _itemQuantities = {};

  List<dynamic> _favorites = [];

  List<dynamic> get favorites => _favorites;

  List<dynamic> allItems = [];
  List<dynamic> _filteredItems = [];

  bool isLoading = false;

  List<dynamic> get filteredItems => _filteredItems;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '27062749153-dtn24suiat2a3qr7arav42b8mte3ilqf.apps.googleusercontent.com',
  );

  /// ✅ **Automatically Load User Data when Provider is created**
  CartProvider() {
    loadUserData();
  }

  /// ✅ **Load Google User Data from SharedPreferences & Restore Session**
  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('googleUser');

    // ✅ Restore previous Google login session
    GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();

    if (googleUser != null) {
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      String? idToken = googleAuth.idToken;
      if (idToken != null) {
        print("🔄 Restoring Google session with token: $idToken");
      }

      _googleProfile = GoogleModel(
        name: googleUser.displayName ?? '',
        email: googleUser.email,
        image: googleUser.photoUrl ?? '',
      );

      notifyListeners();
    }

    if (userData != null && _googleProfile == null) {
      _googleProfile = GoogleModel.fromJson(jsonDecode(userData));
      _userEmail = _googleProfile!.email;
      notifyListeners();
    }
  }

  /// ✅ **Save Google User Data in SharedPreferences**
  Future<void> saveUserData(GoogleModel googleProfile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('googleUser', jsonEncode(googleProfile.toJson()));
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("Sign-in canceled by user.");
        return;
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      String? idToken = googleAuth.idToken;

      if (idToken == null) {
        print("Failed to retrieve ID token.");
        return;
      }

      print("Google ID Token: $idToken");

      // Send token along with user info
      await sendGoogleToken(context: context, token: idToken);
    } catch (e) {
      print("Error signing in with Google: $e");
    }
  }

  Future<void> sendGoogleToken(
      {required BuildContext context, required String token}) async {
    try {
      // var uri = Uri.parse('http://10.30.226.167/Apis/googleSignIn');
      var uri = Uri.parse('${AppConfig.baseUrl}/Apis/googleSignIn');
      var request = http.MultipartRequest('POST', uri);
      request.fields['token'] = token;
      request.headers.addAll({
        "Accept": "application/json",
      });

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${responseBody.body}');

      if (response.statusCode == 200) {
        print("Token sent successfully!");

        // ✅ Parse response to populate Google profile
        final parsedData = json.decode(responseBody.body);
        final googleProfile = GoogleModel.fromJson(parsedData);
        setGoogleProfile(googleProfile);

        // ✅ Fetch contact and address using email
        await _fetchUserDetails(context, googleProfile.email);
        // Navigate to the home screen upon successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Navigation()),
        );
      } else {
        print(
            "Error: Failed to send token. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print('Network or other exception occurred: $e');
    }
  }

  Future<void> _fetchUserDetails(BuildContext context, String email) async {
    try {
      final response = await ApiService().fetchUserDetails(email);

      if (response != null) {
        print('User details found for email: $email');

        // ✅ Use Provider.of instead of context.read
        Provider.of<CartProvider>(context, listen: false)
            .setUserDetails(response);
      } else {
        print('No user details found for email: $email');
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void setOrderId(PaymentRequest orderId) {
    _orderId = orderId;
    notifyListeners();
  }

  // void setUser(String name, String email, String contact, String address) {
  //   _userProfile = UserModel(
  //     name: name,
  //     email: email,
  //     contact: contact.isNotEmpty ? null : contact,
  //     address: address.isNotEmpty ? null : address,
  //   );
  //   notifyListeners();
  // }

  String? _email;
  String? _name;
  UserDetailsModel? _userDetails;

  String? get useremail => _email;

  String? get username => _name;

  UserDetailsModel? get userDetails => _userDetails;

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void setUserDetails(UserDetailsModel user) {
    _userDetails = user;
    _email = user.email; // ✅ Ensure email is updated
    _name = user.fullName;
    notifyListeners();
  }

  // void setUserDetails(UserDetailsModel user) {
  //   // ✅ If contact and address are already set, don't overwrite them
  //   if (_userDetails != null && _userDetails!.email == user.email) {
  //     _userDetails = UserDetailsModel(
  //       userId: user.userId,
  //       fullName: user.fullName,
  //       email: user.email,
  //       contact: _userDetails!.contact.isNotEmpty ? _userDetails!.contact : user.contact,
  //       address: _userDetails!.address.isNotEmpty ? _userDetails!.address : user.address,
  //     );
  //   } else {
  //     // ✅ If new email or first-time login, set details directly
  //     _userDetails = user;
  //   }
  //
  //   _email = user.email;
  //   _name = user.fullName;
  //
  //   notifyListeners();
  // }

  void updateUserContactAddress(String contact, String address) {
    if (_userDetails != null) {
      _userDetails = UserDetailsModel(
        userId: _userDetails!.userId,
        fullName: _userDetails!.fullName,
        email: _userDetails!.email,
        image: _userDetails!.image,
        contact: contact,
        address: address,
      );
      notifyListeners();
    }
  }

  void clearUser() async {
    _userDetails = null;
    _email = null;
    notifyListeners();
  }

  void setUserEmail(UserModel userProfile) {
    _userProfile = userProfile;
    notifyListeners();
  }

  // ✅ Add setter for Google profile
  void setGoogleProfile(GoogleModel googleProfile) {
    _googleProfile = googleProfile;

    // ✅ If user details already exist, update contact and address
    if (_userDetails != null && _userDetails!.email == googleProfile.email) {
      _userDetails = UserDetailsModel(
        userId: _userDetails!.userId,
        fullName: _userDetails!.fullName,
        email: googleProfile.email,
        image: _userDetails!.image,
        contact: _userDetails!.contact,
        address: _userDetails!.address,
      );
    }

    notifyListeners();
  }

  /// ✅ **Logout & Clear SharedPreferences**
  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut(); // Google Sign out
      _googleProfile = null; // Clear profile
      _userEmail = null; // Clear email

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('googleUser'); // Clear stored user data

      notifyListeners();
      print("✅ User signed out successfully.");
    } catch (e) {
      print("❌ Error during Google sign out: $e");
    }
  }

  List<Address> _addresses = [];
  String? _defaultAddressKey; // Stores the index key ("0", "1", etc.)

  List<Address> get addresses => _addresses;

  String? get defaultAddressKey => _defaultAddressKey;

  Address? get defaultAddress {
    if (_addresses.isEmpty) return null;
    if (_defaultAddressKey == null) return _addresses.first;
    return _addresses.firstWhere(
      (a) => a.indexKey == _defaultAddressKey,
      orElse: () => _addresses.first,
    );
  }

  Future<void> fetchAddresses(String email) async {
    _addresses = await ApiService.showAddress(email);
    await _loadDefaultAddressPref(email);
    notifyListeners();
  }

  Future<void> _loadDefaultAddressPref(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _defaultAddressKey = prefs.getString('${email}_defaultAddress');
    notifyListeners();
  }

  Future<void> _saveDefaultAddressPref(String email, String indexKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${email}_defaultAddress', indexKey);
    _defaultAddressKey = indexKey;
    notifyListeners();
  }

  // In your CartProvider:
  Future<bool> setDefaultAddress(String email, int listIndex) async {
    if (listIndex >= 0 && listIndex < _addresses.length) {
      _defaultAddressKey = _addresses[listIndex].indexKey;
      await _saveDefaultAddressPref(email, _defaultAddressKey!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> removeAddress(String email, int listIndex) async {
    if (listIndex < 0 || listIndex >= _addresses.length) return false;

    // Get the indexKey before removing
    final addressKey = _addresses[listIndex].indexKey;

    bool success = await ApiService.deleteAddress(email, listIndex);
    if (success) {
      // Check if we're removing the default address
      if (addressKey == _defaultAddressKey) {
        _defaultAddressKey = null;
        if (_addresses.isNotEmpty) {
          // Set new default to first address if available
          await _saveDefaultAddressPref(email, _addresses[0].indexKey);
        } else {
          await _saveDefaultAddressPref(email, '');
        }
      }
      _addresses.removeAt(listIndex);
      notifyListeners();
    }
    return success;
  }

  // Future<void> signOutGoogle(BuildContext context) async {
  //   try {
  //     await _googleSignIn.signOut(); // Sign out from Google
  //     _googleProfile = null; // Clear Google profile data
  //     notifyListeners();
  //
  //     // Navigate back to the login page
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(
  //           builder: (context) => const Login(email: '', username: '')),
  //       (route) => false,
  //     );
  //
  //     // Show success message
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Successfully signed out from Google!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     print("Error during Google sign out: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Error signing out from Google.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // void setUserProfile(ProfileModel profile) {
  //   _userProfile = profile;
  //   notifyListeners();
  // }

  // Future<bool> loginUser(
  //     BuildContext context, String email, String password) async {
  //   if (email.isEmpty || password.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('❌ Please enter your email and password.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return false;
  //   }
  //
  //   try {
  //     final loginResponse = await ApiService.fetchLogin(email.trim(), password);
  //     if (loginResponse != null) {
  //       _userProfile = loginResponse;
  //       notifyListeners();
  //       return true;
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('❌ Invalid email or password.'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('❌ Login failed: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //     return false;
  //   }
  // }

  // void _signOut(BuildContext context) async {
  //   try {
  //     // Reset the user profile in CartProvider (custom sign-out logic)
  //     _userProfile = null; // Clear the user profile
  //     notifyListeners();
  //
  //     // Clear cart items and other data if necessary
  //     clearCart();
  //
  //     // Navigate to Login screen after sign-out
  //     Navigator.pushAndRemoveUntil(
  //       context,
  //       MaterialPageRoute(builder: (context) => Login(email: '', username: '')),
  //       (route) => false,
  //     );
  //
  //     // Show success snack bar
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Successfully signed out!'),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   } catch (e) {
  //     print("Error during sign out: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Error signing out.'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }
  //
  // // Use this method to trigger the sign-out process
  // void signOut(BuildContext context) {
  //   _signOut(context);
  // }

  Future<void> fetchCartItems(String userId) async {
    try {
      List<CartItem> fetchedItems = await ApiService().searchCart(userId);
      print('✅ Fetched Cart Items: ${fetchedItems.map((e) => e.productId)}');

      List<Subcategory> combinedItems = fetchedItems.map((cartItem) {
        var product = cartItems.firstWhere(
          (product) =>
              product.product_id.toString() == cartItem.productId.toString(),
          orElse: () {
            print('🚨 No match for productId: ${cartItem.productId}');
            return Subcategory(
              id: '',
              product_id: cartItem.productId.toString(),
              name: cartItem.name ?? 'Unknown Product',
              type: '',
              gender: '',
              description: '',
              price: cartItem.price,
              discount: '',
              image: '',
              productDetails:
                  cartItem.image, // Use from CartItem // ✅ Fallback image
// Empty details
            );
          },
        );

        return Subcategory(
          id: product.id,
          product_id: product.product_id,
          name: product.name.isNotEmpty
              ? product.name
              : cartItem.name ?? 'Unknown Product',
          type: product.type,
          gender: product.gender,
          description: product.description,
          price: cartItem.price,
          discount: product.discount,
          image: '',
          productDetails: product.productDetails ?? cartItem.image,
        );
      }).toList();

      // ✅ Update cart items
      cartItems1.clear();
      cartItems1.addAll(fetchedItems);

      cartItems.clear();
      cartItems.addAll(combinedItems);

      notifyListeners(); // ✅ Refresh UI
    } catch (e) {
      print('🚨 Error fetching cart: $e');
    }
  }

  // In CartProvider class
  List<Subcategory> get groceryItems =>
      _cartItems.where((item) => item.id == "3").toList();

  List<Subcategory> get nonGroceryItems =>
      _cartItems.where((item) => item.id != "3").toList();

  List<CartItem> get groceryCartItems => _cartItems1.where((item) {
        final product = _cartItems.firstWhere(
          (p) => p.product_id == item.productId,
          orElse: () => Subcategory(
            id: '',
            product_id: '',
            name: '',
            type: '',
            gender: '',
            description: '',
            price: '',
            discount: '',
            image: '',
            productDetails:
                ProductDetails(mainImages: [], colorImages: {}, sizes: []),
          ),
        );
        return product.id == "3";
      }).toList();

  List<CartItem> get nonGroceryCartItems => _cartItems1.where((item) {
        final product = _cartItems.firstWhere(
          (p) => p.product_id == item.productId,
          orElse: () => Subcategory(
            id: '',
            product_id: '',
            name: '',
            type: '',
            gender: '',
            description: '',
            price: '',
            discount: '',
            image: '',
            productDetails:
                ProductDetails(mainImages: [], colorImages: {}, sizes: []),
          ),
        );
        return product.id != "3";
      }).toList();

// Inside CartProvider class
  bool isProductInCart(String productId) {
    return _cartItems.any((item) => item.product_id == productId);
  }

  Future<String> addToCart(Subcategory product, BuildContext context) async {
    final email = Provider.of<CartProvider>(context, listen: false).email ??
        useremail ??
        '';
    final productId = product.product_id;

    if (email.isNotEmpty && productId.isNotEmpty) {
      bool isProductInCart =
          _cartItems.any((item) => item.product_id == productId);

      if (isProductInCart) {
        return 'Product is already in the cart!';
      }

      bool success = await ApiService().addToCart(
        email,
        productId,
        color: product.color,
        size: product.size,
      );

      if (success) {
        _cartItems.add(product);
        notifyListeners();
        return 'Product added to cart!';
      } else {
        return 'Failed to add product to cart.';
      }
    } else {
      return 'User not logged in or product is invalid.';
    }
  }

  Map<String, double> _productRatings = {};
  Map<String, int> _productRatingCounts = {};

  double getRatingForProduct(String productId) {
    return _productRatings[productId] ?? 0.0;
  }

  int getRatingCountForProduct(String productId) {
    return _productRatingCounts[productId] ?? 0;
  }

  Future<void> loadProductRating(String productId) async {
    try {
      final data = await ApiService.getProductRatings(productId);
      final List<dynamic> ratings = data['rating'];

      if (ratings.isNotEmpty) {
        final total = ratings.fold<int>(
          0,
          (sum, item) => sum + int.tryParse(item['rating'] ?? '0')!,
        );
        final avgRating = total / ratings.length;

        _productRatings[productId] = avgRating;
        _productRatingCounts[productId] = ratings.length;
      } else {
        _productRatings[productId] = 0.0;
        _productRatingCounts[productId] = 0;
      }

      notifyListeners();
    } catch (e) {
      print("Rating fetch failed for $productId: $e");
      _productRatings[productId] = 0.0;
      _productRatingCounts[productId] = 0;
    }
  }

  // In your CartProvider class
  Future<void> loadProductRatings(List<String> productIds) async {
    try {
      // Load ratings for all products in parallel
      await Future.wait(
        productIds.map((productId) => loadProductRating(productId)),
      );
    } catch (e) {
      print("Error loading product ratings: $e");
    }
  }

  List<String> _wishlistItems = [];
  bool _isLoadingWishlist = false;

  // Getters
  List<String> get wishlistItems => _wishlistItems;

  bool get isLoadingWishlist => _isLoadingWishlist;

  bool isProductInWishlist(String productId) =>
      _wishlistItems.contains(productId);

  // Initialize wishlist
  Future<void> initWishlist() async {
    final uEmail = useremail ?? email ?? '';
    if (uEmail.isEmpty) return;

    await fetchWishlist();
  }

  // Fetch current wishlist from API
  Future<void> fetchWishlist() async {
    final uEmail = useremail ?? this.email ?? '';
    if (uEmail.isEmpty) return;

    try {
      _isLoadingWishlist = true;
      notifyListeners();

      final wishlistData = await ApiService.getWishlist(uEmail);

      // Extract product IDs
      _wishlistItems =
          wishlistData.map((item) => item['product_id'].toString()).toList();

      print('WISHLIST LOADED: ${_wishlistItems.length} items');
    } catch (e) {
      print('WISHLIST FETCH ERROR: $e');
    } finally {
      _isLoadingWishlist = false;
      notifyListeners();
    }
  }

  // Add to wishlist
  Future<bool> addToWishlist(String productId) async {
    final uEmail = useremail ?? this.email ?? '';
    if (uEmail.isEmpty) return false;

    try {
      _isLoadingWishlist = true;
      notifyListeners();

      final success = await ApiService.addToWishlist(uEmail, productId);

      if (success && !_wishlistItems.contains(productId)) {
        _wishlistItems.add(productId);
      }

      return success;
    } catch (e) {
      print('ADD TO WISHLIST ERROR: $e');
      return false;
    } finally {
      _isLoadingWishlist = false;
      notifyListeners();
    }
  }

  // Remove from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    final uEmail = useremail ?? this.email ?? '';
    if (uEmail.isEmpty) return false;

    try {
      _isLoadingWishlist = true;
      notifyListeners();

      final success = await ApiService.removeFromWishlist(uEmail, productId);

      if (success) {
        _wishlistItems.remove(productId);
      }

      return success;
    } catch (e) {
      print('REMOVE FROM WISHLIST ERROR: $e');
      return false;
    } finally {
      _isLoadingWishlist = false;
      notifyListeners();
    }
  }

  // Toggle wishlist status
  Future<bool> toggleWishlist(String productId) async {
    if (isProductInWishlist(productId)) {
      return await removeFromWishlist(productId);
    } else {
      return await addToWishlist(productId);
    }
  }

  // Force refresh the wishlist
  Future<void> refreshWishlist() async {
    await fetchWishlist();
  }

  // Future<void> fetchCartItems(String userId) async {
  //   try {
  //     List<CartItem> fetchedItems = await ApiService().searchCart(userId);
  //     print('✅ Fetched Cart Items: $fetchedItems');
  //
  //     _cartItems1.clear(); // Clear old data
  //     _cartItems1.addAll(fetchedItems);
  //
  //     notifyListeners(); // ✅ Important to update UI
  //   } catch (e) {
  //     print('🚨 Error fetching cart: $e');
  //   }
  // }

  // String addToCart(Subcategory item, BuildContext context) {
  //   if (_itemQuantities.containsKey(item.product_id)) {
  //     return 'Item is already added';
  //   } else {
  //     _cartItems.add(item);
  //     _itemQuantities[item.product_id] = 1;
  //     notifyListeners();
  //     return 'Item is added';
  //   }
  // }

  void removeFromCart(Subcategory item) {
    _cartItems
        .removeWhere((cartItem) => cartItem.product_id == item.product_id);
    _itemQuantities.remove(item.product_id); // Remove from quantities map
    notifyListeners();
  }

  bool isInCart(Subcategory item) {
    return _cartItems.any((cartItem) => cartItem.product_id == item.product_id);
  }

  int get cartCount => _cartItems.length;

  void incrementQuantity(Subcategory item) {
    if (_itemQuantities.containsKey(item.product_id)) {
      _itemQuantities[item.product_id] =
          (_itemQuantities[item.product_id] ?? 1) + 1;
    }
    notifyListeners();
  }

  void decrementQuantity(Subcategory item) {
    if (_itemQuantities.containsKey(item.product_id) &&
        _itemQuantities[item.product_id]! > 1) {
      _itemQuantities[item.product_id] =
          (_itemQuantities[item.product_id] ?? 1) - 1;
    } else {
      _itemQuantities.remove(item.product_id); // Remove from map
      removeFromCart(item);
    }
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _cartItems1.clear(); // ✅ Clear this to reset total price
    _itemQuantities.clear();
    notifyListeners(); // Notify listeners about the cart state change
  }

  int getQuantity(Subcategory item) {
    return _itemQuantities[item.product_id] ?? 0;
  }

  double getTotalPrice() {
    double total = 0.0;
    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      final cartItem = cartItems1[i];

      final price = double.tryParse(item.price) ?? 0.0;
      final discount = int.tryParse(item.discount) ?? 0;
      final discountedPrice = price * (100 - discount) / 100;
      final quantity = int.tryParse(cartItem.quantity) ?? 1;

      total += discountedPrice * quantity;
    }
    return total;
  }

  // ✅ Update quantity for cartItems1
  // Update your updateQuantity method to sync both lists
  void updateQuantity(String productId, int newQuantity) {
    // Update cartItems1 (API model)
    int index = _cartItems1.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      final oldItem = _cartItems1[index];

      _cartItems1[index] = CartItem(
        cartId: oldItem.cartId,
        userId: oldItem.userId,
        productId: oldItem.productId,
        quantity: newQuantity.toString(),
        price: oldItem.price,
        totalPrice: (double.parse(oldItem.price) * newQuantity).toString(),
        addedAt: oldItem.addedAt,
        updatedAt: oldItem.updatedAt,
        name: oldItem.name,
        image: oldItem.image,
        color: oldItem.color,
        // ✅ preserve color
        size: oldItem.size, // ✅ preserve size
      );
    }

    // Update cartItems (UI model)
    index = _cartItems.indexWhere((item) => item.product_id == productId);
    if (index != -1) {
      _itemQuantities[productId] = newQuantity;
    }

    notifyListeners();
  }

  // ✅ Set data for product details
  void setCartItems(List<Subcategory> items) {
    _cartItems = items;
    notifyListeners();
  }

  // ✅ Set data for user cart details
  void setCartItems1(List<CartItem> items) {
    _cartItems1 = items;
    notifyListeners();
  }

  // double getTotalPrice() {
  //   double total = 0.0;
  //   for (var item in _cartItems) {
  //     total +=
  //         (double.parse(item.price) * (_itemQuantities[item.product_id] ?? 1));
  //   }
  //   return total;
  // }

  void toggleFavorite(Map<String, dynamic> item) {
    // Check if the item already exists in favorites
    bool isFavorite =
        _favorites.any((favoriteItem) => favoriteItem['name'] == item['name']);

    if (isFavorite) {
      // If item is already in favorites, remove it
      _favorites
          .removeWhere((favoriteItem) => favoriteItem['name'] == item['name']);
    } else {
      // Add item to favorites
      _favorites.add(item);
    }

    // Notify listeners to update UI
    notifyListeners();
  }

  // Check if the item is already in favorites
  bool isFavorite(Map<String, dynamic> item) {
    return _favorites
        .any((favoriteItem) => favoriteItem['name'] == item['name']);
  }

  void searchItems(String query) {
    if (query.isEmpty) {
      _filteredItems =
          List.from(allItems); // Show all items when query is empty
    } else {
      _filteredItems = allItems.where((item) {
        return item['name'].toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }
}
