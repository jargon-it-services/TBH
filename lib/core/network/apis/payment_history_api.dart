import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../services/DataModels/payment_details_model.dart';
import '../../services/DataModels/payment_history_model.dart';
import '../api_response.dart';
import '../dio_client.dart';
import '../env.dart';

/// API service for the Payment History feature.
///
/// Deliberately a plain, single-purpose class with the same shape as
/// every other `*_api.dart` file (`TransactionApi`, `SubscriptionApi`,
/// ...): a `DioClient` singleton, an `Env.isMock` branch per method
/// loading a local JSON fixture, and a live branch calling the real
/// endpoint. No new networking pattern is introduced.
class PaymentHistoryApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_060 - Fetch Payment History
  // Endpoint: GET /api/v1/payments/history
  // Backend Doc Ref: API_060
  // ==========================================================
  /// `GET /api/v1/payments/history` -- returns the full, unpaginated,
  /// unfiltered list. Per the feature contract there is no server-side
  /// search/pagination/filtering, so this is the only call the Payment
  /// History screen ever makes; search and status-chip filtering both
  /// happen locally against the list this returns.
  Future<ApiResponse<PaymentHistoryResponse>> fetchPaymentHistory() async {
    try {
      if (Env.isMock) {
        // simulate network delay
        await Future.delayed(const Duration(seconds: 2));

        final String response = await rootBundle
            .loadString('assets/mocks/payment_history_response.json');

        final Map<String, dynamic> jsonData = json.decode(response);

        return ApiResponse.success(PaymentHistoryResponse.fromJson(jsonData));
      } else {
        final Response response = await _client.get('/api/v1/payments/history');

        if (response.statusCode == 200 && response.data['success'] == true) {
          return ApiResponse.success(
            PaymentHistoryResponse.fromJson(response.data),
          );
        } else {
          return ApiResponse.failure(
            response.data?['message'] ?? 'Failed to load payment history',
          );
        }
      }
    } catch (e) {
      // Preserves ApiException's isConnectivityError/statusCode instead
      // of collapsing it to a plain string — see ApiResponse.failure.
      return ApiResponse.failure(e);
    }
  }

  // ==========================================================
  // API_061 - Fetch Payment Details
  // Endpoint: GET /api/v1/payments/{id}
  // Backend Doc Ref: API_061
  // ==========================================================
  /// `GET /api/v1/payments/{id}` -- always fetched fresh (the Details
  /// screen never receives more than the id from the list screen), so
  /// this is called independently every time the details screen opens.
  Future<ApiResponse<PaymentDetailsResponse>> fetchPaymentDetails({
    required String paymentId,
  }) async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(seconds: 1));

        final String response = await rootBundle
            .loadString('assets/mocks/payment_details_response.json');

        final Map<String, dynamic> jsonData = json.decode(response);

        // The mock fixture is keyed by transaction id so tapping
        // different rows in the (mock) list shows different detail
        // data, falling back to a generic "default" entry for any id
        // not explicitly present in the fixture.
        final Map<String, dynamic> entry =
            jsonData[paymentId] ?? jsonData['default'];

        return ApiResponse.success(PaymentDetailsResponse.fromJson(entry));
      } else {
        final Response response = await _client.get(
          '/api/v1/payments/$paymentId',
        );

        if (response.statusCode == 200 && response.data?['success'] == true) {
          return ApiResponse.success(
            PaymentDetailsResponse.fromJson(response.data),
          );
        }

        return ApiResponse.failure(
          response.data?['message'] ?? 'Failed to load payment details',
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }
}
