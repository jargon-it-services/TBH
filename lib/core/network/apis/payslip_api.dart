import '../../services/DataModels/payslip_detail_model.dart';
import '../../services/DataModels/payslip_list_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Payslip Module API — list/details + generation + status actions
/// (approve/reject/mark paid, single and bulk).
///
/// Follows the exact same [callApi]/[DioClient] pattern as every other
/// API class in this app (`SalaryRulesApi`, `TransactionApi`,
/// `StaffApi`) — no new networking approach introduced. Branch and
/// Employee options for the Create Payslip form are deliberately NOT
/// re-fetched here: the form reuses `BranchesApi.fetchBranches()` and
/// `StaffApi.fetchStaffList()` directly, same catalogs already used by
/// Reports/P&L/Payment Mode (branch) and Staff Management (employee),
/// instead of duplicating a second copy of either list behind a new
/// endpoint.
///
/// [DioClient] only exposes `get`/`post` (no `put`/`delete`), so every
/// mutation below goes through POST, matching every other mutation
/// endpoint in the app.
class PayslipApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // Fetch Payslip List
  // Endpoint: GET /payslips/list
  // ==========================================================
  /// GET /payslips/list — the full Payslip List screen's data (status
  /// segment, branch filter, search, month/year filter all apply
  /// locally against this, same as `TransactionsPage`/
  /// `SalaryRuleListPage`).
  Future<ApiResponse<List<PayslipListItem>>> fetchPayslipList() {
    return callApi<List<PayslipListItem>>(
      mockAsset: 'assets/mocks/payslip_list_response.json',
      liveCall: () => _client.get('/payslips/list'),
      parse: (data) => (data['payslips'] as List)
          .map((e) => PayslipListItem.fromJson(e))
          .toList(),
      fallbackErrorMessage: "We couldn't load payslips right now.",
    );
  }

  // ==========================================================
  // Fetch Payslip Details
  // Endpoint: GET /payslips/{payslipId}/details
  // ==========================================================
  /// GET /payslips/{payslipId}/details
  Future<ApiResponse<PayslipDetailResponse>> fetchPayslipDetails(
    int payslipId,
  ) {
    return callApi<PayslipDetailResponse>(
      mockAsset: 'assets/mocks/payslip_detail_response.json',
      liveCall: () => _client.get('/payslips/$payslipId/details'),
      parse: (data) => PayslipDetailResponse.fromJson(data),
      fallbackErrorMessage: "We couldn't load this payslip's details.",
    );
  }

  // ==========================================================
  // Generate Payslip(s)
  // Endpoint: POST /payslips/generate
  // ==========================================================
  /// POST /payslips/generate — branch(es), all-employees flag or an
  /// explicit employee list, and a single month/year (see
  /// `PayslipCreatePage`).
  Future<ApiResponse<bool>> generatePayslip(Map<String, dynamic> payload) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/payslip_generate_response.json',
      liveCall: () => _client.post('/payslips/generate', data: payload),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to generate payslip',
    );
  }

  // ==========================================================
  // Approve / Reject / Mark Paid (single)
  // Endpoint: POST /payslips/{payslipId}/approve|reject|mark-paid
  // ==========================================================
  /// POST /payslips/{payslipId}/approve — Generated → Approved.
  Future<ApiResponse<bool>> approvePayslip(int payslipId) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/payslip_action_response.json',
      liveCall: () => _client.post('/payslips/$payslipId/approve'),
      parse: (data) => (data['updated'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to approve payslip',
    );
  }

  /// POST /payslips/{payslipId}/reject — Generated → Rejected.
  Future<ApiResponse<bool>> rejectPayslip(int payslipId) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/payslip_action_response.json',
      liveCall: () => _client.post('/payslips/$payslipId/reject'),
      parse: (data) => (data['updated'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to reject payslip',
    );
  }

  /// POST /payslips/{payslipId}/mark-paid — Approved → Paid.
  Future<ApiResponse<bool>> markPayslipPaid(int payslipId) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/payslip_action_response.json',
      liveCall: () => _client.post('/payslips/$payslipId/mark-paid'),
      parse: (data) => (data['updated'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to mark payslip as paid',
    );
  }

  // ==========================================================
  // Bulk Approve / Reject / Mark Paid
  // Endpoint: POST /payslips/bulk-approve|bulk-reject|bulk-mark-paid
  // ==========================================================
  /// POST /payslips/bulk-approve
  Future<ApiResponse<bool>> bulkApprovePayslips(List<int> payslipIds) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/payslip_action_response.json',
      liveCall: () => _client.post(
        '/payslips/bulk-approve',
        data: {'payslip_ids': payslipIds},
      ),
      parse: (data) => (data['updated'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to approve selected payslips',
    );
  }

  /// POST /payslips/bulk-reject
  Future<ApiResponse<bool>> bulkRejectPayslips(List<int> payslipIds) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/payslip_action_response.json',
      liveCall: () => _client.post(
        '/payslips/bulk-reject',
        data: {'payslip_ids': payslipIds},
      ),
      parse: (data) => (data['updated'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to reject selected payslips',
    );
  }

  /// POST /payslips/bulk-mark-paid
  Future<ApiResponse<bool>> bulkMarkPayslipsPaid(List<int> payslipIds) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/payslip_action_response.json',
      liveCall: () => _client.post(
        '/payslips/bulk-mark-paid',
        data: {'payslip_ids': payslipIds},
      ),
      parse: (data) => (data['updated'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to mark selected payslips as paid',
    );
  }
}
