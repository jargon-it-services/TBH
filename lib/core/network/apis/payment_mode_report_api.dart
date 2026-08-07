import '../../services/DataModels/payment_mode_report_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Payment Mode Breakdown API — powers `PaymentModeReportPage`
/// (Account > Report > Payment Mode).
///
/// Same shape as `PnlReportApi`: [callApi] handles the mock/live
/// branching, one bundled mock JSON per segment, and `custom` falls
/// back to the closest regular segment (`this_month`) until a real
/// backend can answer an arbitrary date range.
class PaymentModeReportApi {
  final DioClient _client = DioClient();

  /// GET /reports/payment-mode?period=&branch_id=&start_date=&end_date=
  Future<ApiResponse<PaymentModeReportData>> fetchPaymentModeReport({
    required String period,
    String branchId = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final String mockAsset = switch (period) {
      'today' => 'assets/mocks/payment_mode_today_response.json',
      'this_week' => 'assets/mocks/payment_mode_this_week_response.json',
      '3m' => 'assets/mocks/payment_mode_3m_response.json',
      '6m' => 'assets/mocks/payment_mode_6m_response.json',
      '12m' => 'assets/mocks/payment_mode_12m_response.json',
      _ => 'assets/mocks/payment_mode_this_month_response.json',
    };

    return callApi<PaymentModeReportData>(
      mockAsset: mockAsset,
      liveCall: () => _client.get(
        '/reports/payment-mode',
        queryParameters: {
          'period': period,
          'branch_id': branchId,
          if (startDate != null)
            'start_date': startDate.toIso8601String(),
          if (endDate != null) 'end_date': endDate.toIso8601String(),
        },
      ),
      parse: (data) => PaymentModeReportData.fromJson(data),
      fallbackErrorMessage:
          "We couldn't load the payment mode breakdown right now.",
    );
  }
}
