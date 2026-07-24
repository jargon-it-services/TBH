import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../services/DataModels/transaction_details_model.dart';
import '../../services/DataModels/transaction_list_model.dart';
import '../api_response.dart';
import '../dio_client.dart';
import '../env.dart';

class TransactionApi {
  final DioClient _client = DioClient();

  /// Fetch all transactions list (no pagination, no filters)
  Future<ApiResponse<TransactionsResponse>> fetchTransactions() async {
    try {
      if (Env.isMock) {
        // simulate network delay
        await Future.delayed(const Duration(seconds: 2));

        // load local JSON mock
        final String response = await rootBundle
            .loadString('assets/mocks/transactions_list_response.json');

        final Map<String, dynamic> jsonData = json.decode(response);

        final transactions = TransactionsResponse.fromJson(jsonData);

        return ApiResponse.success(transactions);
      } else {
        final Response response = await _client.get('/transactions');

        if (response.statusCode == 200 && response.data['status'] == true) {
          return ApiResponse.success(
            TransactionsResponse.fromJson(response.data),
          );
        } else {
          return ApiResponse.failure('Failed to load transactions');
        }
      }
    } catch (e) {
      // Preserves ApiException's isConnectivityError/statusCode instead
      // of collapsing it to a plain string — see ApiResponse.failure.
      return ApiResponse.failure(e);
    }
  }

  /// Fetch transaction details by ID
  Future<ApiResponse<TransactionDetailsResponse>> fetchTransactionDetails({
    required String transactionId,
  }) async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(seconds: 1));

        final String response = await rootBundle.loadString(
          'assets/mocks/transaction_detail.json',
        );

        final Map<String, dynamic> jsonData = json.decode(response);

        return ApiResponse.success(
          TransactionDetailsResponse.fromJson(jsonData),
        );
      } else {
        final Response response = await _client.get(
          '/transactions/$transactionId',
        );

        if (response.statusCode == 200 && response.data?['status'] == true) {
          return ApiResponse.success(
            TransactionDetailsResponse.fromJson(response.data['data']),
          );
        }

        return ApiResponse.failure(
          response.data?['message'] ?? 'Failed to load transaction details',
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }
}
