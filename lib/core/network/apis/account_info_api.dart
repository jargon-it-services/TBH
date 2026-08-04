import '../../services/DataModels/account_info_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Account Info API — fetch the signed-in account's full registration
/// data, and update the handful of fields Account Info allows editing.
/// Follows the exact same [callApi]/[DioClient] pattern as every other
/// API class, so nothing new is introduced architecturally.
///
/// There's no create/delete here — Account Info is a single record per
/// account (created at Registration), only ever fetched and updated.
class AccountInfoApi {
  final DioClient _client = DioClient();

  /// GET /account/info
  Future<ApiResponse<AccountInfoResponse>> fetchAccountInfo() {
    return callApi<AccountInfoResponse>(
      mockAsset: 'assets/mocks/account_info_response.json',
      liveCall: () => _client.get('/account/info'),
      parse: (data) => AccountInfoResponse.fromJson(data),
      fallbackErrorMessage: "We couldn't load your account info right now.",
    );
  }

  /// POST /account/info — only Phone Number, Address, Pincode/ZIP
  /// (City/State travel along, auto-derived from it), Full Name, and
  /// Designation are ever included in [payload]; every other Account
  /// Info field is read-only and never sent here.
  Future<ApiResponse<bool>> updateAccountInfo(Map<String, dynamic> payload) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/account_info_update_response.json',
      liveCall: () => _client.post('/account/info', data: payload),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to update account info',
    );
  }
}
