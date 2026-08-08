import '../../services/DataModels/branch_performance_report_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Branch Performance Breakdown API — powers `BranchPerformanceReportPage`
/// (Account > Report > Branch Performance Breakdown).
///
/// Same shape as `PnlReportApi` / `RevenueExpenseReportApi` /
/// `PaymentModeReportApi`: [callApi] handles mock/live branching, one
/// bundled mock JSON per segment, and `custom` falls back to the
/// closest regular segment (`today`) until a real backend can answer
/// an arbitrary date range.
///
/// Note: unlike the other three reports there's no `branch_id` query
/// param — this report *compares* branches, so it always returns
/// every branch for the selected period.
class BranchPerformanceReportApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_076 - Fetch Branch Performance Report
  // Endpoint: GET /reports/branch-performance
  // Backend Doc Ref: API_076
  // ==========================================================
  /// GET /reports/branch-performance?period=&start_date=&end_date=
  Future<ApiResponse<BranchPerformanceReportData>> fetchReport({
    required String period,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final String mockAsset = switch (period) {
      'this_week' => 'assets/mocks/branch_performance_this_week_response.json',
      'this_month' => 'assets/mocks/branch_performance_this_month_response.json',
      '3m' => 'assets/mocks/branch_performance_3m_response.json',
      '6m' => 'assets/mocks/branch_performance_6m_response.json',
      '12m' => 'assets/mocks/branch_performance_12m_response.json',
      _ => 'assets/mocks/branch_performance_today_response.json',
    };

    return callApi<BranchPerformanceReportData>(
      mockAsset: mockAsset,
      liveCall: () => _client.get(
        '/reports/branch-performance',
        queryParameters: {
          'period': period,
          if (startDate != null)
            'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      ),
      parse: (data) => BranchPerformanceReportData.fromJson(data),
      fallbackErrorMessage:
          "We couldn't load the branch performance report right now.",
    );
  }

  // ==========================================================
  // API_077 - Export Branch Performance Report
  // Endpoint: GET /reports/branch-performance/export
  // Backend Doc Ref: API_077
  // ==========================================================
  /// GET /reports/branch-performance/export?format=pdf|excel
  ///
  /// Same "backend hands back a URL, screen just launches it" contract
  /// the other report APIs already use.
  Future<ApiResponse<String>> exportReport({required String format}) {
    return callApi<String>(
      mockAsset: 'assets/mocks/branch_performance_export_response.json',
      liveCall: () => _client.get(
        '/reports/branch-performance/export',
        queryParameters: {'format': format},
      ),
      parse: (data) =>
          ((format == 'excel' ? data['excel_url'] : data['pdf_url']) as String?) ??
          '',
      fallbackErrorMessage: "We couldn't generate that export right now.",
    );
  }
}
