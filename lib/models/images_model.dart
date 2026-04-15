class CategoryImages {
  // Images for Fashion category
  static const Map<String, String> fashionImages = {
    "Male": "assets/images/man.png",
    "Women": "assets/images/woman.png",
    "Kids": "assets/images/kids.png",
  };

  // Images for Grocery category
  static const Map<String, String> groceryImages = {
    "Fruits": "assets/images/fruits.png",
    "Vegetables": "assets/images/veg.png",
    "DairyProduct": "assets/images/milk.png",
    "Drinks": "assets/images/juice.png",
  };

  // Images for Electronics category
  static const Map<String, String> electronicsImages = {
    "Boat": "assets/images/boat.png",
    // "Aroma": "assets/images/boat.png",
    // "DSLR": "assets/images/boat.png",
    "HP": "assets/images/hp.png",
    "DELL": "assets/images/dell.png",
    "Coocaa": "assets/images/coocaa.png",
    "MOTOROLA": "assets/images/motorola.png",
  };

  // Images for H&F category
  static const Map<String, String> handfImages = {
    "Wardrobe": "assets/images/wardrobe.png",
    "Bed": "assets/images/bed.png",
    "Accessories": "assets/images/accessories.png",
  };

  // Default image
  static const String defaultImage = "assets/images/image (1).png";

  // Helper function to fetch images for the given category
  static Map<String, String> getImages(String categoryName) {
    switch (categoryName) {
      case "Fashion":
        return fashionImages;
      case "Grocery":
        return groceryImages;
      case "Electronics":
        return electronicsImages;
      case "Home & Furnitures":
        return handfImages;
      default:
        return {};
    }
  }
}
