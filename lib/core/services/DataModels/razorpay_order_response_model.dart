class RazorpayOrderResponse {
  final String orderId;
  final int amount;
  final String currency;
  final String key; // Razorpay public key

  RazorpayOrderResponse({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.key,
  });

  factory RazorpayOrderResponse.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderResponse(
      orderId: json['orderId'],
      amount: json['amount'],
      currency: json['currency'],
      key: json['key'] ?? '',
    );
  }
}
