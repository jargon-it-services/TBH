import 'api_exceptions.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  /// True when [error] specifically represents "no internet", derived
  /// from an [ApiException] passed to [failure]. Lets calling screens
  /// decide not to show their own error popup on top of the global
  /// ConnectivityBanner for this specific case.
  final bool isConnectivityError;

  /// The HTTP status code behind this failure, when known — carried
  /// over from an [ApiException]'s `statusCode`. Null for a plain
  /// `String`/other error, or when the failure never reached the
  /// server (timeout, no connectivity). Lets callers distinguish an
  /// explicit server verdict (e.g. 401 "invalid credentials/token")
  /// from a transient/network failure, where treating the two the same
  /// would be wrong (see DioClient's refresh-token handling).
  final int? statusCode;

  /// Backend-supplied machine-readable failure reason, when present
  /// (e.g. `"invite_expired"`). Optional and additive — populated only
  /// when the server response includes an `error_code` field (see
  /// [callApi]); every existing caller that never reads this continues
  /// to work unchanged. Currently consumed by [RegistrationApi] to
  /// decide whether a failed registration should keep or clear the
  /// stored invite token.
  final String? errorCode;

  ApiResponse._({
    this.data,
    this.error,
    required this.isSuccess,
    this.isConnectivityError = false,
    this.statusCode,
    this.errorCode,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
    );
  }

  /// Builds a failure response, preserving the real message wherever one
  /// is available instead of discarding it:
  /// - a plain `String` (the common case — every `*_api.dart` file's
  ///   mock/live branches pass the backend's own `message` field) is
  ///   used as-is.
  /// - an [ApiException] (thrown by [DioClient.get]/[post] on a network
  ///   error) uses its `.message`, and its `isConnectivityError` and
  ///   `statusCode` carry through onto this response.
  /// - any other [Exception]/[Error] falls back to `toString()`.
  /// - anything else (shouldn't normally happen) gets a generic,
  ///   user-safe fallback rather than leaking an internal representation.
  factory ApiResponse.failure(Object error, {String? errorCode}) {
    final String message;
    bool isConnectivityError = false;
    int? statusCode;

    if (error is ApiException) {
      message = error.message;
      isConnectivityError = error.isConnectivityError;
      statusCode = error.statusCode;
    } else if (error is String) {
      message = error;
    } else if (error is Exception || error is Error) {
      message = error.toString();
    } else {
      message = 'Oops! We couldn’t load the data. Please try again.';
    }

    return ApiResponse._(
      error: message,
      isSuccess: false,
      isConnectivityError: isConnectivityError,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }
}
