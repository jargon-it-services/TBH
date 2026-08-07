import '../../models/user_role.dart';
import '../../services/DataModels/login_response_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload for a successful login.
///
/// The wire shape changed from a flat `{ token, refresh_token,
/// user_name, role }` to a nested one — `user_name` and `role` now
/// live under `user_info`, alongside new `account`, `recent_plan`,
/// `management`, `feature_lock`, and `expires_in` fields (see
/// `login_response_model.dart` for the nested model classes).
///
/// [userName] and [role] are kept as getters delegating to [userInfo]
/// so every existing call site that read `LoginResult.userName` /
/// `LoginResult.role` (e.g. [SessionManager.saveSession] call sites)
/// keeps compiling and behaving identically without needing to know
/// about the nesting.
class LoginResult {
  final String authToken;
  final String? refreshToken;

  /// Seconds until [authToken] expires, if the backend sent one.
  final int? expiresIn;

  final LoginUserInfo userInfo;
  final LoginAccountInfo? account;
  final LoginRecentPlan? recentPlan;
  final LoginManagementInfo? management;

  /// Feature keys locked for this account under its current plan
  /// (e.g. `["report", "payment_slip", "pnl"]`). Empty when the
  /// backend omits the field or nothing is locked.
  final List<String> featureLock;

  LoginResult({
    required this.authToken,
    this.refreshToken,
    this.expiresIn,
    required this.userInfo,
    this.account,
    this.recentPlan,
    this.management,
    this.featureLock = const [],
  });

  /// Backward-compatible accessor for the old top-level `user_name` —
  /// now nested under `user_info.user_name`.
  String get userName => userInfo.userName;

  /// Backward-compatible accessor for the old top-level `role` — now
  /// nested under `user_info.role`. Goes through
  /// [UserRole.fromApiValue] exactly like the old parsing did, so
  /// unknown/missing values still fail safe to [UserRole.employee].
  UserRole get role => UserRole.fromApiValue(userInfo.role);

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      authToken: json['token'] ?? '',
      refreshToken: json['refresh_token'],
      expiresIn: (json['expires_in'] as num?)?.toInt(),
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

/// Login API — uses the shared [callApi] helper (mock/live branching +
/// ApiResponse<T> wrapping) so the rest of the app doesn't need a new
/// pattern.
class LoginApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_001 - Login
  // Endpoint: POST /auth/login
  // Backend Doc Ref: API_001
  // ==========================================================
  Future<ApiResponse<LoginResult>> login({
    required String organizationCode,
    required String email,
    required String password,
  }) {
    return callApi<LoginResult>(
      mockAsset: 'assets/mocks/login_response.json',
      mockDelay: const Duration(seconds: 2),
      liveCall: () => _client.post(
        '/auth/login',
        data: {
          'organization_code': organizationCode,
          'email': email,
          'password': password,
        },
      ),
      parse: LoginResult.fromJson,
      fallbackErrorMessage: 'Invalid credentials',
    );
  }
}
