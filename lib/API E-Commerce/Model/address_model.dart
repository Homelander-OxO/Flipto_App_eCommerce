// address_model.dart
class Address {
  final String indexKey; // The key from the API response ("0", "1", etc.)
  final String apartmentNo;
  final String street;
  final String area;
  final String city;
  final String pincode;
  final String contact;

  Address({
    required this.indexKey,
    required this.apartmentNo,
    required this.street,
    required this.area,
    required this.city,
    required this.pincode,
    required this.contact,
  });

  factory Address.fromJson(String indexKey, Map<String, dynamic> json) {
    return Address(
      indexKey: indexKey,
      apartmentNo: json["apartment_no"] ?? "",
      street: json["street"] ?? "",
      area: json["area"] ?? "",
      city: json["city"] ?? "",
      pincode: json["pincode"] ?? "",
      contact: json["contact"] ?? "",
    );
  }
}