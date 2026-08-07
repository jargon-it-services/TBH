import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/pnl_report_api.dart';
import '../../core/services/DataModels/pnl_report_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/pnl_report_shimmer.dart';
import 'widgets/pnl_expense_categories_chart.dart';
import 'widgets/pnl_export_buttons.dart';
import 'widgets/pnl_monthly_comparison_table.dart';
import 'widgets/pnl_period_selector.dart';
import 'widgets/pnl_summary_cards.dart';
import 'widgets/pnl_trend_chart.dart';

/// Profit & Loss report — reached from Account > Report > PnL.
///
/// Structure mirrors every other data-fetching screen in the app
/// (`ExpenseListPage`, `PaymentDetailsPage`, ...): shimmer while
/// loading, `NetworkStateView` on failure, pull-to-refresh, and
/// [ConnectivityAwareRefresh] for "retry automatically once back
/// online, but only if the last failure was connectivity-related".
///
/// No backend endpoint exists yet (`PnlReportApi` resolves from a
/// bundled mock JSON — see `Env.isMock`), so period/branch changes
/// just re-run the same mock-aware fetch with different query
/// parameters, exactly like every other filterable list in this app.
class PnlReportPage extends StatefulWidget {
  const PnlReportPage({super.key});

  @override
  State<PnlReportPage> createState() => _PnlReportPageState();
}

class _PnlReportPageState extends State<PnlReportPage>
    with ConnectivityAwareRefresh<PnlReportPage> {
  final PnlReportApi _api = PnlReportApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  PnlReportData? _data;

  String _selectedPeriod = '3m';
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

    final response = await _api.fetchPnlReport(
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
          _error =
              response.error ??
              "We couldn't load the P&L report right now. Please try again.";
          _isOffline = response.isConnectivityError;
        } else if (!response.isConnectivityError) {
          AppSnackbar.error(
            context,
            response.error ?? "Couldn't refresh the report.",
          );
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
        initialDateRange:
            _customRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        ),
      );
      if (picked == null) return; // user cancelled — keep current period
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
          "Profit & Loss",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
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
    if (_loading) {
      return const PnlReportShimmer();
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: PnlPeriodSelector(
                    periods: data.meta.periods,
                    selectedKey: _selectedPeriod,
                    onChanged: _handlePeriodChange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: JargonDropdown(
                    label: 'Branch',
                    value: selectedBranchName,
                    icon: Icons.storefront_outlined,
                    options: branches.map((b) => b.name).toList(),
                    onChanged: (name) => _handleBranchChange(name),
                    showIconBackground: false,
                    showLabel: false,
                  ),
                ),
              ],
            ),
            if (_selectedPeriod == 'custom' && _customRange != null) ...[
              const SizedBox(height: AppSpacing.verticalSmall),
              Text(
                'Showing data for $_customRangeLabel',
                style: AppTextStyles.caption,
              ),
            ],
            const SizedBox(height: AppSpacing.verticalLarge),
            PnlSummaryCards(
              summary: data.summary,
              currencySymbol: data.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PnlTrendChart(
              trend: data.trend,
              currencySymbol: data.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PnlExpenseCategoriesChart(categories: data.expenseCategories),
            const SizedBox(height: AppSpacing.verticalLarge),
            PnlMonthlyComparisonTable(
              comparison: data.monthlyComparison,
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
