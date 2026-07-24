import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

/// ================= PAYMENT RESULT MODEL =================
class RazorpayPaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorMessage;
  final int? errorCode;

  RazorpayPaymentResult.success({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  })  : success = true,
        errorMessage = null,
        errorCode = null;

  RazorpayPaymentResult.failure({
    required this.errorCode,
    required this.errorMessage,
  })  : success = false,
        paymentId = null,
        orderId = null,
        signature = null;
}

/// ================= RAZORPAY SERVICE =================
class RazorpayService {
  late final Razorpay _razorpay;
  Completer<RazorpayPaymentResult>? _paymentCompleter;

  void init() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  Future<RazorpayPaymentResult> startPayment({
    required int amountInRupees,
    required String planName,
    required String orderId, // 🔐 MUST come from backend
  }) {
    _paymentCompleter = Completer<RazorpayPaymentResult>();

    final options = {
      'key': 'rzp_test_0wFRWIZnH65uny',
      'amount': amountInRupees * 100,
      'currency': 'INR',
      'name': 'TBH Business',
      'description': '$planName Subscription',
      // 'order_id': "order_xxxxx",
      'image': 'https://yourdomain.com/logo.png',
      'theme': {'color': '#345995'},
      'prefill': {
        'contact': '9999999999',
        'email': 'user@email.com',
      },
    };

    _razorpay.open(options);
    return _paymentCompleter!.future;
  }

  /// ================= SUCCESS =================
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_paymentCompleter?.isCompleted ?? true) return;

    _paymentCompleter!.complete(
      RazorpayPaymentResult.success(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
      ),
    );
  }

  /// ================= FAILURE =================
  void _handlePaymentError(PaymentFailureResponse response) {
    if (_paymentCompleter?.isCompleted ?? true) return;

    _paymentCompleter!.complete(
      RazorpayPaymentResult.failure(
        errorCode: response.code,
        errorMessage: response.message ?? 'Payment failed',
      ),
    );
  }

  /// ================= WALLET =================
  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional: handle Paytm / PhonePe etc
  }
}
