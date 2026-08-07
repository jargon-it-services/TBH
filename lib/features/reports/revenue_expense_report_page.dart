import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_response.dart';
import '../../core/network/apis/revenue_expense_report_api.dart';
import '../../core/services/DataModels/revenue_expense_report_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/revenue_expense_report_shimmer.dart';
import 'report_page_state.dart';
import 'widgets/expense_breakdown_card.dart';
import 'widgets/payment_mode_segment_selector.dart';
import 'widgets/pnl_export_buttons.dart';
import 'widgets/report_stale_banner.dart';
import 'widgets/revenue_expense_summary_cards.dart';
import 'widgets/revenue_trend_chart_card.dart';
import 'widgets/top_services_card.dart';

/// Revenue & Expense report — reached from Account > Report > Revenue
/// & Expense Summary.
///
/// Shimmer / error / pull-to-refresh / connectivity-retry / custom
/// date range / stale-data handling all come from [ReportPageState].
/// This page only owns what's specific to it: which API to call, the
/// app bar, the card layout, and Export PDF/Excel.
///
/// Deliberately reuses [PaymentModeSegmentSelector] and
/// [PnlExportButtons] as-is rather than cloning near-identical
/// widgets: both are fully generic/presentational already, and the
/// brief was explicit about keeping the segment-toggle/branch layout
/// consistent with Payment Mode.
///
/// Every card (summary, trend, expense breakdown, top services) is
/// driven by the single top segment toggle + branch selector -- there
/// is intentionally no independent per-card period control.
class RevenueExpenseReportPage extends StatefulWidget {
  const RevenueExpenseReportPage({super.key});

  @override
  State<RevenueExpenseReportPage> createState() => _RevenueExpenseReportPageState();
}

class _RevenueExpenseReportPageState
    extends ReportPageState<RevenueExpenseReportPage, RevenueExpenseReportData> {
  final RevenueExpenseReportApi _api = RevenueExpenseReportApi();

  bool _exportingPdf = false;
  bool _exportingExcel = false;

  @override
  String get initialPeriod => 'today';

  @override
  String get loadErrorFallbackMessage =>
      "We couldn't load the revenue & expense report right now. Please try again.";

  @override
  Future<ApiResponse<RevenueExpenseReportData>> fetchReport({
    required String period,
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.fetchReport(
      period: period,
      branchId: branchId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  void _handleBranchChange(String branchName) {
    final branches = data?.meta.branches ?? const <PnlBranchOption>[];
    final match = branches.where((b) => b.name == branchName);
    handleBranchChange(match.isNotEmpty ? match.first.id : 'all');
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
          "Revenue & Expense",
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
      return const RevenueExpenseReportShimmer();
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

    final branches = reportData.meta.branches;
    final selectedBranchName = branches
        .firstWhere(
          (b) => b.id == selectedBranchId,
          orElse: () => const PnlBranchOption(id: 'all', name: 'All Branches'),
        )
        .name;

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
            PaymentModeSegmentSelector(
              periods: reportData.meta.periods,
              selectedKey: selectedPeriod,
              onChanged: handlePeriodChange,
            ),
            const SizedBox(height: AppSpacing.verticalSmall),
            // Branch selector below the segment toggle, matching
            // Payment Mode's layout exactly per the brief.
            JargonDropdown(
              label: 'Branch',
              value: selectedBranchName,
              icon: Icons.storefront_outlined,
              options: branches.map((b) => b.name).toList(),
              onChanged: (name) => _handleBranchChange(name),
              showIconBackground: false,
              showLabel: false,
            ),
            if (selectedPeriod == 'custom' && customRange != null) ...[
              const SizedBox(height: AppSpacing.verticalSmall),
              Text(
                'Showing data for $customRangeLabel',
                style: AppTextStyles.caption,
              ),
            ],
            const SizedBox(height: AppSpacing.verticalLarge),
            RevenueExpenseSummaryCards(
              summary: reportData.summary,
              currencySymbol: reportData.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            RevenueTrendChartCard(
              trend: reportData.trend,
              currencySymbol: reportData.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            ExpenseBreakdownCard(
              breakdown: reportData.expenseBreakdown,
              currencySymbol: reportData.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            TopServicesCard(
              section: reportData.topServices,
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
