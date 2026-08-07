import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../services/DataModels/razorpay_order_response_model.dart';
import '../../services/DataModels/razorpay_payment_payload_model.dart';
import '../api_response.dart';
import '../dio_client.dart';
import '../env.dart';

class RazorpayApiService {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_062 - Create Razorpay Order
  // Endpoint: POST /payments/razorpay/order
  // Backend Doc Ref: API_062
  // ==========================================================
  /// ----------------------------------------
  /// 1️⃣ Create Razorpay Order (Backend / Mock)
  /// ----------------------------------------
  Future<ApiResponse<RazorpayOrderResponse>> createOrder({
    required int amountInPaise,
    required String planId,
    required String currency,
  }) async {
    try {
      if (Env.isMock) {
        // ⏳ simulate network delay
        await Future.delayed(const Duration(seconds: 2));

        // 📦 load mock JSON
        final String response = await rootBundle.loadString(
          'assets/mocks/razorpay_create_order_response.json',
        );

        final Map<String, dynamic> jsonData = json.decode(response);

        return ApiResponse.success(
          RazorpayOrderResponse.fromJson(
            jsonData['data'],
          ),
        );
      } else {
        final Response response = await _client.post(
          '/payments/razorpay/order',
          data: {
            "amount": amountInPaise,
            "currency": currency,
            "planId": planId,
          },
        );

        return ApiResponse.success(
          RazorpayOrderResponse.fromJson(response.data['data']),
        );
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // ==========================================================
  // API_063 - Save Razorpay Payment Result
  // Endpoint: POST /payments/razorpay/result
  // Backend Doc Ref: API_063
  // ==========================================================
  /// -------------------------------------------------
  /// 2️⃣ Save Razorpay Payment Result (ALL CASES)
  /// -------------------------------------------------
  Future<ApiResponse<void>> savePaymentResult({
    required RazorpayPaymentPayload payload,
  }) async {
    try {
      if (Env.isMock) {
        // ⏳ simulate network delay
        await Future.delayed(const Duration(seconds: 1));

        // ✅ optionally log payload for debugging
        // debugPrint('Mock Razorpay payload: ${payload.toJson()}');

        // No backend call in mock
        return ApiResponse.success(null);
      } else {
        await _client.post(
          '/payments/razorpay/result',
          data: payload.toJson(),
        );

        return ApiResponse.success(null);
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
