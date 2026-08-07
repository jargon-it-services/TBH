import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/api_response.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_snackbar.dart';

/// Shared state machine behind every report screen in this feature
/// (`PnlReportPage`, `PaymentModeReportPage`, `RevenueExpenseReportPage`).
///
/// All three screens need the exact same things: track the selected
/// segment/branch/custom-range, fetch on change, show a shimmer only
/// on the very first load, keep stale data on screen (flagged via
/// [isStale]) if a background refresh fails, and retry automatically
/// once connectivity returns (see [ConnectivityAwareRefresh]). Pulling
/// that into one base class means a fix like "Custom must stay
/// tappable even while already selected" (previously fixed separately
/// in each report's own period selector, now lives once in the shared
/// `PaymentModeSegmentSelector`) only needs making once, not once per
/// report screen.
///
/// A subclass only has to say *how* to fetch data ([fetchReport]),
/// which period it opens on ([initialPeriod]), and what to show if the
/// very first load fails outright ([loadErrorFallbackMessage]).
/// Everything else -- state fields, the load/retry/refresh flow, the
/// custom date range picker -- lives here once.
///
/// Members are deliberately public (no leading underscore): each
/// report page's `State` class lives in its own file and extends this
/// one, so these need to be visible across that file boundary.
abstract class ReportPageState<W extends StatefulWidget, T> extends State<W>
    with ConnectivityAwareRefresh<W> {
  bool loading = true;
  String? error;
  bool isOffline = false;

  /// True when what's on screen is left over from the last successful
  /// load, but the most recent (silent) refresh attempt failed. The
  /// screen keeps showing this data -- it's still the best information
  /// available -- but callers should surface [isStale] somewhere
  /// visible (see `ReportStaleBanner`) rather than letting a page that
  /// silently failed to refresh look fully current.
  bool isStale = false;

  T? data;

  late String selectedPeriod = initialPeriod;
  String selectedBranchId = 'all';
  DateTimeRange? customRange;

  /// Which period key the screen opens on -- e.g. PnL starts on
  /// `'3m'`, Payment Mode on `'this_month'`, Revenue & Expense on
  /// `'today'`.
  String get initialPeriod;

  /// Full-screen error message when the very first load fails outright
  /// (no previously-loaded data to fall back to yet).
  String get loadErrorFallbackMessage;

  /// Run the actual fetch for the given filters. Subclasses just call
  /// their own mock-aware API class here (e.g. `PnlReportApi`).
  Future<ApiResponse<T>> fetchReport({
    required String period,
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
  });

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  @override
  Future<void> onReconnected() => loadReport(silent: true);

  Future<void> loadReport({bool silent = false}) async {
    setState(() {
      if (!silent && data == null) loading = true;
      error = null;
    });

    final response = await fetchReport(
      period: selectedPeriod,
      branchId: selectedBranchId,
      startDate: customRange?.start,
      endDate: customRange?.end,
    );
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess && response.data != null) {
      setState(() {
        data = response.data;
        loading = false;
        isOffline = false;
        isStale = false;
      });
    } else {
      setState(() {
        loading = false;
        if (data == null) {
          error = response.error ?? loadErrorFallbackMessage;
          isOffline = response.isConnectivityError;
        } else {
          // Keep whatever's already on screen -- it's still more
          // useful than an empty state -- but flag it as possibly out
          // of date instead of silently acting like the refresh
          // worked.
          isStale = true;
          if (!response.isConnectivityError) {
            AppSnackbar.error(context, response.error ?? "Couldn't refresh the report.");
          }
        }
      });
    }
  }

  Future<void> handlePeriodChange(String key) async {
    if (key == 'custom') {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 3),
        lastDate: now,
        // Pre-fill with the range already chosen, if any, so
        // reopening "Custom" to change the range starts from where
        // you left off instead of forgetting it.
        initialDateRange: customRange ??
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
        selectedPeriod = 'custom';
        customRange = picked;
      });
      loadReport(silent: true);
      return;
    }

    setState(() {
      selectedPeriod = key;
      customRange = null;
    });
    loadReport(silent: true);
  }

  /// Takes the already-resolved branch id -- the name-to-id lookup
  /// stays in each page (it needs that page's own `T.meta.branches`
  /// shape, which this generic base class has no way to know about).
  void handleBranchChange(String branchId) {
    if (branchId == selectedBranchId) return;
    setState(() => selectedBranchId = branchId);
    loadReport(silent: true);
  }

  String get customRangeLabel {
    final range = customRange;
    if (range == null) return '';
    final formatter = DateFormat('dd MMM yyyy');
    return '${formatter.format(range.start)} — ${formatter.format(range.end)}';
  }
}
