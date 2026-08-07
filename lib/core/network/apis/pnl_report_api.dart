import '../../services/DataModels/pnl_report_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// P&L Report API — powers `PnlReportPage` (Account > Report > PnL).
///
/// Uses the shared [callApi] helper exactly like `BranchesApi` /
/// `SalaryRulesApi` (mock/live branching + `ApiResponse<T>` wrapping),
/// the current preferred pattern for new API classes in this project —
/// no new networking architecture is introduced for this feature.
///
/// No backend endpoint exists for this yet, so with `Env.isMock` true
/// (see `env.dart`) every call below resolves from a bundled mock JSON
/// asset. Swapping to the real API later is a no-op for callers: only
/// the `liveCall` closures here start hitting a real host once
/// `Env.isMock` flips to `false` and `/reports/pnl` exists.
class PnlReportApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_055 - Fetch P&L Report
  // Endpoint: GET /reports/pnl
  // Backend Doc Ref: API_055
  // ==========================================================
  /// GET /reports/pnl?period=&branch_id=&start_date=&end_date=
  ///
  /// [period] is one of the keys the response's own `meta.periods[]`
  /// advertises (`today` / `this_week` / `this_month` / `3m` / `6m` /
  /// `12m` / `custom`). The mock has one canned dataset per non-custom
  /// period; `custom` (and any period key without its own dataset)
  /// falls back to the `3m` dataset — swapping in a real backend is
  /// what makes a genuine custom-range query possible, this just
  /// keeps the screen usable against mocks today.
  Future<ApiResponse<PnlReportData>> fetchPnlReport({
    required String period,
    String branchId = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final String mockAsset = switch (period) {
      'today' => 'assets/mocks/pnl_report_today_response.json',
      'this_week' => 'assets/mocks/pnl_report_this_week_response.json',
      'this_month' => 'assets/mocks/pnl_report_this_month_response.json',
      '6m' => 'assets/mocks/pnl_report_6m_response.json',
      '12m' => 'assets/mocks/pnl_report_12m_response.json',
      _ => 'assets/mocks/pnl_report_3m_response.json',
    };

    return callApi<PnlReportData>(
      mockAsset: mockAsset,
      liveCall: () => _client.get(
        '/reports/pnl',
        queryParameters: {
          'period': period,
          'branch_id': branchId,
          if (startDate != null)
            'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      ),
      parse: (data) => PnlReportData.fromJson(data),
      fallbackErrorMessage: "We couldn't load the P&L report right now.",
    );
  }

  // ==========================================================
  // API_056 - Export P&L Report
  // Endpoint: GET /reports/pnl/export
  // Backend Doc Ref: API_056
  // ==========================================================
  /// GET /reports/pnl/export?format=pdf|excel
  ///
  /// Returns a downloadable file URL — same "backend hands back a URL,
  /// screen just launches it" contract `PaymentDetailsPage` already
  /// uses for Download Receipt / Download Invoice, so Export PDF /
  /// Export Excel need no new download machinery here.
  Future<ApiResponse<String>> exportReport({required String format}) {
    return callApi<String>(
      mockAsset: 'assets/mocks/pnl_export_response.json',
      liveCall: () => _client.get(
        '/reports/pnl/export',
        queryParameters: {'format': format},
      ),
      parse: (data) =>
          ((format == 'excel' ? data['excel_url'] : data['pdf_url']) as String?) ??
          '',
      fallbackErrorMessage: "We couldn't generate that export right now.",
    );
  }
}
