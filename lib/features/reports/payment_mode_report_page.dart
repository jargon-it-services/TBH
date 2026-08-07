import 'package:flutter/material.dart';

import '../../core/network/api_response.dart';
import '../../core/network/apis/payment_mode_report_api.dart';
import '../../core/services/DataModels/payment_mode_report_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/payment_mode_report_shimmer.dart';
import 'report_page_state.dart';
import 'widgets/payment_mode_bars.dart';
import 'widgets/payment_mode_donut_card.dart';
import 'widgets/payment_mode_total_card.dart';
import 'widgets/payment_mode_transaction_counts.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_stale_banner.dart';

/// Payment Mode Breakdown — reached from Account > Report > Payment
/// Mode.
///
/// Shimmer / error / pull-to-refresh / connectivity-retry / custom
/// date range / stale-data handling all come from [ReportPageState].
/// The filter row (segment toggle + branch selector + custom-range
/// label) is shared with PnL and Revenue & Expense via
/// [ReportFilterBar]. This page only owns what's Payment-Mode-specific:
/// which API to call, the app bar, and the card layout below the
/// filter row.
class PaymentModeReportPage extends StatefulWidget {
  const PaymentModeReportPage({super.key});

  @override
  State<PaymentModeReportPage> createState() => _PaymentModeReportPageState();
}

class _PaymentModeReportPageState
    extends ReportPageState<PaymentModeReportPage, PaymentModeReportData> {
  final PaymentModeReportApi _api = PaymentModeReportApi();

  @override
  String get initialPeriod => 'this_month';

  @override
  String get loadErrorFallbackMessage =>
      "We couldn't load the payment mode breakdown right now. Please try again.";

  @override
  Future<ApiResponse<PaymentModeReportData>> fetchReport({
    required String period,
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.fetchPaymentModeReport(
      period: period,
      branchId: branchId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Payment Mode Breakdown",
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.large),
          ),
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (loading) {
      return const PaymentModeReportShimmer();
    }

    if (error != null) {
      return NetworkStateView(
        isOffline: isOffline,
        message: error,
        onRetry: loadReport,
      );
    }

    final reportData = data;
    if (reportData == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => loadReport(silent: true),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isStale) ...[
              const ReportStaleBanner(),
              const SizedBox(height: AppSpacing.verticalMedium),
            ],
            ReportFilterBar(
              periods: reportData.meta.periods,
              selectedPeriod: selectedPeriod,
              onPeriodChanged: handlePeriodChange,
              branches: reportData.meta.branches,
              selectedBranchId: selectedBranchId,
              onBranchChanged: handleBranchChange,
              customRangeLabel: customRangeLabel,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PaymentModeTotalCard(
              summary: reportData.summary,
              currencySymbol: reportData.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PaymentModeBars(
              modes: reportData.modes,
              currencySymbol: reportData.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PaymentModeDonutCard(
              modes: reportData.modes,
              total: reportData.summary.totalReceived,
              currencySymbol: reportData.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PaymentModeTransactionCounts(modes: reportData.modes),
            const SizedBox(height: AppSpacing.verticalMedium),
          ],
        ),
      ),
    );
  }
}
