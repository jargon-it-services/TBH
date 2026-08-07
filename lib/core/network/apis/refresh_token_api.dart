import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload for a successful token refresh.
class RefreshTokenResult {
  final String authToken;
  final String? refreshToken;

  RefreshTokenResult({required this.authToken, this.refreshToken});

  factory RefreshTokenResult.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResult(
      authToken: json['token'] ?? '',
      refreshToken: json['refresh_token'],
    );
  }
}

/// Refresh Token API — uses the shared [callApi] helper (mock/live
/// branching + ApiResponse<T> wrapping) so the rest of the app doesn't
/// need a new pattern. Also gives callers (see [DioClient]) access to
/// the real HTTP status code of a failure via [ApiResponse.statusCode],
/// which matters here specifically: only an explicit 401 means the
/// refresh token was rejected — anything else (timeout, no
/// connectivity, 5xx) is a transient failure, not a verdict on the
/// session.
///
/// BACKEND CONTRACT (endpoint does not exist yet — see
/// docs/refresh_token_backend_contract.md for the full spec this was
/// written against):
///
///   POST /auth/refresh
///   Request body:  { "refresh_token": "<current refresh token>" }
///   200 response:  { "status": true,  "data": { "token": "<new_jwt>", "refresh_token": "<new_refresh_token>" } }
///   401 response:  { "status": false, "message": "Refresh token invalid or expired" }
///
/// Until that endpoint ships, `Env.isMock` is honored exactly like every
/// other *_api.dart file, loading a local mock JSON response instead of
/// hitting the network.
class RefreshTokenApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_002 - Refresh Token
  // Endpoint: POST /auth/refresh
  // Backend Doc Ref: API_002
  // ==========================================================
  Future<ApiResponse<RefreshTokenResult>> refresh({
    required String refreshToken,
  }) {
    return callApi<RefreshTokenResult>(
      mockAsset: 'assets/mocks/refresh_token_response.json',
      liveCall: () => _client.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      ),
      parse: RefreshTokenResult.fromJson,
      fallbackErrorMessage: 'Session expired. Please log in again.',
    );
  }
}
