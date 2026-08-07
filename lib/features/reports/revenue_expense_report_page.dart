import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/revenue_expense_report_api.dart';
import '../../core/services/DataModels/revenue_expense_report_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/revenue_expense_report_shimmer.dart';
import 'widgets/expense_breakdown_card.dart';
import 'widgets/payment_mode_segment_selector.dart';
import 'widgets/pnl_export_buttons.dart';
import 'widgets/revenue_expense_summary_cards.dart';
import 'widgets/revenue_trend_chart_card.dart';
import 'widgets/top_services_card.dart';

/// Revenue & Expense report — reached from Account > Report > Revenue
/// & Expense Summary.
///
/// Deliberately reuses [PaymentModeSegmentSelector] and
/// [PnlExportButtons] as-is rather than cloning near-identical
/// widgets: both are fully generic/presentational already (periods +
/// selectedKey + onChanged; export loading state + callbacks), and the
/// brief was explicit about keeping the segment-toggle/branch layout
/// consistent with Payment Mode -- reusing the same widget guarantees
/// that rather than two copies quietly drifting apart over time.
///
/// Every card (summary, trend, expense breakdown, top services) is
/// driven by the single top segment toggle + branch selector -- there
/// is intentionally no independent per-card period control.
class RevenueExpenseReportPage extends StatefulWidget {
  const RevenueExpenseReportPage({super.key});

  @override
  State<RevenueExpenseReportPage> createState() => _RevenueExpenseReportPageState();
}

class _RevenueExpenseReportPageState extends State<RevenueExpenseReportPage>
    with ConnectivityAwareRefresh<RevenueExpenseReportPage> {
  final RevenueExpenseReportApi _api = RevenueExpenseReportApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  RevenueExpenseReportData? _data;

  String _selectedPeriod = 'today';
  String _selectedBranchId = 'all';
  DateTimeRange? _customRange;

  bool _exportingPdf = false;
  bool _exportingExcel = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  Future<void> onReconnected() => _loadReport(silent: true);

  Future<void> _loadReport({bool silent = false}) async {
    setState(() {
      if (!silent && _data == null) _loading = true;
      _error = null;
    });

    final response = await _api.fetchReport(
      period: _selectedPeriod,
      branchId: _selectedBranchId,
      startDate: _customRange?.start,
      endDate: _customRange?.end,
    );
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess && response.data != null) {
      setState(() {
        _data = response.data;
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        if (_data == null) {
          _error = response.error ??
              "We couldn't load the revenue & expense report right now. Please try again.";
          _isOffline = response.isConnectivityError;
        } else if (!response.isConnectivityError) {
          AppSnackbar.error(context, response.error ?? "Couldn't refresh the report.");
        }
      });
    }
  }

  Future<void> _handlePeriodChange(String key) async {
    if (key == 'custom') {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 3),
        lastDate: now,
        // Pre-fill with the range already chosen, if any, so
        // reopening "Custom" to change the range starts from where
        // you left off instead of forgetting it.
        initialDateRange: _customRange ??
            DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        ),
      );
      if (picked == null) return; // cancelled — keep current selection
      setState(() {
        _selectedPeriod = 'custom';
        _customRange = picked;
      });
      _loadReport(silent: true);
      return;
    }

    setState(() {
      _selectedPeriod = key;
      _customRange = null;
    });
    _loadReport(silent: true);
  }

  void _handleBranchChange(String branchName) {
    final branches = _data?.meta.branches ?? const <PnlBranchOption>[];
    final match = branches.where((b) => b.name == branchName);
    final branchId = match.isNotEmpty ? match.first.id : 'all';
    if (branchId == _selectedBranchId) return;
    setState(() => _selectedBranchId = branchId);
    _loadReport(silent: true);
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

  String get _customRangeLabel {
    final range = _customRange;
    if (range == null) return '';
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(range.start)} — ${formatter.format(range.end)}';
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
    if (_loading) {
      return const RevenueExpenseReportShimmer();
    }

    if (_error != null) {
      return NetworkStateView(
        isOffline: _isOffline,
        message: _error,
        onRetry: _loadReport,
      );
    }

    final data = _data;
    if (data == null) return const SizedBox.shrink();

    final branches = data.meta.branches;
    final selectedBranchName = branches
        .firstWhere(
          (b) => b.id == _selectedBranchId,
          orElse: () => const PnlBranchOption(id: 'all', name: 'All Branches'),
        )
        .name;

    return RefreshIndicator(
      onRefresh: () => _loadReport(silent: true),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PaymentModeSegmentSelector(
              periods: data.meta.periods,
              selectedKey: _selectedPeriod,
              onChanged: _handlePeriodChange,
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
            if (_selectedPeriod == 'custom' && _customRange != null) ...[
              const SizedBox(height: AppSpacing.verticalSmall),
              Text(
                'Showing data for $_customRangeLabel',
                style: AppTextStyles.caption,
              ),
            ],
            const SizedBox(height: AppSpacing.verticalLarge),
            RevenueExpenseSummaryCards(
              summary: data.summary,
              currencySymbol: data.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            RevenueTrendChartCard(
              trend: data.trend,
              currencySymbol: data.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            ExpenseBreakdownCard(
              breakdown: data.expenseBreakdown,
              currencySymbol: data.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            TopServicesCard(
              section: data.topServices,
              currencySymbol: data.meta.currencySymbol,
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
