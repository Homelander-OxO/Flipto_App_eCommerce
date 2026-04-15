import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/address_model.dart';
import 'package:flutter_app/models/e-subcategory_model.dart';
import 'package:flutter_app/screens/confirm_order.dart';
import 'package:flutter_app/screens/add_credit_card.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/fcm.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:flutter_app/custom_widgets/loading.dart';
import 'package:flutter_app/custom_widgets/progress_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum PaymentTab { newCard, savedCards }

class RazorPay extends StatefulWidget {
  final double amount;
  final CartProvider cartProvider;
  final Address selectedAddress;
  final String cartType; // NEW

  const RazorPay({
    super.key,
    required this.amount,
    required this.cartProvider,
    required this.selectedAddress,
    required this.cartType,
  });

  @override
  State<RazorPay> createState() => _RazorPayState();
}

class _RazorPayState extends State<RazorPay> {
  late Razorpay _razorpay;
  late FToast fToast;
  Map<String, dynamic>? razorpayResponse;
  String? selectedPaymentMethod;
  bool _isLoading = false; // Add loading state
  bool _isInitialLoading = true; // Controls whether to show shimmer
  String? _selectedCardId;
  PaymentTab _selectedTab = PaymentTab.newCard;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    fToast = FToast()..init(context);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isInitialLoading = false; // Turn off shimmer after 1 second
        });
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    var orderId = response.orderId;
    var signature = response.signature;
    var paymentId = response.paymentId;
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    String? userId = cartProvider.useremail ?? cartProvider.email ?? '';
    setState(() {
      _isLoading = true; // Set loading state to true
    });

    razorpayResponse = {
      "id": paymentId ?? "unknown_order_id",
      "entity": "order",
      "amount": widget.amount * 100,
      "currency": "INR",
      "status": "paid",
      "method": "Razorpay",
    };

    await storeOrder();
    // ✅ Empty the cart after successful payment

    if (userId != null && userId.isNotEmpty) {
      final isGrocery = widget.cartType == 'grocery';
      final filteredCartItems1 = widget.cartProvider.cartItems1.where((item) {
        final product = widget.cartProvider.cartItems.firstWhere(
          (p) => p.product_id == item.productId,
        );
        if (product == null) return false;
        return isGrocery ? product.id == "3" : product.id != "3";
      }).toList();

      for (var item in filteredCartItems1) {
        await ApiService.removeCart(item.cartId);
      }

      print(
          "✅ Cleared only ${isGrocery ? 'grocery' : 'regular'} items from cart.");
    }

    print("Payment Successful! Payment ID: $paymentId");

    // final selectedAddress = widget.cartProvider.addresses.isNotEmpty
    //     ? widget.cartProvider.addresses[0] // Assuming first address is selected
    //     : null;
    //
    // // Prepare address details
    // final addressDetails = selectedAddress != null
    //     ? <String, dynamic>{
    //   'apartmentNo': selectedAddress.apartmentNo,
    //   'street': selectedAddress.street,
    //   'area': selectedAddress.area,
    //   'city': selectedAddress.city,
    //   'pincode': selectedAddress.pincode,
    //   'contact': selectedAddress.contact,
    // }
    //     : <String, dynamic>{};

    await ApiService.addTransaction(
      paymentId: paymentId ?? "unknown_payment_id",
      // addressDetails: addressDetails,
    );

    String? fcmToken = FirebaseApi.fcmToken;

    if (fcmToken != null) {
      // await Future.delayed(Duration(seconds: 1));
      await ApiService.sendFCMNotification(
          title: "Order Confirmed",
          main:
              "Your order has been placed successfully. It will be delivered within 7 days.",
          deviceToken: fcmToken,
          userId: userId // ✅ Send FCM token dynamically
          );
      await Future.delayed(Duration(seconds: 1));

      // ✅ Additional Payment Successful notification
      await ApiService.sendFCMNotification(
        title: "Payment Successful",
        main:
            "Payment of ₹${widget.amount} was successful. Your order is being processed.",
        deviceToken: fcmToken,
        userId: userId,
      );
    } else {
      print("❌ FCM Token is null, notification not sent.");
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          orderId: razorpayResponse!['id'],
          addressDetails: {
            // Add this
            'apartmentNo': widget.selectedAddress.apartmentNo,
            'street': widget.selectedAddress.street,
            'area': widget.selectedAddress.area,
            'city': widget.selectedAddress.city,
            'pincode': widget.selectedAddress.pincode,
            'contact': widget.selectedAddress.contact,
          },
        ),
      ),
      (route) => false,
    );
    print('Order: ${orderId}');
    print('payment: ${paymentId}');
    print('signature: ${signature}');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    showToast('❌ Payment Failed! Reason: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    showToast('⚡ External Wallet Selected: ${response.walletName}');
  }

  Future<void> startPayment() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    String? userName = cartProvider.username ?? cartProvider.name;
    String? userEmail = cartProvider.useremail ?? cartProvider.email;
    String? userId = cartProvider.useremail ?? cartProvider.email ?? '';

    try {
      if (selectedPaymentMethod == "card") {
        // This will use the razorpayResponse prepared in _handleCardSelection
        if (razorpayResponse == null) {
          showToast('❌ Payment processing failed. Please try again.');
          return;
        }

        // await storeOrder();

        // Send notifications
        // String? fcmToken = FirebaseApi.fcmToken;
        // final cartProvider = Provider.of<CartProvider>(context, listen: false);
        // String? userId = cartProvider.useremail ?? cartProvider.email ?? '';
        //
        // if (fcmToken != null) {
        //   await ApiService.sendFCMNotification(
        //       title: "Order Confirmed",
        //       main: "Your order has been placed successfully.",
        //       deviceToken: fcmToken,
        //       userId: userId);
        //
        //   await ApiService.sendFCMNotification(
        //     title: "Payment Successful",
        //     main: "Payment of ₹${widget.amount} was successful.",
        //     deviceToken: fcmToken,
        //     userId: userId,
        //   );
        // }
        //
        // // Clear cart and navigate to confirmation
        // widget.cartProvider.clearCart();
        //
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => OrderConfirmationScreen(
        //       orderId: razorpayResponse!['id'],
        //       addressDetails: {
        //         'apartmentNo': widget.selectedAddress.apartmentNo,
        //         'street': widget.selectedAddress.street,
        //         'area': widget.selectedAddress.area,
        //         'city': widget.selectedAddress.city,
        //         'pincode': widget.selectedAddress.pincode,
        //         'contact': widget.selectedAddress.contact,
        //       },
        //     ),
        //   ),
        //   (route) => false,
        // );
      } else if (selectedPaymentMethod == "razorpay") {
        double amount = widget.amount;

        // Calculate delivery charge
        final deliveryCharge = amount >= 500 ? 0 : 40;
        final totalAmount = amount;

        if (amount < 1.0) {
          showToast('❌ Amount must be greater than ₹1.');
          return;
        }

        // Convert to paisa (Razorpay expects amount in smallest currency unit)
        int amountInPaisa =
            (amount * 100).toInt(); // This is what we'll actually charge
        int displayAmountInPaisa =
            (totalAmount * 100).toInt(); // This is what we'll show

        PaymentRequest? paymentRequest =
            await ApiService.buyNow(amountInPaisa.toDouble());
        if (paymentRequest == null) {
          showToast('❌ Failed to generate order ID. Try again.');
          return;
        }

        // Store the orderId in the CartProvider
        cartProvider.setOrderId(paymentRequest);

        razorpayResponse = {
          "id": paymentRequest.orderId,
          "entity": "order",
          "amount": amountInPaisa,
          "currency": "INR",
          "status": "created",
        };

        var options = {
          'key': 'rzp_test_fYPS4vRtfn9qdL',
          'amount': displayAmountInPaisa,
          // 'amount': paymentRequest.amountInPaisa,
          'name': userName,
          'description': 'E-commerce',
          'prefill': {
            'contact': '8888888888',
            'email': userEmail,
          },
          'notes': {
            'actual_amount': amountInPaisa,
            // The amount we'll actually charge
            'delivery_charge': (deliveryCharge * 100).toInt(),
            // Delivery in paisa
          },
        };

        try {
          _razorpay.open(options);
        } catch (e) {
          print('Error: $e');
          showToast('❌ Error while opening Razorpay checkout.');
        }
      } else {
        await storeOrder();

        // ✅ Dynamically fetch and pass the FCM token
        String? fcmToken = FirebaseApi.fcmToken;

        if (fcmToken != null) {
          await Future.delayed(Duration(seconds: 2));
          await ApiService.sendFCMNotification(
              title: "Order Confirmed",
              main:
                  "Your order has been placed successfully. It will be delivered within 7 days.",
              deviceToken: fcmToken,
              userId: userId // ✅ Send FCM token dynamically
              );
          await Future.delayed(Duration(seconds: 1));

          // ✅ Additional Payment Successful notification
          await ApiService.sendFCMNotification(
            title: "Payment Successful",
            main:
                "Payment of ₹${widget.amount} was successful. Your order is being processed.",
            deviceToken: fcmToken,
            userId: userId,
          );
        } else {
          print("❌ FCM Token is null, notification not sent.");
        }

        widget.cartProvider.clearCart();
      }
    } catch (e) {
      showToast('❌ Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // if (selectedPaymentMethod == "razorpay") {
    //   double amount = widget.amount;
    //   if (amount < 1.0) {
    //     showToast('❌ Amount must be greater than ₹1.');
    //     return;
    //   }
    //
    //   int amountInPaisa = (amount).toInt();
    //
    //   PaymentRequest? paymentRequest =
    //       await ApiService.buyNow(amountInPaisa.toDouble());
    //   if (paymentRequest == null) {
    //     showToast('❌ Failed to generate order ID. Try again.');
    //     return;
    //   }
    //
    //   // Store the orderId in the CartProvider
    //   cartProvider.setOrderId(paymentRequest);
    //
    //   razorpayResponse = {
    //     "id": paymentRequest.orderId,
    //     "entity": "order",
    //     "amount": amountInPaisa,
    //     "currency": "INR",
    //     "status": "created",
    //   };
    //
    //   var options = {
    //     'key': 'rzp_test_fYPS4vRtfn9qdL',
    //     'amount': paymentRequest.amountInPaisa,
    //     'name': userName,
    //     'description': 'E-commerce',
    //     'prefill': {
    //       'contact': '8888888888',
    //       'email': userEmail,
    //     },
    //   };
    //
    //   try {
    //     _razorpay.open(options);
    //   } catch (e) {
    //     print('Error: $e');
    //     showToast('❌ Error while opening Razorpay checkout.');
    //   }
    // } else {
    //   await storeOrder();
    //
    //   // ✅ Dynamically fetch and pass the FCM token
    //   String? fcmToken = FirebaseApi.fcmToken;
    //
    //   if (fcmToken != null) {
    //     await Future.delayed(Duration(seconds: 2));
    //     await ApiService.sendFCMNotification(
    //         title: "Order Confirmed",
    //         main:
    //             "Your order has been placed successfully. It will be delivered within 7 days.",
    //         deviceToken: fcmToken,
    //         userId: userId // ✅ Send FCM token dynamically
    //         );
    //     await Future.delayed(Duration(seconds: 1));
    //
    //     // ✅ Additional Payment Successful notification
    //     await ApiService.sendFCMNotification(
    //       title: "Payment Successful",
    //       main:
    //           "Payment of ₹${widget.amount} was successful. Your order is being processed.",
    //       deviceToken: fcmToken,
    //       userId: userId,
    //     );
    //   } else {
    //     print("❌ FCM Token is null, notification not sent.");
    //   }
    //
    //   widget.cartProvider.clearCart();
    // }
  }

  Future<void> storeOrder() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isGrocery = widget.cartType == 'grocery';

    // Choose either Google ID or Normal User Email
    String? userId = cartProvider.useremail ?? cartProvider.email;

    if (userId == null || userId.isEmpty) {
      showToast('❌ Error: User ID not found!');
      return;
    }

    if (razorpayResponse == null) {
      showToast('❌ Error: Payment response not generated.');
      return;
    }

    // Filter cart items based on category_id
    final filteredCartItems = cartProvider.cartItems
        .where((item) => isGrocery ? item.id == "3" : item.id != "3")
        .toList();

    final filteredCartItems1 = cartProvider.cartItems1.where((item) {
      final product = filteredCartItems.firstWhere(
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
      return isGrocery ? product.id == "3" : product.id != "3";
    }).toList();

    List<String> productIds =
        filteredCartItems.map((item) => item.product_id).toList();
    List<String> amounts = filteredCartItems.map((item) => item.price).toList();
    List<String> colors =
        filteredCartItems1.map((item) => item.color?.trim() ?? '').toList();
    List<String> sizes =
        filteredCartItems1.map((item) => item.size?.trim() ?? '').toList();
    List<int> quantity = filteredCartItems1
        .map((item) => int.tryParse(item.quantity) ?? 1)
        .toList();

    final addressDetails = {
      'apartmentNo': widget.selectedAddress.apartmentNo,
      'street': widget.selectedAddress.street,
      'area': widget.selectedAddress.area,
      'city': widget.selectedAddress.city,
      'pincode': widget.selectedAddress.pincode,
      'contact': widget.selectedAddress.contact,
    };

    await ApiService.storePaymentData(
      order: razorpayResponse!,
      userId: userId,
      productIds: productIds,
      amounts: amounts,
      colors: colors,
      sizes: sizes,
      quantity: quantity,
      addressDetails: addressDetails,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          orderId: razorpayResponse!['id'],
          addressDetails: addressDetails,
        ),
      ),
      (route) => false,
    );

    showToast('✅ Order Placed Successfully!');
  }

  void showToast(String message) {
    fToast.showToast(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.black87,
        ),
        child: Text(message, style: const TextStyle(color: Colors.white)),
      ),
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SimpleCircularLoader(color: Colors.indigoAccent),
              const SizedBox(height: 20),
              Text(
                "Processing Payment...",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isInitialLoading
        ? _buildShimmerEffect()
        : Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.grey[800]),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Payment',
                style: GoogleFonts.manrope(
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                // const SizedBox(height: 8),
                CheckoutProgress(currentStep: 3, previousStep: 2),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Payment Method",
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Rest of your payment options...
                        _buildPaymentOption(
                          title: "Pay with Card",
                          subtitle: "Visa, Mastercard, Rupay",
                          icon: Icons.credit_card,
                          suffixIcon: Icons.arrow_forward_ios_rounded,
                          isSelected: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              CustomCupertinoPageRoute(
                                builder: (context) => AddCardScreen(
                                  amount: widget.amount,
                                  onPaymentSuccess: () {
                                    // This will be called when payment succeeds in AddCardScreen
                                    _handleCardPaymentSuccess();
                                    // Navigator.pushReplacement(
                                    //   context,
                                    //   MaterialPageRoute(
                                    //     builder: (context) =>
                                    //         OrderConfirmationScreen(
                                    //           orderId: razorpayResponse!['id'],
                                    //           addressDetails: {
                                    //             'apartmentNo': widget.selectedAddress.apartmentNo,
                                    //             'street': widget.selectedAddress.street,
                                    //             'area': widget.selectedAddress.area,
                                    //             'city': widget.selectedAddress.city,
                                    //             'pincode': widget.selectedAddress.pincode,
                                    //             'contact': widget.selectedAddress.contact,
                                    //           },
                                    //
                                    //         ),
                                    //   ),
                                    // );
                                  },
                                  onPaymentError: (error) {
                                    showToast(error);
                                  },
                                  onCardAdded: () {
                                    // Optional: Handle when new card is added
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        _buildPaymentOption(
                          title: "Cash on Delivery",
                          subtitle: "Pay when you receive your order",
                          icon: Icons.payments_outlined,
                          isSelected: selectedPaymentMethod == "cod",
                          onTap: () {
                            setState(() => selectedPaymentMethod = "cod");
                            _handleCodSelection();
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentOption(
                          title: "Razorpay Payments",
                          subtitle: "Cards, UPI, Wallets & Net Banking",
                          icon: Icons.credit_card,
                          // Fallback if asset fails
                          customIconAsset: 'assets/images/razorpay.png',
                          // Your logo`
                          isSelected: selectedPaymentMethod == "razorpay",
                          onTap: () => setState(
                              () => selectedPaymentMethod = "razorpay"),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentOption(
                          title: "UPI Payment",
                          subtitle: "Google Pay, PhonePe, Paytm & more",
                          icon: Icons.account_balance_wallet_rounded,
                          isSelected: selectedPaymentMethod == "upi",
                          onTap: () => setState(
                              () => selectedPaymentMethod = "razorpay"),
                        ),
                        const SizedBox(height: 32),
                        _buildOrderSummary(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              padding: EdgeInsets.fromLTRB(15, 12, 15, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Amount",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      Text(
                        '₹${(widget.amount).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    // height: 52,
                    height: MediaQuery.of(context).size.height * 0.065,
                    child: ElevatedButton(
                      onPressed: _selectedCardId != null ||
                              selectedPaymentMethod != null
                          ? startPayment
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: (_selectedCardId != null ||
                                selectedPaymentMethod != null)
                            ? Color(0xff101d42)
                            : Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _selectedCardId != null
                            ? "Pay with Selected Card"
                            : "Confirm Payment",
                        style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          letterSpacing: -0.05
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    IconData? suffixIcon,
    String? customIconAsset, // For Razorpay only
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        splashColor: Colors.indigo.withOpacity(0.085),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey[50],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? Colors.indigoAccent : Colors.grey[200]!,
              width: 1.5,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container with subtle highlight
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.indigoAccent.withOpacity(0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Center(
                  child: customIconAsset != null
                      ? Image.asset(
                          customIconAsset,
                          width: 22,
                          height: 22,
                          color: isSelected
                              ? Colors.indigoAccent
                              : Colors.grey[800],
                        )
                      : Icon(
                          icon,
                          size: 20,
                          color: isSelected
                              ? Colors.indigoAccent
                              : Colors.grey[700],
                        ),
                ),
              ),
              const SizedBox(width: 18),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.grey[900] : Colors.grey[800],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.grey[600] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Your Preferred Radio Button (unchanged)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.indigoAccent : Colors.grey[400]!,
                    width: isSelected ? 6 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = widget.amount - (widget.amount >= 500 ? 0 : 40);
    final deliveryCharge = widget.amount >= 500 ? 0 : 40;
    final total = widget.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            "ORDER SUMMARY",
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                _buildSummaryRow(
                  "Subtotal",
                  "₹${subtotal.toStringAsFixed(1)}",
                  isFirst: true,
                ),
                // _buildDivider(),
                _buildSummaryRow(
                  'Delivery Charges',
                  deliveryCharge == 0 ? 'Free Delivery' : '₹$deliveryCharge',
                  isDelivery: true,
                  isFreeDelivery: deliveryCharge == 0,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                  child: Center(
                    child: CustomPaint(
                      painter: _DashedLinePainter(),
                      size: Size(double.infinity, 1),
                    ),
                  ),
                ),
                _buildSummaryRow(
                  "Total Amount",
                  "₹${total.toStringAsFixed(2)}",
                  isTotal: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isTotal = false,
    bool isFirst = false,
    bool isDelivery = false,
    bool isFreeDelivery = false,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, isFirst ? 12 : 4, 0, isTotal ? 12 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: isTotal ? 15.5 : 14.5,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? Colors.grey[900] : Colors.grey[600],
              letterSpacing: -0.2,
            ),
          ),
          if (isDelivery && isFreeDelivery)
            Text(
              value, // This will be "Free"
              style: GoogleFonts.manrope(
                fontSize: 14.5,
                color: Colors.green,
                fontWeight: FontWeight.w600,
                  letterSpacing: -0.2
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: isTotal ? 16 : 14.5,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                color: isTotal ? Colors.indigoAccent : Colors.grey[800],
                letterSpacing: -0.2,
              ),
            ),
        ],
      ),
    );
  }

  // Widget _customRadioButton(String value, bool isSelected) {
  //   return GestureDetector(
  //     onTap: () {
  //       setState(() {
  //         selectedPaymentMethod = value;
  //       });
  //       if (value == "cod") {
  //         _handleCodSelection();
  //       }
  //     },
  //     child: Container(
  //       width: 24,
  //       height: 24,
  //       decoration: BoxDecoration(
  //         shape: BoxShape.circle,
  //         gradient: isSelected
  //             ? LinearGradient(
  //           colors: [
  //             Colors.blue,
  //             Colors.blueAccent,
  //             Colors.indigoAccent,
  //           ],
  //           begin: Alignment.topCenter,
  //           end: Alignment.bottomCenter,
  //         )
  //             : LinearGradient(
  //           colors: [Colors.white],
  //           begin: Alignment.topCenter,
  //           end: Alignment.bottomCenter,
  //         ),
  //         border: Border.all(
  //           color: isSelected ? Colors.blue : Colors.grey,
  //           width: 0.5,
  //         ),
  //       ),
  //       child: isSelected
  //           ? Center(
  //         child: Container(
  //           width: 10,
  //           height: 10,
  //           decoration: const BoxDecoration(
  //             shape: BoxShape.circle,
  //             color: Colors.white,
  //           ),
  //         ),
  //       )
  //           : null,
  //     ),
  //   );
  // }

  Future<void> _handleCodSelection() async {
    double amount = widget.amount;
    int amountInPaisa = (amount * 100).toInt();

    PaymentRequest? paymentRequest =
        await ApiService.buyNow(amountInPaisa.toDouble());

    if (paymentRequest != null) {
      setState(() {
        razorpayResponse = {
          "id": paymentRequest.orderId,
          "entity": "order",
          "amount": amountInPaisa,
          "currency": "INR",
          "status": "created",
          "method": "COD",
        };
      });
    } else {
      showToast('❌ Failed to generate order ID for COD.');
    }
  }

  // In your payment screen
  void _handleCardPaymentSuccess() async {
    // Show processing indicator
    setState(() => _isLoading = true);

    try {
      // Simulate payment processing delay
      await Future.delayed(Duration(milliseconds: 400));

      // Prepare payment response
      double amount = widget.amount;
      int amountInPaisa = (amount * 100).toInt();

      PaymentRequest? paymentRequest =
          await ApiService.buyNow(amountInPaisa.toDouble());

      if (paymentRequest != null) {
        razorpayResponse = {
          "id": paymentRequest.orderId,
          "entity": "order",
          "amount": amountInPaisa,
          "currency": "INR",
          "status": "paid",
          "method": "Card",
        };

        // Navigate to confirmation
        _navigateToConfirmation();

        await storeOrder();

        // Send notifications
        await _sendPaymentNotifications();

        // Clear cart
        widget.cartProvider.clearCart();
      }
    } catch (e) {
      showToast('Payment failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPaymentNotifications() async {
    String? fcmToken = FirebaseApi.fcmToken;
    String? userId =
        widget.cartProvider.useremail ?? widget.cartProvider.email ?? '';

    if (fcmToken != null) {
      await ApiService.sendFCMNotification(
          title: "Order Confirmed",
          main: "Your order has been placed successfully.",
          deviceToken: fcmToken,
          userId: userId);

      await ApiService.sendFCMNotification(
        title: "Payment Successful",
        main: "Payment of ₹${widget.amount} was successful.",
        deviceToken: fcmToken,
        userId: userId,
      );
    }
  }

  void _navigateToConfirmation() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => OrderConfirmationScreen(
          orderId: razorpayResponse!['id'],
          addressDetails: {
            'apartmentNo': widget.selectedAddress.apartmentNo,
            'street': widget.selectedAddress.street,
            'area': widget.selectedAddress.area,
            'city': widget.selectedAddress.city,
            'pincode': widget.selectedAddress.pincode,
            'contact': widget.selectedAddress.contact,
          },
        ),
      ),
      (route) => false,
    );
  }

  Widget _buildShimmerEffect() {
    return Skeletonizer(
      enabled: true,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          leading: Icon(Icons.arrow_back_rounded),
          title: Text(
            'Payment',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        body: Column(
          children: [
            Divider(height: 1, color: Colors.grey[300]),
            // Skeletonize the progress indicator
            Container(
              padding: EdgeInsets.fromLTRB(26, 12, 40, 20),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: Colors
                        .transparent, // Placeholder for progress indicator
                  ),
                  Row(
                    // spacing: 30,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        List.generate(3, (index) => Bone.circle(size: 26)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey[300]),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 35, 15, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skeleton title
                    Skeleton.leaf(
                        child: Container(
                      height: MediaQuery.of(context).size.width / 17,
                      width: MediaQuery.of(context).size.width / 1.9,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    )),
                    SizedBox(height: 20),
                    // Skeleton payment method card
                    Skeleton.leaf(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 7, horizontal: 7),
                        height: MediaQuery.of(context).size.height / 11,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Second skeleton payment method card
                    Skeleton.leaf(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 7, horizontal: 7),
                        height: MediaQuery.of(context).size.height / 11,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Second skeleton payment method card
                    Skeleton.leaf(
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 7, horizontal: 7),
                        height: MediaQuery.of(context).size.height / 11,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ...List.generate(
                    3,
                    (index) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Bone.text(width: 80),
                          Bone.text(width: 60),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: SizedBox(
            height: 54,
            child: Skeleton.leaf(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.5),
                  gradient: LinearGradient(
                    colors: [Colors.grey[300]!, Colors.grey[400]!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    const dashWidth = 5;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
