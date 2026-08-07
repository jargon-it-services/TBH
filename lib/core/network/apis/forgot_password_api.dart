import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload for organization code verification.
class OrganizationVerifyResult {
  final String organizationName;

  OrganizationVerifyResult({required this.organizationName});

  factory OrganizationVerifyResult.fromJson(Map<String, dynamic> json) {
    return OrganizationVerifyResult(
      organizationName: json['organization_name'] ?? '',
    );
  }
}

/// Response payload for the "send OTP" step.
class OtpSendResult {
  final String message;
  final int expirySeconds;

  OtpSendResult({required this.message, required this.expirySeconds});

  factory OtpSendResult.fromJson(Map<String, dynamic> json) {
    return OtpSendResult(
      message: json['message'] ?? 'OTP sent successfully',
      expirySeconds: json['expiry_seconds'] ?? 300,
    );
  }
}

/// Response payload for OTP verification.
class OtpVerifyResult {
  final String resetToken;

  OtpVerifyResult({required this.resetToken});

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResult(
      resetToken: json['reset_token'] ?? '',
    );
  }
}

/// Response payload for the final password reset.
class ResetPasswordResult {
  final String message;

  ResetPasswordResult({required this.message});

  factory ResetPasswordResult.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResult(
      message: json['message'] ?? 'Password changed successfully',
    );
  }
}

/// Forgot Password APIs — uses the shared [callApi] helper (mock/live
/// branching + ApiResponse<T> wrapping) so the rest of the app doesn't
/// need a new pattern.
class ForgotPasswordApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_005 - Verify Organization
  // Endpoint: POST /forgot-password/verify-organization
  // Backend Doc Ref: API_005
  // ==========================================================
  Future<ApiResponse<OrganizationVerifyResult>> verifyOrganization({
    required String orgCode,
  }) {
    return callApi<OrganizationVerifyResult>(
      mockAsset: 'assets/mocks/forgot_password_verify_org_response.json',
      mockDelay: const Duration(seconds: 1),
      liveCall: () => _client.post(
        '/forgot-password/verify-organization',
        data: {'organization_code': orgCode},
      ),
      parse: OrganizationVerifyResult.fromJson,
      fallbackErrorMessage: 'Organization code not found',
    );
  }

  // ==========================================================
  // API_006 - Send OTP
  // Endpoint: POST /forgot-password/send-otp
  // Backend Doc Ref: API_006
  // ==========================================================
  Future<ApiResponse<OtpSendResult>> sendOtp({
    required String orgCode,
    required String email,
  }) {
    return callApi<OtpSendResult>(
      mockAsset: 'assets/mocks/forgot_password_send_otp_response.json',
      mockDelay: const Duration(seconds: 1),
      liveCall: () => _client.post(
        '/forgot-password/send-otp',
        data: {'organization_code': orgCode, 'email': email},
      ),
      parse: OtpSendResult.fromJson,
      fallbackErrorMessage: 'Could not send OTP',
    );
  }

  // ==========================================================
  // API_007 - Verify OTP
  // Endpoint: POST /forgot-password/verify-otp
  // Backend Doc Ref: API_007
  // ==========================================================
  Future<ApiResponse<OtpVerifyResult>> verifyOtp({
    required String orgCode,
    required String email,
    required String otp,
  }) {
    return callApi<OtpVerifyResult>(
      mockAsset: 'assets/mocks/forgot_password_verify_otp_response.json',
      mockDelay: const Duration(seconds: 1),
      liveCall: () => _client.post(
        '/forgot-password/verify-otp',
        data: {'organization_code': orgCode, 'email': email, 'otp': otp},
      ),
      parse: OtpVerifyResult.fromJson,
      fallbackErrorMessage: 'Invalid or expired OTP',
    );
  }

  // ==========================================================
  // API_008 - Reset Password
  // Endpoint: POST /forgot-password/reset
  // Backend Doc Ref: API_008
  // ==========================================================
  Future<ApiResponse<ResetPasswordResult>> resetPassword({
    required String orgCode,
    required String email,
    required String otp,
    required String password,
  }) {
    return callApi<ResetPasswordResult>(
      mockAsset: 'assets/mocks/forgot_password_reset_response.json',
      mockDelay: const Duration(seconds: 2),
      liveCall: () => _client.post(
        '/forgot-password/reset',
        data: {
          'organization_code': orgCode,
          'email': email,
          'otp': otp,
          'password': password,
        },
      ),
      parse: ResetPasswordResult.fromJson,
      fallbackErrorMessage: 'Failed to change password',
    );
  }
}
