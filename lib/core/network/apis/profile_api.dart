import '../../models/user_role.dart';
import '../../services/DataModels/login_response_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload for the signed-in user's own profile.
///
/// Same nested `user_info` / `account` / `recent_plan` / `management` /
/// `feature_lock` shape [LoginResult] parses (see
/// `login_response_model.dart` for those model classes) — the backend
/// contract for this task is: profile's `data` is identical to login's
/// `data`, minus the auth-issuing fields (`token`, `refresh_token`,
/// `expires_in`), since this endpoint only re-reads the current user's
/// profile rather than establishing a new session.
///
/// [userName] and [role] are kept as convenience getters delegating to
/// [userInfo], mirroring [LoginResult.userName] / [LoginResult.role].
class ProfileResult {
  final LoginUserInfo userInfo;
  final LoginAccountInfo? account;
  final LoginRecentPlan? recentPlan;
  final LoginManagementInfo? management;

  /// Feature keys locked for this account under its current plan (e.g.
  /// `["report", "payment_slip", "pnl"]`). Empty when the backend
  /// omits the field or nothing is locked.
  final List<String> featureLock;

  ProfileResult({
    required this.userInfo,
    this.account,
    this.recentPlan,
    this.management,
    this.featureLock = const [],
  });

  /// Backward-compatible accessor mirroring [LoginResult.userName].
  String get userName => userInfo.userName;

  /// Backward-compatible accessor mirroring [LoginResult.role]. Goes
  /// through [UserRole.fromApiValue] exactly like login parsing does,
  /// so an unknown/missing value fails safe to [UserRole.employee].
  UserRole get role => UserRole.fromApiValue(userInfo.role);

  factory ProfileResult.fromJson(Map<String, dynamic> json) {
    return ProfileResult(
      userInfo: json['user_info'] != null
          ? LoginUserInfo.fromJson(json['user_info'])
          : LoginUserInfo.empty,
      account: json['account'] != null
          ? LoginAccountInfo.fromJson(json['account'])
          : null,
      recentPlan: json['recent_plan'] != null
          ? LoginRecentPlan.fromJson(json['recent_plan'])
          : null,
      management: json['management'] != null
          ? LoginManagementInfo.fromJson(json['management'])
          : null,
      featureLock:
          (json['feature_lock'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }
}

/// Profile API — uses the shared [callApi] helper (mock/live branching +
/// `ApiResponse<T>` wrapping) exactly like [LoginApi] and
/// `DashboardHeaderApi`, so the rest of the app doesn't need a new
/// pattern.
///
/// This is a protected endpoint (unlike login/register/forgot-password):
/// it is deliberately NOT added to `DioClient`'s public-paths list, so
/// the current access token is attached automatically as the
/// Authorization header, and its 401s go through the same
/// refresh/auto-logout handling as every other protected call — the
/// same wiring [ReferralApi]/[DashboardHeaderApi] already get for free.
class ProfileApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_010 - Fetch Profile
  // Endpoint: GET /user/profile
  // Backend Doc Ref: API_010
  // ==========================================================
  Future<ApiResponse<ProfileResult>> fetchProfile() {
    return callApi<ProfileResult>(
      mockAsset: 'assets/mocks/profile_response.json',
      liveCall: () => _client.get('/user/profile'),
      parse: ProfileResult.fromJson,
      fallbackErrorMessage: "We couldn't load your profile right now.",
    );
  }
}
