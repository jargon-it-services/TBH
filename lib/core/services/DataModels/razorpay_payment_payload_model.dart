class RazorpayPaymentPayload {
  final String orderId;
  final String? paymentId;
  final String? signature;

  /// SUCCESS | FAILED | CANCELLED | ERROR
  final String status;

  /// Razorpay error fields
  final int? errorCode;
  final String? errorDescription;
  final String? errorSource;
  final String? errorStep;
  final String? errorReason;

  /// Metadata
  final int amount;
  final String planId;
  final String platform; // android / ios / web
  final DateTime createdAt;

  RazorpayPaymentPayload({
    required this.orderId,
    required this.status,
    required this.amount,
    required this.planId,
    required this.platform,
    required this.createdAt,
    this.paymentId,
    this.signature,
    this.errorCode,
    this.errorDescription,
    this.errorSource,
    this.errorStep,
    this.errorReason,
  });

  Map<String, dynamic> toJson() {
    return {
      "orderId": orderId,
      "paymentId": paymentId,
      "signature": signature,
      "status": status,
      "amount": amount,
      "planId": planId,
      "platform": platform,
      "error": {
        "code": errorCode,
        "description": errorDescription,
        "source": errorSource,
        "step": errorStep,
        "reason": errorReason,
      },
      "createdAt": createdAt.toIso8601String(),
    };
  }
}
