import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload for a successful logout call.
class LogoutResult {
  final String message;

  LogoutResult({required this.message});

  factory LogoutResult.fromJson(Map<String, dynamic> json) {
    return LogoutResult(
      message: json['message'] ?? 'Logged out successfully',
    );
  }
}

/// Logout API — uses the shared [callApi] helper (mock/live branching +
/// ApiResponse<T> wrapping) so the rest of the app doesn't need a new
/// pattern.
///
/// This is a protected endpoint (unlike login/register/forgot-password):
/// it is deliberately NOT added to DioClient's public-paths list, so the
/// current access token is attached automatically as the Authorization
/// header, exactly the way every other protected call already works.
///
/// BACKEND CONTRACT (endpoint does not exist yet — see
/// docs/logout_backend_contract.md for the full spec this was written
/// against):
///
///   POST /auth/logout
///   Headers:       Authorization: Bearer <current access token>
///   200 response:  { "status": true,  "data": { "message": "Logged out successfully" } }
///   401 response:  { "status": false, "message": "Invalid or expired token" }
///
/// Until that endpoint ships, `Env.isMock` is honored exactly like every
/// other *_api.dart file, loading a local mock JSON response instead of
/// hitting the network.
class LogoutApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_003 - Logout
  // Endpoint: POST /auth/logout
  // Backend Doc Ref: API_003
  // ==========================================================
  Future<ApiResponse<LogoutResult>> logout() {
    return callApi<LogoutResult>(
      mockAsset: 'assets/mocks/logout_response.json',
      liveCall: () => _client.post('/auth/logout'),
      parse: LogoutResult.fromJson,
      fallbackErrorMessage: 'Logout failed',
    );
  }
}
