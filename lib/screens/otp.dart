import 'package:flutter/material.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

class OtpLoginScreen extends StatefulWidget {
  @override
  _OtpLoginScreenState createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isOtpSent = false;

  Future<void> _sendOtp() async {
    final email = _emailController.text;
    String? googleName = Provider.of<CartProvider>(context, listen: false).name;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse('http://192.168.1.160/Apis/generateOtp');
    try {
      final response = await http.post(
        url,
        body: {
          'email': email,
          'full_name': "Hiren",
        },
      );
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body == 'Success') {
          setState(() {
            _isOtpSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send OTP: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("Server returned non-200 status code: ${response.statusCode}");
      }
    } catch (error) {
      print('Error sending OTP: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text;

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse('http://192.168.1.160/Apis/verifyOtp');
    try {
      final response = await http.post(
        url,
        body: {
          'email': _emailController.text,
          'otp': otp,
        },
      );

      print('Response: ${response.body}');
      if (response.statusCode == 200) {
        if (response.body == 'Verified') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to the home screen or another screen after successful verification
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP verification failed: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      print('Error verifying OTP: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
               decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendOtp,
              child: const Text('Send OTP'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
