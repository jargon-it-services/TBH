import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/payment_mode_report_api.dart';
import '../../core/services/DataModels/payment_mode_report_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/payment_mode_report_shimmer.dart';
import 'widgets/payment_mode_bars.dart';
import 'widgets/payment_mode_donut_card.dart';
import 'widgets/payment_mode_segment_selector.dart';
import 'widgets/payment_mode_total_card.dart';
import 'widgets/payment_mode_transaction_counts.dart';

/// Payment Mode Breakdown — reached from Account > Report > Payment
/// Mode.
///
/// Structure mirrors `PnlReportPage` exactly (same shimmer / error /
/// pull-to-refresh / connectivity-retry shape via `PaymentModeReportApi`
/// mock-aware fetch), with two differences the spec calls for: the
/// branch selector sits in its own row *below* the segment toggle
/// (P&L puts branch beside the period pills), and the segment toggle
/// has seven options instead of four, so it scrolls horizontally
/// rather than filling the width with `Expanded` tabs.
class PaymentModeReportPage extends StatefulWidget {
  const PaymentModeReportPage({super.key});

  @override
  State<PaymentModeReportPage> createState() => _PaymentModeReportPageState();
}

class _PaymentModeReportPageState extends State<PaymentModeReportPage>
    with ConnectivityAwareRefresh<PaymentModeReportPage> {
  final PaymentModeReportApi _api = PaymentModeReportApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  PaymentModeReportData? _data;

  String _selectedPeriod = 'this_month';
  String _selectedBranchId = 'all';
  DateTimeRange? _customRange;

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

    final response = await _api.fetchPaymentModeReport(
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
              "We couldn't load the payment mode breakdown right now. Please try again.";
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
        // Pre-fill with the range already chosen, if any, so reopening
        // "Custom" to change the range starts from where you left off
        // instead of forgetting it.
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
          "Payment Mode Breakdown",
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
      return const PaymentModeReportShimmer();
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
            // Branch selector below the segment toggle, per spec —
            // unlike PnL's side-by-side layout.
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
            PaymentModeTotalCard(
              summary: data.summary,
              currencySymbol: data.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PaymentModeBars(
              modes: data.modes,
              currencySymbol: data.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PaymentModeDonutCard(
              modes: data.modes,
              total: data.summary.totalReceived,
              currencySymbol: data.meta.currencySymbol,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            PaymentModeTransactionCounts(modes: data.modes),
            const SizedBox(height: AppSpacing.verticalMedium),
          ],
        ),
      ),
    );
  }
}
