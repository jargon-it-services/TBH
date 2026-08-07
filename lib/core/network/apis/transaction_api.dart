import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../services/DataModels/transaction_details_model.dart';
import '../../services/DataModels/transaction_entry_models.dart';
import '../../services/DataModels/transaction_list_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';
import '../env.dart';

class TransactionApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_049 - Fetch Transaction Bootstrap
  // Endpoint: GET /transactions/bootstrap
  // Backend Doc Ref: API_049
  // ==========================================================
  /// GET /transactions/bootstrap — everything the Transaction Entry
  /// screen needs (services/expenses/staff/branches/role/last-used
  /// prefs) in one call. Fetched once per screen open, per the
  /// "Performance Requirements" spec — never re-fetched on every
  /// qty/service change.
  Future<ApiResponse<TransactionBootstrapData>> fetchBootstrap() {
    return callApi<TransactionBootstrapData>(
      mockAsset: 'assets/mocks/transactions_bootstrap_response.json',
      liveCall: () => _client.get('/transactions/bootstrap'),
      parse: (data) => TransactionBootstrapData.fromJson(data),
      fallbackErrorMessage: "We couldn't load transaction data right now.",
    );
  }

  // ==========================================================
  // API_050 - Create Transaction
  // Endpoint: POST /transactions
  // Backend Doc Ref: API_050
  // ==========================================================
  /// POST /transactions — create. `idempotency_key` is generated once
  /// per screen-open by the caller (see
  /// `TransactionEntryPage._idempotencyKey`) and resent unchanged on
  /// every retry of the *same* transaction, so a duplicate request
  /// (double-submit, an HTTP client's automatic retry-on-timeout, or a
  /// crash-and-reopen) resolves to the backend's original record
  /// instead of a second one.
  Future<ApiResponse<TransactionSaveResult>> createTransaction(
    Map<String, dynamic> payload,
  ) {
    return callApi<TransactionSaveResult>(
      mockAsset: 'assets/mocks/transaction_save_response.json',
      liveCall: () => _client.post('/transactions', data: payload),
      parse: (data) => TransactionSaveResult.fromJson(data),
      fallbackErrorMessage: 'Failed to save transaction',
    );
  }

  // ==========================================================
  // API_051 - Update Transaction
  // Endpoint: PUT /transactions/{id}
  // Backend Doc Ref: API_051
  // ==========================================================
  /// PUT /transactions/{id} — edit, within the backend-enforced window.
  /// A `409` here (window closed since the Edit screen was opened) still
  /// comes back as a normal [ApiResponse.failure] with `statusCode: 409`
  /// set (see [ApiException.fromDioError]) — callers branch on that
  /// specific code to show the distinct "can no longer be edited"
  /// message rather than a generic save error.
  Future<ApiResponse<TransactionSaveResult>> updateTransaction(
    String transactionId,
    Map<String, dynamic> payload,
  ) {
    return callApi<TransactionSaveResult>(
      mockAsset: 'assets/mocks/transaction_save_response.json',
      liveCall: () => _client.put('/transactions/$transactionId', data: payload),
      parse: (data) => TransactionSaveResult.fromJson(data),
      fallbackErrorMessage: 'Failed to update transaction',
    );
  }

  // ==========================================================
  // API_052 - Mark Transaction Paid
  // Endpoint: POST /transactions/{id}/mark-paid
  // Backend Doc Ref: API_052
  // ==========================================================
  /// POST /transactions/{id}/mark-paid — settles a Pending transaction.
  /// Deliberately separate from [updateTransaction]: only ever changes
  /// `status`/`paid_at`, never gated by the edit window (see the
  /// module spec's "Settling a Pending Transaction").
  Future<ApiResponse<TransactionMarkPaidResult>> markAsPaid(String transactionId) {
    return callApi<TransactionMarkPaidResult>(
      mockAsset: 'assets/mocks/transaction_mark_paid_response.json',
      liveCall: () => _client.post('/transactions/$transactionId/mark-paid', data: {}),
      parse: (data) => TransactionMarkPaidResult.fromJson(data),
      fallbackErrorMessage: 'Failed to mark transaction as paid',
    );
  }

  // ==========================================================
  // API_053 - Fetch Transactions List
  // Endpoint: GET /transactions
  // Backend Doc Ref: API_053
  // ==========================================================
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

  // ==========================================================
  // API_054 - Fetch Transaction Details
  // Endpoint: GET /transactions/{id}
  // Backend Doc Ref: API_054
  // ==========================================================
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
