import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreditCardPaymentWidget extends StatefulWidget {
  final double amount;
  final Function() onPaymentSuccess;
  final Function(String) onPaymentError;

  const CreditCardPaymentWidget({
    super.key,
    required this.amount,
    required this.onPaymentSuccess,
    required this.onPaymentError,
  });

  @override
  State<CreditCardPaymentWidget> createState() =>
      _CreditCardPaymentWidgetState();
}

class _CreditCardPaymentWidgetState extends State<CreditCardPaymentWidget> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool useSavedCard = false;
  bool _isProcessing = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Column(
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
          cardType: CardType.visa,
          enableFloatingCard: true,
          isSwipeGestureEnabled: true,
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
        ),
      ],
    );
  }
}

class SavedCardItem extends StatelessWidget {
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SavedCardItem({
    super.key,
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CreditCardWidget(
            cardNumber: cardNumber,
            expiryDate: expiryDate,
            cardHolderName: cardHolderName,
            cvvCode: '',
            showBackView: false,
            isHolderNameVisible: true,
            cardBgColor: isSelected
                ? Colors.indigoAccent.shade400
                : Colors.grey.shade300,
            textStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
            cardType: _getCardType(cardNumber),
            isSwipeGestureEnabled: false,
            onCreditCardWidgetChange: (_) {},
            enableFloatingCard: true,
          ),
        ),
        if (isSelected)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              height: 25,
              width: 25,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
            ),
          ),
        Positioned(
          bottom: 10,
          right: 10,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              height: 25,
              width: 25,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.delete, color: Colors.red, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  CardType _getCardType(String number) {
    if (number.startsWith('4')) return CardType.visa;
    if (number.startsWith('5')) return CardType.mastercard;
    if (number.startsWith('3')) return CardType.americanExpress;
    return CardType.otherBrand;
  }
}
