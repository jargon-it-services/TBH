import '../../services/DataModels/employee_performance_report_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Employee Performance Report API — powers `EmployeePerformanceReportPage`
/// (Account > Report > Employee Performance Report).
///
/// Uses the shared [callApi] helper exactly like `PnlReportApi` /
/// `PaymentModeReportApi` / `BranchPerformanceReportApi` (mock/live
/// branching + `ApiResponse<T>` wrapping) — no new networking
/// architecture is introduced for this feature.
///
/// No backend endpoint exists for this yet, so with `Env.isMock` true
/// every call below resolves from a bundled mock JSON asset. Swapping
/// to the real API later is a no-op for callers: only the `liveCall`
/// closures here start hitting a real host once `Env.isMock` flips to
/// `false` and `/reports/employee-performance` exists.
class EmployeePerformanceReportApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_078 - Fetch Employee Performance Report
  // Endpoint: GET /reports/employee-performance
  // Backend Doc Ref: API_078
  // ==========================================================
  /// GET /reports/employee-performance?period=&branch_id=&start_date=&end_date=
  Future<ApiResponse<EmployeePerformanceReportData>> fetchReport({
    required String period,
    String branchId = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final String mockAsset = switch (period) {
      'today' => 'assets/mocks/employee_performance_today_response.json',
      'this_week' => 'assets/mocks/employee_performance_this_week_response.json',
      '3m' => 'assets/mocks/employee_performance_3m_response.json',
      '6m' => 'assets/mocks/employee_performance_6m_response.json',
      '12m' => 'assets/mocks/employee_performance_12m_response.json',
      _ => 'assets/mocks/employee_performance_this_month_response.json',
    };

    return callApi<EmployeePerformanceReportData>(
      mockAsset: mockAsset,
      liveCall: () => _client.get(
        '/reports/employee-performance',
        queryParameters: {
          'period': period,
          'branch_id': branchId,
          if (startDate != null)
            'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      ),
      parse: (data) => EmployeePerformanceReportData.fromJson(data),
      fallbackErrorMessage:
          "We couldn't load the employee performance report right now.",
    );
  }

  // ==========================================================
  // API_079 - Export Employee Performance Report
  // Endpoint: GET /reports/employee-performance/export
  // Backend Doc Ref: API_079
  // ==========================================================
  /// GET /reports/employee-performance/export?format=pdf|excel
  ///
  /// Same "backend hands back a URL, screen just launches it" contract
  /// the other report APIs already use.
  Future<ApiResponse<String>> exportReport({required String format}) {
    return callApi<String>(
      mockAsset: 'assets/mocks/employee_performance_export_response.json',
      liveCall: () => _client.get(
        '/reports/employee-performance/export',
        queryParameters: {'format': format},
      ),
      parse: (data) =>
          ((format == 'excel' ? data['excel_url'] : data['pdf_url']) as String?) ??
          '',
      fallbackErrorMessage: "We couldn't generate that export right now.",
    );
  }
}
