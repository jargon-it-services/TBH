import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_response.dart';
import '../../core/network/apis/pnl_report_api.dart';
import '../../core/services/DataModels/pnl_report_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/pnl_report_shimmer.dart';
import 'report_page_state.dart';
import 'widgets/pnl_expense_categories_chart.dart';
import 'widgets/pnl_export_buttons.dart';
import 'widgets/pnl_monthly_comparison_table.dart';
import 'widgets/pnl_summary_cards.dart';
import 'widgets/pnl_trend_chart.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_stale_banner.dart';

/// Profit & Loss report — reached from Account > Report > PnL.
///
/// Shimmer / error / pull-to-refresh / connectivity-retry / custom
/// date range / stale-data handling all come from [ReportPageState] —
/// see that file for the shared behavior every report screen needs.
/// The filter row (segment toggle + branch selector + custom-range
/// label) is shared with Payment Mode and Revenue & Expense via
/// [ReportFilterBar]. This page only owns what's actually
/// PnL-specific: which API to call, the app bar, the card layout, and
/// Export PDF/Excel (Payment Mode doesn't have an export row, so that
/// stays here rather than in the shared base).
class PnlReportPage extends StatefulWidget {
  const PnlReportPage({super.key});

  @override
  State<PnlReportPage> createState() => _PnlReportPageState();
}

class _PnlReportPageState extends ReportPageState<PnlReportPage, PnlReportData> {
  final PnlReportApi _api = PnlReportApi();

  bool _exportingPdf = false;
  bool _exportingExcel = false;

  @override
  String get initialPeriod => '3m';

  @override
  String get loadErrorFallbackMessage =>
      "We couldn't load the P&L report right now. Please try again.";

  @override
  Future<ApiResponse<PnlReportData>> fetchReport({
    required String period,
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.fetchPnlReport(
      period: period,
      branchId: branchId,
      startDate: startDate,
      endDate: endDate,
    );
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
          "Profit & Loss",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
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
      return const PnlReportShimmer();
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
            PnlSummaryCards(
              summary: reportData.summary,
              currencySymbol: reportData.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PnlTrendChart(
              trend: reportData.trend,
              currencySymbol: reportData.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PnlExpenseCategoriesChart(categories: reportData.expenseCategories),
            const SizedBox(height: AppSpacing.verticalLarge),
            PnlMonthlyComparisonTable(
              comparison: reportData.monthlyComparison,
              currencySymbol: reportData.meta.currencySymbol,
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
