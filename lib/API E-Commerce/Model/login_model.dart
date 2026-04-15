// class PaymentRequest {
//   final int amountInPaisa;
//   final String orderId;
//
//   PaymentRequest({
//     required this.amountInPaisa,
//     required this.orderId,
//   });
//
//   factory PaymentRequest.fromJson(Map<String, dynamic> json) {
//     return PaymentRequest(
//       amountInPaisa: json['amount'] ?? 0,
//       orderId: json['id'] ?? '',
//     );
//   }
// }