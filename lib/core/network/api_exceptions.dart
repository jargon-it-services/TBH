import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  /// True when this failure is specifically due to no internet
  /// connectivity — either detected before the request was even sent
  /// (see DioClient's pre-flight check) or surfaced by Dio as a
  /// connectionError mid-request. Lets UI code skip showing its own
  /// "no internet" snackbar/toast when the global ConnectivityBanner
  /// already communicates the same thing, instead of both firing at once.
  final bool isConnectivityError;

  ApiException(
    this.message, [
    this.statusCode,
    this.isConnectivityError = false,
  ]);

  factory ApiException.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException("Connection timeout");
      case DioExceptionType.badResponse:
        return ApiException(
          e.response?.data?['message'] ?? "Server error",
          e.response?.statusCode,
        );
      case DioExceptionType.connectionError:
        return ApiException("No internet connection", null, true);
      default:
        return ApiException("Unexpected error occurred");
    }
  }

  @override
  String toString() => message;
}
