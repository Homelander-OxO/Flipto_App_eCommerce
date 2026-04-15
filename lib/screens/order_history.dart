// import 'package:flutter/material.dart';
// import 'package:flutter_app/API%20E-Commerce/Screen/order_traking.dart';
// import 'package:flutter_app/utilities/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_app/API%20E-Commerce/api_service.dart';
// import 'package:provider/provider.dart';
//
// class OrderHistoryScreen extends StatefulWidget {
//   final String userId;
//
//   const OrderHistoryScreen({Key? key, required this.userId}) : super(key: key);
//
//   @override
//   _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
// }
//
// class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
//   List<Map<String, dynamic>> _productList = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchOrderTrackingData();
//   }
//
//   void fetchOrderTrackingData() async {
//     final orderHistoryData = await ApiService.fetchTrackingData(widget.userId);
//     if (orderHistoryData != null && orderHistoryData['products'] != null) {
//       setState(() {
//         _productList =
//             List<Map<String, dynamic>>.from(orderHistoryData['products']);
//         _isLoading = false;
//       });
//     } else {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final cartProvider = Provider.of<CartProvider>(context);
//
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: Text('Order History',
//             style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.black),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: ListView.builder(
//                 itemCount: _productList.length,
//                 itemBuilder: (context, index) {
//                   final product = _productList[index];
//                   return SizedBox(
//                     height: 80,
//                     child: Card(
//                       surfaceTintColor: Colors.white,
//                       color: Colors.white,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: ListTile(
//                         leading: ClipRRect(
//                           borderRadius: BorderRadius.circular(6),
//                           child: Image.network(
//                             product['product_image'],
//                             width: 60,
//                             height: 60,
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         title: Text(
//                           product['product_name'],
//                           style: GoogleFonts.poppins(
//                               fontSize: 16, fontWeight: FontWeight.w400),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: Text("₹${product['product_price']}",
//                             style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w500,
//                                  )),
//                         trailing: Icon(Icons.arrow_forward_ios, size: 16),
//                         onTap: () {
//                           final order = cartProvider.oId ?? '';
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => OrderTrackingScreen(
//                                 orderId: order,
//                                 productName: product['product_name'],
//                                 productImage: product['product_image'],
//                                 productPrice: product['product_price'].toString(),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//     );
//   }
// }
