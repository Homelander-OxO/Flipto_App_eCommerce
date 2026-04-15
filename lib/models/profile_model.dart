class ProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String image;
  final String role;

  ProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.image,
    required this.role,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json["user_id"] ?? "",
      firstName: json["firstName"] ?? "",
      lastName: json["lastName"] ?? "",
      email: json["email"] ?? "",
      address: json["address"] ?? "",
      city: json["city"] ?? "",
      state: json["state"] ?? "",
      country: json["country"] ?? "",
      pincode: json["pincode"] ?? "",
      image: json["image"] ?? "",
      role: json["role"] ?? "",
    );
  }
}

class GoogleModel {
  final String name;
  final String email;
  final String image;

  GoogleModel({
    required this.name,
    required this.email,
    required this.image,
  });

  factory GoogleModel.fromJson(Map<String, dynamic> json) {
    return GoogleModel(
      name: json["name"] ?? "",
      email: json["email"] ?? "",
      image: json["picture"] ?? "",
    );
  }
  /// **Convert `GoogleModel` to JSON (for SharedPreferences)**
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "picture": image, // Keep key consistent with API response
    };
  }
}

class UserModel {
  final String name;
  final String email;
  String? contact;
  String? address;

  UserModel({
    required this.name,
    required this.email,
    this.contact,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json["name"] ?? "Unknown User",
      email: json["email"] ?? "No Email",
      contact: json["contact"] ?? "No Email",
      address: json["address"] ?? "No Email",
    );
  }

}

class UserDetailsModel {
  final String userId;
  final String fullName;
  final String email;
  final String contact;
  final String address;
  final String image;

  UserDetailsModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.contact,
    required this.address,
    required this.image,
  });

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    return UserDetailsModel(
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      image: json['image'] ?? '',
      contact: json['contact'] ?? '',
      address: json['address'] ?? '',
    );
  }
}
