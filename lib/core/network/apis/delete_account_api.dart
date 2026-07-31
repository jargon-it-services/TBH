import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload for a successful account-deletion call.
class DeleteAccountResult {
  final String message;

  DeleteAccountResult({required this.message});

  factory DeleteAccountResult.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResult(
      message: json['message'] ?? 'Account deleted successfully',
    );
  }
}

/// Delete Account API — uses the shared [callApi] helper (mock/live
/// branching + `ApiResponse<T>` wrapping), exactly like [LogoutApi] and
/// [ProfileApi], so this doesn't introduce a new calling pattern.
///
/// This is a protected endpoint: it is deliberately NOT added to
/// `DioClient`'s public-paths list, so the current access token is
/// attached automatically as the Authorization header, and it goes
/// through the same refresh/auto-logout handling as every other
/// protected call.
///
/// TODO(backend): This endpoint does not exist yet. Written against the
/// same contract shape as [LogoutApi] (see
/// docs/logout_backend_contract.md for that precedent):
///
///   POST /user/delete-account
///   Headers:       Authorization: Bearer <current access token>
///   200 response:  { "status": true,  "data": { "message": "Account deleted successfully" } }
///   4xx response:  { "status": false, "message": "<reason>" }
///
/// Until that endpoint ships, `Env.isMock` is honored exactly like every
/// other `*_api.dart` file, loading a local mock JSON response
/// (assets/mocks/delete_account_response.json) instead of hitting the
/// network. Once the real endpoint exists, only the path/contract below
/// needs updating — callers (AccountPage) don't change.
class DeleteAccountApi {
  final DioClient _client = DioClient();

  Future<ApiResponse<DeleteAccountResult>> deleteAccount() {
    return callApi<DeleteAccountResult>(
      mockAsset: 'assets/mocks/delete_account_response.json',
      liveCall: () => _client.post('/user/delete-account'),
      parse: DeleteAccountResult.fromJson,
      fallbackErrorMessage: 'Could not delete your account. Please try again.',
    );
  }
}
