import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_response.dart';
import '../../core/network/apis/employee_performance_report_api.dart';
import '../../core/services/DataModels/employee_performance_report_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/employee_performance_report_shimmer.dart';
import 'report_page_state.dart';
import 'widgets/employee_ranking_table.dart';
import 'widgets/pnl_export_buttons.dart';
import 'widgets/report_filter_bar.dart';
import 'widgets/report_stale_banner.dart';
import 'widgets/top_performer_card.dart';

/// Employee Performance Report — reached from Account > Report >
/// Employee Performance Report.
///
/// Shimmer / error / pull-to-refresh / connectivity-retry / custom
/// date range / stale-data handling all come from [ReportPageState] —
/// see that file for the shared behavior every report screen needs.
/// The filter row (segment toggle + branch selector + custom-range
/// label) is the same [ReportFilterBar] PnL, Payment Mode and Revenue
/// & Expense already use — this page only owns what's specific to
/// Employee Performance: which API to call, the app bar, the Top
/// Performer card, and the ranking table below it.
class EmployeePerformanceReportPage extends StatefulWidget {
  const EmployeePerformanceReportPage({super.key});

  @override
  State<EmployeePerformanceReportPage> createState() =>
      _EmployeePerformanceReportPageState();
}

class _EmployeePerformanceReportPageState
    extends ReportPageState<EmployeePerformanceReportPage, EmployeePerformanceReportData> {
  final EmployeePerformanceReportApi _api = EmployeePerformanceReportApi();

  bool _exportingPdf = false;
  bool _exportingExcel = false;

  @override
  String get initialPeriod => 'this_month';

  @override
  String get loadErrorFallbackMessage =>
      "We couldn't load the employee performance report right now. Please try again.";

  @override
  Future<ApiResponse<EmployeePerformanceReportData>> fetchReport({
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
          "Employee Performance Report",
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
      return const EmployeePerformanceReportShimmer();
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
              branches: reportData.meta.branches,
              selectedBranchId: selectedBranchId,
              onBranchChanged: handleBranchChange,
              customRangeLabel: customRangeLabel,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            TopPerformerCard(
              performer: reportData.topPerformer,
              currencySymbol: currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            EmployeeRankingTable(
              section: reportData.ranking,
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
