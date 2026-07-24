import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload for the invite-link endpoint. The app never
/// generates this URL itself — the backend owns invite generation
/// entirely; this is just the opaque link it hands back.
class InviteLinkResult {
  final String inviteUrl;

  InviteLinkResult({required this.inviteUrl});

  factory InviteLinkResult.fromJson(Map<String, dynamic> json) {
    return InviteLinkResult(
      inviteUrl: json['invite_url'] ?? '',
    );
  }
}

/// Referral API — uses the shared [callApi] helper (mock/live branching
/// + ApiResponse<T> wrapping) so the rest of the app doesn't need a new
/// pattern, exactly like LoginApi/LogoutApi/AppVersionApi.
///
/// BACKEND CONTRACT:
///
///   GET /referrals/invite-link
///   Headers:       Authorization: Bearer <current access token>
///   200 response:  { "status": true, "data": { "invite_url": "https://app.tbh.com/i/X7Kd92PmLq" } }
///
/// This is a protected endpoint (not in DioClient's public-paths list),
/// so the current access token is attached automatically the same way
/// every other protected call already works.
class ReferralApi {
  final DioClient _client = DioClient();

  Future<ApiResponse<InviteLinkResult>> getInviteLink() {
    return callApi<InviteLinkResult>(
      mockAsset: 'assets/mocks/referral_invite_link_response.json',
      liveCall: () => _client.get('/referrals/invite-link'),
      parse: InviteLinkResult.fromJson,
      fallbackErrorMessage: 'Could not generate invite link',
    );
  }
}
