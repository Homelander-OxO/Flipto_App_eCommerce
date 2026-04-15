// import 'dart:convert';
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;
//
// class AuthProvider {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   // final GoogleSignIn _googleSignIn = GoogleSignIn();
//   //
//   // // 🔹 Google Sign-In Method
//   // Future<User?> signInWithGoogle() async {
//   //   try {
//   //     // Step 1: Start the Google Sign-In flow
//   //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//   //     if (googleUser == null) return null; // If user cancels login
//   //
//   //     // Step 2: Obtain Google Sign-In authentication details
//   //     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//   //
//   //     // Step 3: Create new credential for Firebase authentication
//   //     final AuthCredential credential = GoogleAuthProvider.credential(
//   //       accessToken: googleAuth.accessToken,
//   //       idToken: googleAuth.idToken,
//   //     );
//   //
//   //     // Step 4: Sign in with the credential
//   //     final UserCredential userCredential = await _auth.signInWithCredential(credential);
//   //     return userCredential.user;
//   //   } catch (error) {
//   //     print("❌ Google Sign-In Error: $error");
//   //     return null;
//   //   }
//   // }
//
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email'],
//     serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com', // Replace with your actual Web Client ID
//   );
//
//   Future<void> signInWithGoogle() async {
//     try {
//       // Start the Google Sign-In process
//       GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//
//       if (googleUser == null) {
//         print("Sign-in canceled by user.");
//         return;
//       }
//
//       // Obtain the authentication details
//       GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//
//       // Retrieve the ID token
//       String? idToken = googleAuth.idToken;
//       print("Google ID Token: $idToken");
//
//       if (idToken != null) {
//         // Send the token to the backend for verification
//         await _sendTokenToBackend(idToken);
//       } else {
//         print("Failed to retrieve ID token.");
//       }
//     } catch (e) {
//       print("Error signing in: $e");
//     }
//   }
//
//   Future<void> _sendTokenToBackend(String idToken) async {
//     final response = await http.post(
//       Uri.parse('http://192.168.1.160/Apis/googleSignIn'),
//       headers: {'Content-Type': 'application/json'},
//       body: json.encode({'id_token': idToken}),  // Encoding the token into JSON
//     );
//
//     if (response.statusCode == 200) {
//       print("Token sent successfully to backend.");
//       print("Response: ${response.body}");
//     } else {
//       print("Failed to send token. Status code: ${response.statusCode}");
//       print("Response: ${response.body}");
//     }
//   }
//   // 🔹 Logout from Google
//   Future<void> signOut() async {
//     await _googleSignIn.signOut();
//     await _auth.signOut();
//   }
// }
