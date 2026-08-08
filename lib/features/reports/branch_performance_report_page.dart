import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_response.dart';
import '../../core/network/apis/branch_performance_report_api.dart';
import '../../core/services/DataModels/branch_performance_report_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/branch_performance_report_shimmer.dart';
import 'report_page_state.dart';
import 'widgets/branch_comparison_chart.dart';
import 'widgets/branch_overview_card.dart';
import 'widgets/branch_performance_card.dart';
import 'widgets/pnl_export_buttons.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_stale_banner.dart';
import 'widgets/top_employee_comparison_table.dart';

/// Branch Performance Breakdown — reached from Account > Report >
/// Branch Performance Breakdown.
///
/// Shimmer / error / pull-to-refresh / connectivity-retry / custom
/// date range / stale-data handling all come from [ReportPageState] —
/// see that file for the shared behavior every report screen needs.
///
/// Unlike PnL, Payment Mode and Revenue & Expense, this screen has no
/// branch selector — comparing branches *is* the report, so it always
/// shows every branch for the chosen period. It still reuses
/// [ReportFilterBar] (segment toggle + custom-range label) rather than
/// the lower-level `ReportSegmentSelector`, just with
/// `showBranchSelector: false` to drop the branch dropdown.
class BranchPerformanceReportPage extends StatefulWidget {
  const BranchPerformanceReportPage({super.key});

  @override
  State<BranchPerformanceReportPage> createState() => _BranchPerformanceReportPageState();
}

class _BranchPerformanceReportPageState
    extends ReportPageState<BranchPerformanceReportPage, BranchPerformanceReportData> {
  final BranchPerformanceReportApi _api = BranchPerformanceReportApi();

  bool _exportingPdf = false;
  bool _exportingExcel = false;

  @override
  String get initialPeriod => 'this_month';

  @override
  String get loadErrorFallbackMessage =>
      "We couldn't load the branch performance report right now. Please try again.";

  @override
  Future<ApiResponse<BranchPerformanceReportData>> fetchReport({
    required String period,
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // No branch filter on this report by design — every branch always
    // comes back so they can be compared against each other.
    return _api.fetchReport(period: period, startDate: startDate, endDate: endDate);
  }

  Future<void> _openLink(String? url, {required String failureLabel}) async {
    if (url == null || url.isEmpty) {
      if (mounted) AppSnackbar.error(context, "Couldn't open $failureLabel");
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      AppSnackbar.error(context, "Couldn't open $failureLabel");
    }
  }

  Future<void> _handleExport(String format) async {
    final isPdf = format == 'pdf';
    setState(() => isPdf ? _exportingPdf = true : _exportingExcel = true);

    final response = await _api.exportReport(format: format);
    if (!mounted) return;

    setState(() => isPdf ? _exportingPdf = false : _exportingExcel = false);

    if (response.isSuccess) {
      await _openLink(
        response.data,
        failureLabel: isPdf ? 'the PDF export' : 'the Excel export',
      );
    } else {
      AppSnackbar.error(
        context,
        response.error ?? "We couldn't generate that export right now.",
      );
    }
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
          "Branch Performance Breakdown",
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.large)),
        ),
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (loading) {
      return const BranchPerformanceReportShimmer();
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

    final items = reportData.branchPerformance.items;
    final currencySymbol = reportData.meta.currencySymbol;

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
              customRangeLabel: customRangeLabel,
              showBranchSelector: false,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            BranchOverviewCard(
              overview: reportData.overview,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            BranchPerformanceCard(
              section: reportData.branchPerformance,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: BranchComparisonChart(
                    title: 'Revenue Comparison',
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.primary,
                    items: items,
                    valueOf: (item) => item.revenue,
                    currencySymbol: currencySymbol,
                  ),
                ),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(
                  child: BranchComparisonChart(
                    title: 'Profit Comparison',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                    items: items,
                    valueOf: (item) => item.profit,
                    currencySymbol: currencySymbol,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            BranchComparisonChart(
              title: 'Expense Comparison',
              icon: Icons.receipt_long_outlined,
              color: AppColors.secondary,
              items: items,
              valueOf: (item) => item.expenses,
              currencySymbol: currencySymbol,
              height: 220,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            TopEmployeeComparisonTable(
              section: reportData.topEmployees,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PnlExportButtons(
              isExportingPdf: _exportingPdf,
              isExportingExcel: _exportingExcel,
              onExportPdf: () => _handleExport('pdf'),
              onExportExcel: () => _handleExport('excel'),
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
          ],
        ),
      ),
    );
  }
}
