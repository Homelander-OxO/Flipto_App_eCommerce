import 'package:flutter/material.dart';
import 'package:flutter_app/screens/payment_screen.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';
import 'package:provider/provider.dart';

class ContactAddressScreen extends StatefulWidget {
  final String email;
  final String contact;
  final String address;

  const ContactAddressScreen({
    Key? key,
    required this.email,
    required this.contact,
    required this.address,
  }) : super(key: key);

  @override
  _ContactAddressScreenState createState() => _ContactAddressScreenState();
}

class _ContactAddressScreenState extends State<ContactAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _contactController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  bool _isButtonVisible = false;

  void _updateButtonVisibility() {
    setState(() {
      _isButtonVisible = _contactController.text.isNotEmpty &&
          _addressController.text.isNotEmpty;
    });
  }

  void _submitForm() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<CartProvider>(context, listen: false);
      final email = userProvider.useremail ?? userProvider.email ?? '';
      final contact = _contactController.text;
      final address = _addressController.text;

      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User email not found. Please log in again.")),
        );
        return;
      }

      // await ApiService.updateUser(email, contact, address);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User details updated successfully!')),
      );

      // Store contact & address in Provider for later use
      userProvider.updateUserContactAddress(contact, address);

      // // Navigate to Payment Screen
      // Navigator.pushReplacement(
      //   context,
      //   CustomCupertinoPageRoute(
      //     builder: (context) => RazorPay(
      //       amount: cartProvider.getTotalPrice(),
      //       cartProvider: cartProvider,
      //     ),
      //   ),
      // );
    }
  }

  @override
  void initState() {
    super.initState();
    _contactController = TextEditingController(text: widget.contact);
    _addressController = TextEditingController(text: widget.address);

    _contactController.addListener(_updateButtonVisibility);
    _addressController.addListener(_updateButtonVisibility);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<CartProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final userData = cartProvider.userDetails;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        centerTitle: true,
        title: Text('User Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 30,
            children: [
              TextFormField(
                initialValue: userData?.fullName,
                // ✅ Now this will show the name
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                readOnly: true,
              ),
              TextFormField(
                initialValue: userProvider.useremail,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                readOnly: true,
              ),
              TextFormField(
                // initialValue: userData?.contact,
                controller: _contactController,
                decoration: InputDecoration(
                  labelText: 'Contact',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                // initialValue: userData?.address,

                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 20),
              _isButtonVisible
                  ? ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Submit'),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
