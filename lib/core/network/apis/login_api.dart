import '../../models/user_role.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload for a successful login.
class LoginResult {
  final String authToken;
  final String userName;
  final UserRole role;
  final String? refreshToken;

  LoginResult({
    required this.authToken,
    required this.userName,
    required this.role,
    this.refreshToken,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      authToken: json['token'] ?? '',
      userName: json['user_name'] ?? '',
      // Backend contract: `role` is one of super_admin / account_admin /
      // branch_admin / manager / employee. Any other/missing value
      // safely falls back to the least-privileged role — see
      // UserRole.fromApiValue.
      role: UserRole.fromApiValue(json['role'] as String?),
      refreshToken: json['refresh_token'],
    );
  }
}

/// Login API — uses the shared [callApi] helper (mock/live branching +
/// ApiResponse<T> wrapping) so the rest of the app doesn't need a new
/// pattern.
class LoginApi {
  final DioClient _client = DioClient();

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
