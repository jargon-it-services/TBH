import 'dart:convert';

import 'package:flutter/services.dart';

import 'api_exceptions.dart';
import 'api_response.dart';
import 'env.dart';

/// Shared shape for every `*_api.dart` method: "if [Env.isMock], load a
/// local mock JSON file and branch on its `status` field; otherwise make
/// the real call and branch on `response.statusCode` + `status`; either
/// way, parse `data` into [T] on success, and turn any thrown exception
/// into a safely-messaged [ApiResponse.failure]."
///
/// Every API class previously repeated this exact shape by hand (see the
/// production code review — "Code Duplication" was the top finding).
/// This centralizes it once so each API method only supplies what's
/// actually specific to it: which mock file, which live call, and how
/// to parse the payload. Behavior is unchanged from what each call site
/// did before — this is a mechanical extraction, not a redesign.
///
/// [T] is the parsed success type. [parse] receives the `data` object
/// from either the mock JSON or the live response body.
Future<ApiResponse<T>> callApi<T>({
  required String mockAsset,
  required Future<dynamic> Function() liveCall,
  required T Function(Map<String, dynamic> json) parse,
  required String fallbackErrorMessage,
  Duration mockDelay = const Duration(milliseconds: 500),
}) async {
  try {
    if (Env.isMock) {
      await Future.delayed(mockDelay);

      final String raw = await rootBundle.loadString(mockAsset);
      final Map<String, dynamic> jsonData = json.decode(raw);

      if (jsonData['status'] == true) {
        return ApiResponse.success(parse(jsonData['data']));
      }
      return ApiResponse.failure(
        jsonData['message'] ?? fallbackErrorMessage,
        errorCode: jsonData['error_code'] as String?,
      );
    }

    final response = await liveCall();

    if (response.statusCode == 200 && response.data['status'] == true) {
      return ApiResponse.success(parse(response.data['data']));
    }

    // Preserve the HTTP status code on the failure (not just the
    // message) — callers like DioClient's refresh-token handling need
    // to distinguish "server explicitly said no" (e.g. 401) from other
    // failure shapes.
    return ApiResponse.failure(
      ApiException(
        response.data['message'] ?? fallbackErrorMessage,
        response.statusCode,
      ),
      errorCode: response.data['error_code'] as String?,
    );
  } catch (e) {
    // Preserves ApiException's message/statusCode/isConnectivityError
    // when present (see ApiResponse.failure), instead of collapsing
    // everything to a plain string via e.toString().
    return ApiResponse.failure(e);
  }
}
