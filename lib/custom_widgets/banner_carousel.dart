import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MyBannerCarousel extends StatefulWidget {
  const MyBannerCarousel({super.key});

  @override
  _MyBannerCarouselState createState() => _MyBannerCarouselState();
}

class _MyBannerCarouselState extends State<MyBannerCarousel> {
  int _currentIndex = 0;

  final List<String> imagePaths = [
    "assets/images/cb4.jpg",
    "assets/images/cb3.jpg",
    // "assets/images/cb5.jpg",
    "assets/images/cb7.jpg",
    "assets/images/cb9.jpg",
    "assets/images/cb10.jpg",
    "assets/images/cb12.jpg",
    "assets/images/cb11.jpg",
    "assets/images/cb1.jpg",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height / 4.5,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: imagePaths.map((imagePath) {
            return Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  // Space between items
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),

        // Dots indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedSmoothIndicator(
            activeIndex: _currentIndex,
            count: imagePaths.length,
            effect: ExpandingDotsEffect(
              dotWidth: 7,
              dotHeight: 5,
              activeDotColor: Color(0xff101d42),
              dotColor: Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }
}
