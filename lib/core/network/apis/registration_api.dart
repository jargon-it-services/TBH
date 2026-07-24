import 'dart:io';

import 'package:dio/dio.dart';

import '../../referral/invite_token_manager.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload returned on successful registration. Kept minimal —
/// extend with whatever the real backend returns (token, user id, etc.)
/// once the endpoint is finalized. `authToken` is what would normally be
/// persisted via secure storage before navigating straight to Dashboard.
class RegistrationResult {
  final String authToken;
  final String businessName;
  final String? businessId;

  RegistrationResult({
    required this.authToken,
    required this.businessName,
    this.businessId,
  });

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    return RegistrationResult(
      authToken: json['token'] ?? '',
      businessName: json['business_name'] ?? '',
      businessId: json['business_id']?.toString(),
    );
  }
}

class RegistrationApi {
  final DioClient _client = DioClient();
  final InviteTokenManager _inviteTokenManager = InviteTokenManager();

  /// Error codes the backend may return when the attached invite token
  /// turned out to be unusable. Any other failure (validation error,
  /// network error, etc.) leaves the stored token untouched, since only
  /// the backend can say the invite itself is dead — see
  /// [InviteTokenManager]'s lifecycle notes.
  static const _deadInviteErrorCodes = {
    'invite_invalid',
    'invite_expired',
    'invite_revoked',
  };

  /// Registration UI stays untouched — it has no Account Code/Referral
  /// Code field and never will. Instead, right before the request is
  /// sent, this reads any invite token stored by [DeepLinkService] and
  /// attaches it silently. If none exists, this is a normal request,
  /// exactly as before.
  Future<ApiResponse<RegistrationResult>> registerBusiness({
    // Contact
    required String address,
    required String city,
    required String state,
    required String zip,
    required String phone,
    required String businessEmail,
    // Owner
    required String ownerName,
    required String designation,
    required String idProofType,
    required String idProofNumber,
    required File idProofDocument,
    // Account
    required String loginEmail,
    required String password,
  }) async {
    final inviteToken = await _inviteTokenManager.getToken();

    final response = await callApi<RegistrationResult>(
      mockAsset: 'assets/mocks/register_response.json',
      mockDelay: const Duration(seconds: 2),
      liveCall: () async {
        final formData = FormData.fromMap({
          "address": address,
          "city": city,
          "state": state,
          "zip": zip,
          "phone": phone,
          "business_email": businessEmail,
          "owner_name": ownerName,
          "designation": designation,
          "id_proof_type": idProofType,
          "id_proof_number": idProofNumber,
          "id_proof_document":
              await MultipartFile.fromFile(idProofDocument.path),
          "login_email": loginEmail,
          "password": password,
          if (inviteToken != null && inviteToken.isNotEmpty)
            "invite_token": inviteToken,
        });
        return _client.post('/register', data: formData);
      },
      parse: RegistrationResult.fromJson,
      fallbackErrorMessage: 'Registration failed',
    );

    // Invite token lifecycle (see InviteTokenManager):
    //   success                          -> delete (used, no longer needed)
    //   backend confirms invite is dead  -> delete (invalid/expired/revoked)
    //   any other failure                -> keep (user may retry)
    if (inviteToken != null && inviteToken.isNotEmpty) {
      if (response.isSuccess ||
          _deadInviteErrorCodes.contains(response.errorCode)) {
        await _inviteTokenManager.clearToken();
      }
    }

    return response;
  }
}
