// import 'package:flutter/material.dart';
// import 'package:flutter_app/API%20E-Commerce/Model/e-subcategory_model.dart';
// import 'package:flutter_app/API%20E-Commerce/Screen/product_screen.dart';
// import 'package:flutter_app/API%20E-Commerce/api_service.dart';
//
// class SubcategoryScreen extends StatefulWidget {
//   final String categoryId;
//   final String categoryName;
//
//   SubcategoryScreen({required this.categoryId, required this.categoryName});
//
//   @override
//   _SubcategoryScreenState createState() => _SubcategoryScreenState();
// }
//
// class _SubcategoryScreenState extends State<SubcategoryScreen> {
//   late Future<List<Subcategory>> subcategories;
//   String selectedType = 'All';
//   List<String> subcategoryTypes = ['All'];
//
//   @override
//   void initState() {
//     super.initState();
//     subcategories =
//         ApiService.fetchSubcategories(widget.categoryId).then((data) {
//       /// Extract unique types from fetched subcategories
//       Set<String> types = data.map((e) => e.type).toSet();
//       setState(() {
//         subcategoryTypes.addAll(types); // Add types to filter list
//       });
//       return data;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         centerTitle: true,
//         title: Text(
//           widget.categoryName,
//           style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
//         ),
//         backgroundColor: Colors.grey[50],
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 12),
//           child: Container(
//             // margin: EdgeInsets.all(3),
//             decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.white,
//                 border: Border.all(color: Colors.grey, width: 0.3)),
//             child: IconButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               icon: Icon(Icons.arrow_back_ios_new_rounded),
//             ),
//           ),
//         ),
//       ),
//       body: FutureBuilder<List<Subcategory>>(
//         future: subcategories,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(
//               child: Text(
//                 'Error: ${snapshot.error}',
//                 style: TextStyle(color: Colors.red),
//               ),
//             );
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(
//               child: Text(
//                 'No subcategories available.',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//             );
//           } else {
//             List<Subcategory> subcategoryList = snapshot.data!;
//
//             /// 🔹 **Filter items based on selected subcategory type**
//             List<Subcategory> filteredList = selectedType == 'All'
//                 ? subcategoryList
//                 : subcategoryList
//                     .where((item) => item.type == selectedType)
//                     .toList();
//
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// 🔹 **Sub-Subcategory Type Selector (Horizontal)**
//                 Container(
//                   height: MediaQuery.of(context).size.height / 26,
//                   margin: EdgeInsets.only(top: 10, left: 15),
//                   child: ListView.builder(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: subcategoryTypes.length,
//                     itemBuilder: (context, index) {
//                       String type = subcategoryTypes[index];
//                       bool isSelected = type == selectedType;
//                       return GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             selectedType = type; // Update selected type
//                           });
//                         },
//                         child: Container(
//                           padding:
//                               EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                           margin: EdgeInsets.only(right: 10),
//                           decoration: BoxDecoration(
//                             color: isSelected ? Colors.black : Colors.white,
//                             borderRadius: BorderRadius.circular(7),
//                             border: Border.all(color: Colors.black),
//                           ),
//                           child: Text(
//                             type,
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: isSelected ? Colors.white : Colors.black,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//
//                 /// 🔹 **Filtered Grid of Items**
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 15.0),
//                     child: GridView.builder(
//                        padding: EdgeInsets.all(0),
//                       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 2,
//                         crossAxisSpacing: 1,
//                         mainAxisSpacing: 1,
//                         childAspectRatio: 0.52,
//                       ),
//                       itemCount: filteredList.length,
//                       itemBuilder: (context, index) {
//                         return GestureDetector(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ItemDetailScreen(
//                                   subcategory: filteredList[index],
//                                 ),
//                               ),
//                             );
//                           },
//                           child: Hero(
//                             tag: filteredList[index].name,
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(10),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.grey.withOpacity(0.2),
//                                     spreadRadius: 2,
//                                     blurRadius: 5,
//                                   ),
//                                 ],
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   // Image.network(
//                                   //   filteredList[index].image,
//                                   //   height: 120,
//                                   //   width: double.infinity,
//                                   //   // fit: BoxFit.cover,
//                                   // ),
//                                   Padding(
//                                     padding: const EdgeInsets.all(8.0),
//                                     child: Text(
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                       filteredList[index].name,
//                                       textAlign: TextAlign.center,
//                                       style: TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                   Padding(
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 10),
//                                     child: Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         Text(
//                                           '₹${filteredList[index].price}',
//                                           style: TextStyle(
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.w500,
//                                             color: Colors.black,
//                                           ),
//                                         ),
//                                         SizedBox(
//                                           height: 30,
//                                           child: ElevatedButton(
//                                             style: ElevatedButton.styleFrom(
//                                               elevation: 0,
//                                               backgroundColor: Colors.amber,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(7),
//                                               ),
//                                             ),
//                                             onPressed: () {
//                                               // Add to cart functionality
//                                             },
//                                             child: Text(
//                                               "ADD",
//                                               style: TextStyle(
//                                                   color: Colors.white),
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           }
//         },
//       ),
//     );
//   }
// }
