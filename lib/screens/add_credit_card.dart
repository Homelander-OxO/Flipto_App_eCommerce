import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/custom_widgets/card_1.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCardScreen extends StatefulWidget {
  final double amount;
  final void Function() onPaymentSuccess;
  final void Function(String) onPaymentError;
  final void Function() onCardAdded;

  const AddCardScreen({
    super.key,
    required this.amount,
    required this.onPaymentSuccess,
    required this.onPaymentError,
    required this.onCardAdded,
  });

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen>
    with TickerProviderStateMixin {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool saveCard = false;
  bool _isProcessing = false;
  bool _paymentSuccess = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TabController? _tabController;
  List<Map<String, dynamic>> _savedCards = [];
  String? _selectedCardId;

  // Add these variables to your state class
  late AnimationController _firstAnimController;
  late AnimationController _secondAnimController;
  bool _showFirstAnim = false;
  bool _showSecondAnim = false;

  @override
  void initState() {
    super.initState();

    _firstAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showFirstAnim = false);
        }
      });

    _secondAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showSecondAnim = false);
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSavedCards());
  }

  @override
  void dispose() {
    _firstAnimController.dispose();
    _secondAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final cardsJson = prefs.getStringList('saved_cards') ?? [];

    final saved = cardsJson.map((json) {
      final decoded = jsonDecode(json);
      return Map<String, dynamic>.from(decoded);
    }).toList();

    if (!mounted) return;

    setState(() {
      _savedCards = saved;
      _tabController?.dispose();
      _tabController = TabController(
        length: saved.isNotEmpty ? 2 : 1,
        vsync: this,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final showTabs = _savedCards.isNotEmpty;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Payment methods',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            bottom: (_tabController != null && showTabs)
                ? PreferredSize(
                    preferredSize: Size.fromHeight(50),
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TabBar(
                            dividerHeight: 0,
                            indicatorPadding:
                                EdgeInsets.only(left: -60, right: -50),
                            // indicatorSize: TabBarIndicatorSize.label,
                            controller: _tabController,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              color: Colors.black,
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[600],
                            labelStyle: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            unselectedLabelStyle: GoogleFonts.manrope(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            tabs: const [
                              Tab(text: 'New card'),
                              Tab(text: 'Saved cards'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
          body: _tabController == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController!,
                  children: showTabs
                      ? [
                          _buildNewCardForm(),
                          _buildSavedCardsList(),
                        ]
                      : [
                          _buildNewCardForm(),
                        ],
                ),
        ),
        _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildNewCardForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CreditCardWidget(
            cardNumber: cardNumber,
            expiryDate: expiryDate,
            cardHolderName: cardHolderName,
            cvvCode: cvvCode,
            showBackView: isCvvFocused,
            onCreditCardWidgetChange: (_) {},
            cardBgColor: Colors.indigoAccent.shade400,
            isHolderNameVisible: true,
            cardType: _getCardType(cardNumber),
            enableFloatingCard: true,
          ),
          const SizedBox(height: 16),
          CreditCardForm(
            formKey: formKey,
            cardNumber: cardNumber,
            expiryDate: expiryDate,
            cardHolderName: cardHolderName,
            cvvCode: cvvCode,
            onCreditCardModelChange: (creditCardModel) {
              setState(() {
                cardNumber = creditCardModel.cardNumber;
                expiryDate = creditCardModel.expiryDate;
                cardHolderName = creditCardModel.cardHolderName;
                cvvCode = creditCardModel.cvvCode;
                isCvvFocused = creditCardModel.isCvvFocused;
              });
            },
            inputConfiguration: InputConfiguration(
              cardNumberDecoration: _modernInputDecoration(
                label: 'Card Number',
                hint: 'XXXX XXXX XXXX XXXX',
                suffixIcon:
                    Icon(Icons.credit_card, color: Colors.grey.shade500),
              ),
              expiryDateDecoration: _modernInputDecoration(
                label: 'Expiry Date',
                hint: 'MM/YY',
                suffixIcon: Icon(Icons.calendar_month_rounded,
                    color: Colors.grey.shade500),
              ),
              cvvCodeDecoration: _modernInputDecoration(
                label: 'CVV',
                hint: 'XXX',
                suffixIcon:
                    Icon(Icons.help_outline, color: Colors.grey.shade500),
              ),
              cardHolderDecoration: _modernInputDecoration(
                label: 'Card Holder Name',
                hint: 'Enter Name',
                suffixIcon: Icon(Icons.person_outline_rounded,
                    color: Colors.grey.shade500),
              ),
              cardNumberTextStyle:
                  GoogleFonts.manrope(fontSize: 13, color: Colors.black),
              expiryDateTextStyle:
                  GoogleFonts.manrope(fontSize: 13, color: Colors.black),
              cvvCodeTextStyle:
                  GoogleFonts.manrope(fontSize: 13, color: Colors.black),
              cardHolderTextStyle:
                  GoogleFonts.manrope(fontSize: 13, color: Colors.black),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: saveCard,
                onChanged: (value) => setState(() => saveCard = value!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(color: Colors.grey.shade400, width: 1.2),
                activeColor: const Color(0xFF0A57FF), // Flipkart-style blue
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Save card for future payments',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff101d42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isProcessing ? null : _processPayment,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'PAY ₹${widget.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }

  InputDecoration _modernInputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 13,
      ),
      labelStyle: GoogleFonts.manrope(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.indigo.shade400,
          width: 1.5,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _saveCardDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCards = prefs.getStringList('saved_cards') ?? [];

      // Add null checks for card details
      if (cardNumber.isEmpty || cardNumber.length < 4) {
        throw Exception('Invalid card number');
      }

      final cardData = {
        'cardNumber': cardNumber,
        'expiryDate': expiryDate,
        'cardHolderName': cardHolderName,
        'last4': cardNumber.substring(cardNumber.length - 4),
        'cardType': _getCardType(cardNumber).toString(),
      };

      savedCards.add(json.encode(cardData));
      await prefs.setStringList('saved_cards', savedCards);
      widget.onCardAdded();
    } catch (e) {
      debugPrint('Failed to save card: $e');
      rethrow;
    }
  }

  // In AddCardScreen
  Future<void> _processPayment() async {
    if (_tabController!.index == 0 && !formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _paymentSuccess = false;
      _showFirstAnim = true;
      _showSecondAnim = false;
    });

    try {
      // First animation
      await _firstAnimController.forward(from: 0);

      // Second animation
      setState(() {
        _showFirstAnim = false;
        _showSecondAnim = true;
      });
      await _secondAnimController.forward(from: 0);

      // Process payment
      if (_tabController!.index == 0 && saveCard) {
        await _saveCardDetails();
      }

      // Show success and navigate immediately
      setState(() {
        _isProcessing = false;
        _paymentSuccess = true;
        _showSecondAnim = false;
      });

      widget.onPaymentSuccess();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _showFirstAnim = false;
        _showSecondAnim = false;
      });
      widget.onPaymentError(e.toString());
    } finally {
      _firstAnimController.reset();
      _secondAnimController.reset();
    }
  }

  // Future<void> _simulatePaymentSteps() async {
  //   // Simulate different stages of payment processing
  //   // await Future.delayed(Duration(milliseconds: 500)); // Connecting to bank
  //   // await Future.delayed(Duration(milliseconds: 800)); // Verifying card
  //   // await Future.delayed(Duration(milliseconds: 700)); // Processing payment
  // }

  // Future<void> _payWithSavedCard() async {
  //   setState(() => _isProcessing = true);
  //   try {
  //     // Simulate payment processing steps
  //     await _simulatePaymentSteps();
  //
  //     // Payment succeeded - no delay here
  //     setState(() {
  //       _isProcessing = false;
  //       _paymentSuccess = true;
  //     });
  //
  //     // Complete the payment immediately
  //     widget.onPaymentSuccess();
  //   } catch (e) {
  //     setState(() => _isProcessing = false);
  //     widget.onPaymentError('Payment failed: $e');
  //   }
  // }

  Widget _buildProcessingOverlay() {
    if (!_isProcessing && !_paymentSuccess) return const SizedBox();

    return Material(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showFirstAnim)
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Lottie.asset(
                  'assets/images/Animation - 1744189772543.json',
                  controller: _firstAnimController,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            if (_showSecondAnim)
              Lottie.asset(
                'assets/images/Animation - 1744189130020.json',
                controller: _secondAnimController,
                width: 250,
                height: 100,
                fit: BoxFit.contain,
              ),
            if (_paymentSuccess)
              Container(
                height: 160,
                width: 170,
                padding: EdgeInsets.fromLTRB(0, 0, 0, 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Lottie.asset(
                        'assets/images/Animation - 1741860923092.json',
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                        repeat: false,
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Payment Successful!",
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedCardsList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _savedCards.length,
            itemBuilder: (context, index) {
              final card = _savedCards[index];
              final cardId = card['last4'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SavedCardItem(
                  cardNumber: '•••• •••• •••• $cardId',
                  expiryDate: card['expiryDate'],
                  cardHolderName: card['cardHolderName'],
                  isSelected: _selectedCardId == cardId,
                  onTap: () => setState(() => _selectedCardId = cardId),
                  onDelete: () => _confirmDeleteCard(index),
                ),
              );
            },
          ),
        ),
        if (_selectedCardId != null) _buildPayWithSavedCardButton(),
      ],
    );
  }

  Widget _buildPayWithSavedCardButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(15, 10, 15, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12, // Reduced from 16
            offset: Offset(0, -3), // Reduced
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff101d42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isProcessing ? null : _processPayment,
          child: _isProcessing
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'PAY ₹${widget.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white),
                ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCard(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: const Text('Are you sure you want to delete this card?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final cards = prefs.getStringList('saved_cards') ?? [];
      final deletedCardId = _savedCards[index]['last4'];
      final wasSelected = _selectedCardId == deletedCardId;

      cards.removeAt(index);
      await prefs.setStringList('saved_cards', cards);

      await _loadSavedCards();

      if (wasSelected) {
        setState(() => _selectedCardId = null);
      }
    }
  }

  CardType _getCardType(String number) {
    if (number.startsWith('4')) return CardType.visa;
    if (number.startsWith('5')) return CardType.mastercard;
    if (number.startsWith('3')) return CardType.americanExpress;
    return CardType.otherBrand;
  }
}

//
// class PaymentProcessingAnimation extends StatefulWidget {
//   @override
//   _PaymentProcessingAnimationState createState() =>
//       _PaymentProcessingAnimationState();
// }
//
// class _PaymentProcessingAnimationState extends State<PaymentProcessingAnimation>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat(reverse: true);
//
//     _animation = Tween<double>(begin: 0.9, end: 1.0)
//         .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ScaleTransition(
//       scale: _animation,
//       child: Container(
//         width: 100,
//         height: 100,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 10,
//               spreadRadius: 2,
//             )
//           ],
//         ),
//         child: Icon(Icons.credit_card, size: 40, color: Colors.indigo),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }
