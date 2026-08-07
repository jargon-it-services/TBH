import '../../services/DataModels/revenue_expense_report_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Revenue & Expense Summary API — powers `RevenueExpenseReportPage`
/// (Account > Report > Revenue & Expense Summary).
///
/// Same shape as `PnlReportApi` / `PaymentModeReportApi`: [callApi]
/// handles mock/live branching, one bundled mock JSON per segment, and
/// `custom` falls back to the closest regular segment (`today`) until
/// a real backend can answer an arbitrary date range.
class RevenueExpenseReportApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_057 - Fetch Revenue & Expense Report
  // Endpoint: GET /reports/revenue-expense
  // Backend Doc Ref: API_057
  // ==========================================================
  /// GET /reports/revenue-expense?period=&branch_id=&start_date=&end_date=
  Future<ApiResponse<RevenueExpenseReportData>> fetchReport({
    required String period,
    String branchId = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final String mockAsset = switch (period) {
      'this_week' => 'assets/mocks/revenue_expense_this_week_response.json',
      'this_month' => 'assets/mocks/revenue_expense_this_month_response.json',
      '3m' => 'assets/mocks/revenue_expense_3m_response.json',
      '6m' => 'assets/mocks/revenue_expense_6m_response.json',
      '12m' => 'assets/mocks/revenue_expense_12m_response.json',
      _ => 'assets/mocks/revenue_expense_today_response.json',
    };

    return callApi<RevenueExpenseReportData>(
      mockAsset: mockAsset,
      liveCall: () => _client.get(
        '/reports/revenue-expense',
        queryParameters: {
          'period': period,
          'branch_id': branchId,
          if (startDate != null)
            'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      ),
      parse: (data) => RevenueExpenseReportData.fromJson(data),
      fallbackErrorMessage:
          "We couldn't load the revenue & expense report right now.",
    );
  }

  // ==========================================================
  // API_058 - Export Revenue & Expense Report
  // Endpoint: GET /reports/revenue-expense/export
  // Backend Doc Ref: API_058
  // ==========================================================
  /// GET /reports/revenue-expense/export?format=pdf|excel
  ///
  /// Same "backend hands back a URL, screen just launches it" contract
  /// `PnlReportApi.exportReport` already uses.
  Future<ApiResponse<String>> exportReport({required String format}) {
    return callApi<String>(
      mockAsset: 'assets/mocks/revenue_expense_export_response.json',
      liveCall: () => _client.get(
        '/reports/revenue-expense/export',
        queryParameters: {'format': format},
      ),
      parse: (data) =>
          ((format == 'excel' ? data['excel_url'] : data['pdf_url']) as String?) ??
          '',
      fallbackErrorMessage: "We couldn't generate that export right now.",
    );
  }
}
