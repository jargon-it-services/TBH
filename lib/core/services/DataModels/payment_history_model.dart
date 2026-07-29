/// Data models for `GET /api/v1/payments/history`.
///
/// Mirrors the exact conventions already used by
/// `transaction_list_model.dart`: every `fromJson` falls back to a safe
/// default instead of throwing, so a null/missing field from the API
/// degrades gracefully in the UI rather than crashing the screen.
class PaymentHistoryResponse {
  final bool success;
  final String message;
  final String currency;
  final List<PaymentSummary> payments;

  PaymentHistoryResponse({
    required this.success,
    required this.message,
    required this.currency,
    required this.payments,
  });

  factory PaymentHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return PaymentHistoryResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      currency: data['currency'] ?? 'INR',
      payments: (data['payments'] as List? ?? [])
          .map((e) => PaymentSummary.fromJson(e))
          .toList(),
    );
  }
}

/// One row in the Payment History list / one Transaction Card.
class PaymentSummary {
  final String id;
  final DateTime? date;
  final String dateDisplay;
  final String branch;
  final String branchCode;
  final String paymentType;
  final String paymentMethod;
  final double amount;
  final String formattedAmount;
  final String status;

  PaymentSummary({
    required this.id,
    required this.date,
    required this.dateDisplay,
    required this.branch,
    required this.branchCode,
    required this.paymentType,
    required this.paymentMethod,
    required this.amount,
    required this.formattedAmount,
    required this.status,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    final dateTime = json['dateTime'] ?? {};
    final branchInfo = json['branch'] ?? {};

    return PaymentSummary(
      id: json['id'] ?? '',
      date: DateTime.tryParse(dateTime['iso'] ?? ''),
      dateDisplay: dateTime['display'] ?? '',
      branch: branchInfo['name'] ?? '',
      branchCode: branchInfo['code'] ?? '',
      paymentType: json['paymentType'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      // API-formatted amount is used for display wherever present;
      // `amount` (numeric) is kept only for sorting/analytics use, not
      // rendered directly (see currency_utils.dart doc on preferring
      // API-formatted values over locally reformatting numbers).
      formattedAmount: json['formattedAmount'] ?? '₹${json['amount'] ?? 0}',
      status: (json['status'] ?? '').toString().toLowerCase(),
    );
  }
}
