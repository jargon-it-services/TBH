import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../services/DataModels/account_info_model.dart';
import '../../services/platform_info.dart';
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
  /// (City/State travel along, auto-derived from it), Full Name,
  /// Designation, GSTIN, and Account Photo/Logo are ever included in
  /// [payload]/[accountPhoto]; every other Account Info field is
  /// read-only and never sent here.
  ///
  /// `platform` is never a field the user sees or fills in — it's
  /// resolved via [PlatformInfo] and attached silently, same as
  /// `RegistrationApi.registerBusiness` does.
  Future<ApiResponse<bool>> updateAccountInfo(
    Map<String, dynamic> payload, {
    File? accountPhoto,
    bool removeAccountPhoto = false,
  }) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/account_info_update_response.json',
      liveCall: () async => _client.post(
        '/account/info',
        data: await _buildRequestBody(payload, accountPhoto, removeAccountPhoto),
      ),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to update account info',
    );
  }

  Future<dynamic> _buildRequestBody(
    Map<String, dynamic> payload,
    File? accountPhoto,
    bool removeAccountPhoto,
  ) async {
    final withPlatform = {...payload, 'platform': PlatformInfo.current};

    if (accountPhoto == null && !removeAccountPhoto) return withPlatform;

    final fields = <String, dynamic>{};
    withPlatform.forEach((key, value) {
      fields[key] = value is String ? value : jsonEncode(value);
    });
    if (removeAccountPhoto) fields['remove_account_photo'] = 'true';

    return FormData.fromMap({
      ...fields,
      if (accountPhoto != null)
        'account_photo': await MultipartFile.fromFile(accountPhoto.path),
    });
  }
}
