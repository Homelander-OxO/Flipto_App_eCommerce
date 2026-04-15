// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_app/API%20E-Commerce/Model/profile_model.dart';
//
// // Function to create ProfileModel from Google User
// ProfileModel getProfileFromGoogleUser(User firebaseUser) {
//   // Split the full name into first and last name
//   String firstName = "";
//   String lastName = "";
//
//   if (firebaseUser.displayName != null) {
//     List<String> nameParts = firebaseUser.displayName!.split(" ");
//     firstName = nameParts[0];  // First part as first name
//     lastName = nameParts.length > 1 ? nameParts.sublist(1).join(" ") : ""; // Join the rest as last name
//   }
//
//   return ProfileModel(
//     id: firebaseUser.uid,
//     firstName: firstName,
//     lastName: lastName,
//     email: firebaseUser.email ?? "",
//     address: "", // Optional, if not available from Google
//     city: "",
//     state: "",
//     country: "",
//     pincode: "",
//     image: firebaseUser.photoURL ?? "",
//     role: "Google User", // You can set a default role
//   );
// }
