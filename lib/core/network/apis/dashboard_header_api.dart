import '../../models/user_role.dart';
import '../../services/DataModels/dashboard_header_model.dart';
import '../../session/session_manager.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Fetches the data the Dashboard's sticky header needs to render
/// itself for the logged-in user — org identity, notification count,
/// and whichever switchable-scope list applies to their role
/// (Organizations for Super Admin, Branches for Account Admin, or a
/// single assigned Branch for Branch Admin / Manager / Employee).
///
/// This is a single endpoint rather than one per role: the live
/// backend already knows the caller's role from the auth token (same
/// as every other protected call — see [DioClient]), so it returns
/// only the fields relevant to that role. [DashboardHeaderModel]
/// documents the exact per-role shape.
///
/// Uses the shared [callApi] helper (mock/live branching + error
/// wrapping) like the other newer `*_api.dart` files (e.g. [LoginApi],
/// [ReferralApi]) instead of hand-rolling the try/catch + status-code
/// branching that the older API files still do.
class DashboardHeaderApi {
  final DioClient _client = DioClient();

  Future<ApiResponse<DashboardHeaderModel>> fetchHeader() {
    return callApi<DashboardHeaderModel>(
      // A live backend infers the role from the auth token and always
      // hits the same path; only the mock fixture needs to vary by
      // role (mirrors DashboardApi.fetchRevenueTrend picking between
      // trend_next.json/trend_prev.json by a parameter).
      mockAsset: _mockAssetForCurrentRole(),
      liveCall: () => _client.get('/dashboard/header'),
      parse: DashboardHeaderModel.fromJson,
      fallbackErrorMessage:
          "We couldn't load your dashboard header right now.",
    );
  }

  String _mockAssetForCurrentRole() {
    switch (SessionManager.instance.role) {
      case UserRole.superAdmin:
        return 'assets/mocks/dashboard_header_super_admin_response.json';
      case UserRole.accountAdmin:
        return 'assets/mocks/dashboard_header_account_admin_response.json';
      case UserRole.branchAdmin:
        return 'assets/mocks/dashboard_header_branch_admin_response.json';
      case UserRole.manager:
        return 'assets/mocks/dashboard_header_manager_response.json';
      case UserRole.employee:
        return 'assets/mocks/dashboard_header_employee_response.json';
    }
  }
}
