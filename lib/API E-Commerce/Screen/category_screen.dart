import 'package:flutter/material.dart';
import 'package:flutter_app/API%20E-Commerce/Model/e-category_model.dart';
import 'package:flutter_app/API%20E-Commerce/Screen/gender_category.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/custom_widgets/cart_badge.dart';
import 'package:flutter_app/custom_widgets/custom_route.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;

  const CategoryScreen({super.key, required this.category});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<Category>> categories;

  @override
  void initState() {
    super.initState();
    // Fetch categories from the API
    categories = ApiService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Categories",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.grey[50],
        actions: [CartIconWithBadge()],
      ),
      body: FutureBuilder<List<Category>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No categories available"));
          } else {
            List<Category> categoryList = snapshot.data!;
            return SizedBox(
              height: 120, // Adjust height based on your design
              child: ListView.builder(
                scrollDirection: Axis.horizontal, // Make it horizontal
                itemCount: categoryList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      // Navigate to Subcategory screen with selected category
                      Navigator.push(
                        context,
                        CustomCupertinoPageRoute(
                          builder: (context) => GenderCategory(
                            categoryId: categoryList[index].id,
                            categoryName: categoryList[index].name,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 100, // Adjust width
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            // Rounded corners
                            child: Image.network(
                              categoryList[index].image,
                              height: 80, // Adjust size
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            categoryList[index].name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}
