import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/connectivity/connectivity_aware_refresh.dart';
import '../../../core/network/apis/dashboard_api.dart';
import '../../../core/services/DataModels/dashboard_models.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/alert_slider.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/business_summary_card.dart';
import '../../../core/widgets/card_wrapper.dart';
import '../../../core/widgets/no_internet_page.dart';
import '../../../core/widgets/revenue_trend_chart.dart';
import '../../../core/widgets/shimmers/dashboard_shimmer.dart';

/// =====================================================================
/// SHARED DASHBOARD-BODY BUILDING BLOCKS
/// =====================================================================
///
/// [DashboardPeriod], [DashboardKpiData]/[KpiSection], the alert types +
/// [importantAlertsSection], and [RevenueContributionChart] below are
/// used by all four role dashboards (Account Admin, Branch Admin,
/// Manager, Employee). None of them existed as reusable widgets before
/// this task, and this task's file scope is limited to the four
/// `role_dashboards/*.dart` files — so rather than leaving four
/// near-duplicate copies (which the "no duplicated code" requirement
/// rules out), they live here, once, and the other three dashboards
/// import this file for them. The natural home for these is
/// `lib/core/widgets/` alongside [BusinessSummaryCard] and
/// [RevenueTrendChart] — moving them there is a follow-up outside this
/// task's file allowance, not a change in what the code does.
///
/// [BusinessSummaryCard], [RevenueTrendChart], [AlertSlider] and
/// [AnimatedEmptyState] are reused as-is from `core/widgets` per the
/// task's "reuse, don't recreate" requirement.

/// ---------------------------------------------------------------------
/// Period
/// ---------------------------------------------------------------------

enum DashboardPeriod { today, thisWeek, thisMonth, thisYear }

extension DashboardPeriodX on DashboardPeriod {
  /// Short label shown on the [DashboardPeriodSelector] pill/tab.
  String get label {
    switch (this) {
      case DashboardPeriod.today:
        return 'Daily';
      case DashboardPeriod.thisWeek:
        return 'Weekly';
      case DashboardPeriod.thisMonth:
        return 'Monthly';
      case DashboardPeriod.thisYear:
        return 'Yearly';
    }
  }

  /// Value sent to [DashboardApi.fetchRevenueTrend]'s `period` query
  /// parameter, and the noun used in "this <noun>'s data" copy below.
  String get apiValue {
    switch (this) {
      case DashboardPeriod.today:
        return 'daily';
      case DashboardPeriod.thisWeek:
        return 'weekly';
      case DashboardPeriod.thisMonth:
        return 'monthly';
      case DashboardPeriod.thisYear:
        return 'yearly';
    }
  }

  String get noun {
    switch (this) {
      case DashboardPeriod.today:
        return "today";
      case DashboardPeriod.thisWeek:
        return "this week";
      case DashboardPeriod.thisMonth:
        return "this month";
      case DashboardPeriod.thisYear:
        return "this year";
    }
  }
}

/// Reusable, theme-aware period picker driving the dashboard refresh.
///
/// Segmented "pill" control (Daily / Weekly / Monthly / Yearly) matching
/// the approved period-selector design, built with the app's existing
/// design tokens ([AppColors]/[AppRadius]/[AppSpacing]/[AppTextStyles])
/// instead of the earlier [JargonDropdown]-based picker. Public API
/// (`value`/`onChanged`) is unchanged, so every dashboard that already
/// wires this up (Account Admin, Branch Admin, Manager, Employee) picks
/// up the new look with no call-site changes. Super Admin has no period
/// concept today ([SuperAdminDashboard] is a placeholder) and is
/// intentionally untouched.
class DashboardPeriodSelector extends StatelessWidget {
  final DashboardPeriod value;
  final ValueChanged<DashboardPeriod> onChanged;

  const DashboardPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final period in DashboardPeriod.values)
            Expanded(
              child: _PeriodTab(
                label: period.label,
                isActive: period == value,
                onTap: () {
                  if (period != value) onChanged(period);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color:
                isActive ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// KPI section
/// ---------------------------------------------------------------------

/// KPI figures for the dashboard's KPI section, derived from whatever
/// the shared [DashboardResponse] already carries. [totalServices],
/// [customersServed] and [totalRevenue] are backed by real fields
/// ([DashboardCounts] and the sum of [FirmModel.revenue]);
/// [totalExpenses] and [totalProfit] have no backing field in
/// [DashboardData] today, so they're nullable and render as "—" rather
/// than a fabricated number — see this task's accompanying notes for
/// the response-field addition this needs.
class DashboardKpiData {
  final int totalServices;
  final int? customersServed;
  final double totalRevenue;
  final double? totalExpenses;
  final double? totalProfit;

  const DashboardKpiData({
    required this.totalServices,
    required this.totalRevenue,
    this.customersServed,
    this.totalExpenses,
    this.totalProfit,
  });

  factory DashboardKpiData.fromDashboardData(DashboardData data) {
    final double revenue = data.firms.fold(0.0, (sum, f) => sum + f.revenue);
    return DashboardKpiData(
      totalServices: data.meta.counts.totalServices,
      customersServed: data.meta.counts.totalCustomers,
      totalRevenue: revenue,
    );
  }
}

class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.horizontalMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(height: AppSpacing.verticalSmall),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h3.copyWith(
                fontSize: 16,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// One icon+count pair used in the middle of [ServicesCustomersKpiCard]
/// (its "Customers" or "Services" half).
class _KpiIconStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String count;

  const _KpiIconStat({
    required this.icon,
    required this.iconColor,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 15),
        const SizedBox(width: 4),
        Text(
          count,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.h3.copyWith(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// "Total Services Served" KPI card.
///
/// Same layout as every other [KpiCard] — icon box on top, then the
/// figure, then the label — except the middle "figure" slot holds two
/// icon+count pairs (Customers, then Services) instead of a single
/// value, so both counts are visible at a glance. Same card chrome
/// (border/shadow/radius/tap target) and the same top icon box and
/// bottom label style as the other KPI cards for visual consistency.
///
/// [customersServed] renders as "—" until the backend adds the
/// corresponding count to the dashboard response (see
/// [DashboardCounts.totalCustomers]).
class ServicesCustomersKpiCard extends StatelessWidget {
  final int totalServices;
  final int? customersServed;
  final VoidCallback onTap;

  const ServicesCustomersKpiCard({
    super.key,
    required this.totalServices,
    required this.onTap,
    this.customersServed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.large),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.horizontalMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: const Icon(
                Icons.design_services_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(height: AppSpacing.verticalSmall),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _KpiIconStat(
                  icon: Icons.people_alt_outlined,
                  iconColor: AppColors.secondary,
                  count: customersServed != null ? '$customersServed' : '—',
                ),
                const SizedBox(width: 24),
                _KpiIconStat(
                  icon: Icons.design_services_outlined,
                  iconColor: AppColors.primary,
                  count: '$totalServices',
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Total Services Served',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enterprise KPI section: Total Services Served (shown as a
/// [ServicesCustomersKpiCard] with a Services icon+count and a
/// Customers icon+count side by side), Total Expenses, Total Revenue
/// and Total Profit — one responsive, themed, clickable card per
/// figure, all inside a single "Quick Insights" [CardWrapper] (white
/// background + elevation), matching [BusinessSummaryCard]'s own
/// heading + card styling. Every card's `onTap` is intentionally empty
/// per this task's instructions; wiring real navigation is follow-up
/// work once each KPI has a destination to open.
class KpiSection extends StatelessWidget {
  final DashboardKpiData data;
  final DashboardPeriod period;

  const KpiSection({super.key, required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      ServicesCustomersKpiCard(
        totalServices: data.totalServices,
        customersServed: data.customersServed,
        onTap: () {},
      ),
      KpiCard(
        icon: Icons.currency_rupee_rounded,
        label: 'Total Revenue',
        value: CurrencyUtils.format(data.totalRevenue),
        onTap: () {},
      ),
      KpiCard(
        icon: Icons.receipt_long_outlined,
        label: 'Total Expenses',
        value: data.totalExpenses != null
            ? CurrencyUtils.format(data.totalExpenses!)
            : '—',
        onTap: () {},
      ),
      KpiCard(
        icon: Icons.trending_up_rounded,
        label: 'Total Profit',
        value: data.totalProfit != null
            ? CurrencyUtils.format(data.totalProfit!)
            : '—',
        valueColor: data.totalProfit == null
            ? null
            : (data.totalProfit! >= 0 ? AppColors.income : AppColors.expense),
        onTap: () {},
      ),
    ];

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Quick Insights', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 520 ? 4 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppSpacing.horizontalSmall,
                  crossAxisSpacing: AppSpacing.horizontalSmall,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) => tiles[index],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Important Alerts
/// ---------------------------------------------------------------------

enum DashboardAlertType { info, warning, error, success }

class DashboardAlertData {
  final DashboardAlertType type;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;

  const DashboardAlertData({
    required this.type,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCtaTap,
  });
}

Color _alertBg(DashboardAlertType type) {
  switch (type) {
    case DashboardAlertType.error:
      return AppColors.error.withOpacity(0.08);
    case DashboardAlertType.warning:
      return AppColors.warning.withOpacity(0.10);
    case DashboardAlertType.success:
      return AppColors.success.withOpacity(0.08);
    case DashboardAlertType.info:
      return AppColors.primary.withOpacity(0.08);
  }
}

Color _alertColor(DashboardAlertType type) {
  switch (type) {
    case DashboardAlertType.error:
      return AppColors.error;
    case DashboardAlertType.warning:
      return AppColors.warning;
    case DashboardAlertType.success:
      return AppColors.success;
    case DashboardAlertType.info:
      return AppColors.primary;
  }
}

IconData _alertIcon(DashboardAlertType type) {
  switch (type) {
    case DashboardAlertType.error:
      return Icons.error_outline;
    case DashboardAlertType.warning:
      return Icons.warning_amber_rounded;
    case DashboardAlertType.success:
      return Icons.check_circle_outline;
    case DashboardAlertType.info:
      return Icons.info_outline;
  }
}

class DashboardAlertCard extends StatelessWidget {
  final DashboardAlertData alert;

  const DashboardAlertCard({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(alert.type);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: _alertBg(alert.type),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_alertIcon(alert.type), color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(alert.message, style: AppTextStyles.bodySmall),
                if (alert.ctaLabel != null && alert.onCtaTap != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: alert.onCtaTap,
                    child: Text(alert.ctaLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Data-driven: renders nothing when [alerts] is empty (the same rule
/// [AlertSlider] already applies), rather than a hardcoded, always-shown
/// alert. [DashboardData] has no `alerts` field yet — see this task's
/// accompanying notes — so every caller currently passes `const []`, and
/// this section stays invisible until that field exists.
Widget importantAlertsSection(List<DashboardAlertData> alerts) {
  return AlertSlider<DashboardAlertData>(
    alerts: alerts,
    itemBuilder: (_, alert) => DashboardAlertCard(alert: alert),
  );
}

/// ---------------------------------------------------------------------
/// Revenue Contribution
/// ---------------------------------------------------------------------

class RevenueContributionSlice {
  final String label;
  final double value;

  const RevenueContributionSlice({required this.label, required this.value});
}

const List<Color> _pieColors = [
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF00BCD4),
  Color(0xFF8BC34A),
  Color(0xFFFF5722),
];

/// Generalization of the pie-chart-plus-legend pattern the legacy admin
/// dashboard built inline (firm-revenue split) into a reusable widget
/// that any role can feed a different slice source into — Account Admin
/// passes firm-level revenue, Branch Admin passes staff-level revenue
/// within the branch, since a single branch has only one "firm".
class RevenueContributionChart extends StatelessWidget {
  final String title;
  final List<RevenueContributionSlice> slices;
  final DashboardPeriod period;
  final String emptyTitle;
  final String emptyMessage;

  const RevenueContributionChart({
    super.key,
    required this.title,
    required this.slices,
    required this.period,
    this.emptyTitle = 'No Revenue Split Available',
    this.emptyMessage =
        'Revenue contribution will appear once sales are recorded.',
  });

  double get _total => slices.fold(0.0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty || _total == 0) {
      return AnimatedEmptyState(
        icon: Icons.pie_chart_outline,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pie_chart, color: AppColors.primary),
            const SizedBox(width: AppSpacing.horizontalSmall),
            Text(title, style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: AppSpacing.verticalSmall),
        Text(
          "This represents ${period.noun}'s contribution.",
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 35),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 45,
              sectionsSpace: 2,
              sections: List.generate(slices.length, (index) {
                final slice = slices[index];
                return PieChartSectionData(
                  value: slice.value,
                  color: _pieColors[index % _pieColors.length],
                  radius: 55,
                  showTitle: false,
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: List.generate(slices.length, (index) {
            final slice = slices[index];
            final percent = (slice.value / _total) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: _pieColors[index % _pieColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      slice.label,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "${percent.toStringAsFixed(1)}%",
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Generic error view shared by every role dashboard's body (distinct
/// from the sticky header's own inline error bar).
/// ---------------------------------------------------------------------

class DashboardBodyErrorView extends StatelessWidget {
  final String message;
  final bool isConnectivityError;
  final VoidCallback onRetry;

  const DashboardBodyErrorView({
    super.key,
    required this.message,
    required this.isConnectivityError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnectivityError) {
      return NoInternetPage(onRetry: onRetry);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: AppSpacing.verticalSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =====================================================================
/// ACCOUNT ADMIN DASHBOARD
/// =====================================================================
///
/// Shows Important Alerts, the Period Selector, the KPI section,
/// Business Summary, Revenue Trend and Revenue Contribution — scoped to
/// the selected organization/branch and period. The org/branch scope
/// itself is selected in [DashboardStickyHeader]; this widget refetches
/// whenever [selectedBranchId] changes (see [didUpdateWidget]), so once
/// [DashboardPage] is wired to forward the header's `onScopeChanged`
/// here (an additive change outside this task's file scope — see repo
/// notes), switching branch already refreshes this body without any
/// further change to this file.
class AccountAdminDashboard extends StatefulWidget {
  const AccountAdminDashboard({super.key, this.selectedBranchId});

  /// Id of the org/branch currently selected in the sticky header, or
  /// null for "All ...". Only used to decide *when* to refetch (see
  /// [didUpdateWidget]) — the actual scoping happens server-side, same
  /// as every other authenticated call (see [DioClient]), once
  /// [DashboardApi.fetchAdminDashboard] accepts a scope parameter.
  final String? selectedBranchId;

  @override
  State<AccountAdminDashboard> createState() => _AccountAdminDashboardState();
}

class _AccountAdminDashboardState extends State<AccountAdminDashboard>
    with ConnectivityAwareRefresh<AccountAdminDashboard> {
  final DashboardApi _api = DashboardApi();

  bool _loading = true;
  String? _error;
  bool _isConnectivityError = false;
  DashboardData? _data;

  DashboardPeriod _period = DashboardPeriod.thisMonth;
  List<TrendPoint> _revenueTrend = [];
  bool _hasPrevTrend = false;
  bool _hasNextTrend = false;
  String? _prevCursor;
  String? _nextCursor;
  bool _loadingTrend = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AccountAdminDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBranchId != widget.selectedBranchId) {
      _load(silent: true);
    }
  }

  @override
  Future<void> onReconnected() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    setState(() {
      if (!silent && _data == null) _loading = true;
      _error = null;
    });

    final result = await _api.fetchAdminDashboard();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !result.isSuccess && result.isConnectivityError;

    if (result.isSuccess && result.data != null) {
      final data = result.data!.data;
      final trend = data.overviewTrend;
      setState(() {
        _data = data;
        _revenueTrend = trend?.points ?? [];
        _hasPrevTrend = trend?.prevCursor != null;
        _hasNextTrend = trend?.nextCursor != null;
        _prevCursor = trend?.prevCursor;
        _nextCursor = trend?.nextCursor;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        if (_data == null) {
          _error = result.error ?? "Oops! We couldn't load the dashboard.";
          _isConnectivityError = result.isConnectivityError;
        }
      });
    }
  }

  Future<void> _loadTrend({String? cursor, required bool isNext}) async {
    if (_loadingTrend) return;
    setState(() => _loadingTrend = true);

    final result = await _api.fetchRevenueTrend(
      period: _period.apiValue,
      cursor: cursor,
      isNext: isNext,
    );
    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final trend = result.data!;
      setState(() {
        _revenueTrend = trend.points;
        _hasPrevTrend = trend.prevCursor != null;
        _hasNextTrend = trend.nextCursor != null;
        _prevCursor = trend.prevCursor;
        _nextCursor = trend.nextCursor;
      });
    }

    setState(() => _loadingTrend = false);
  }

  void _onPeriodChanged(DashboardPeriod period) {
    setState(() => _period = period);
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const DashboardShimmer();

    if (_error != null) {
      return DashboardBodyErrorView(
        message: _error!,
        isConnectivityError: _isConnectivityError,
        onRetry: _load,
      );
    }

    final data = _data;
    if (data == null) return const DashboardShimmer();

    return RefreshIndicator(
      onRefresh: () => _load(silent: true),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            importantAlertsSection(const []),
            const SizedBox(height: AppSpacing.verticalSmall),
            DashboardPeriodSelector(
              value: _period,
              onChanged: _onPeriodChanged,
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            KpiSection(
              data: DashboardKpiData.fromDashboardData(data),
              period: _period,
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            CardWrapper(
              child: BusinessSummaryCard(
                periodLabel: _period.noun,
                items: _businessSummaryItems(data),
              ),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            CardWrapper(
              child: RevenueTrendChart(
                revenueTrend: _revenueTrend
                    .map((e) => RevenueTrendData(label: e.label, value: e.value))
                    .toList(),
                hasPrevTrend: _hasPrevTrend,
                hasNextTrend: _hasNextTrend,
                loading: _loadingTrend,
                prevCursor: _prevCursor,
                nextCursor: _nextCursor,
                onLoadTrend: ({String? cursor, bool isNext = false}) {
                  _loadTrend(cursor: cursor, isNext: isNext);
                },
                periodLabel: (_) => _period.noun,
              ),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            CardWrapper(
              child: RevenueContributionChart(
                title: 'Revenue Contribution',
                slices: data.firms
                    .map(
                      (f) => RevenueContributionSlice(
                        label: f.name,
                        value: f.revenue,
                      ),
                    )
                    .toList(),
                period: _period,
              ),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
          ],
        ),
      ),
    );
  }

  List<SummaryItem> _businessSummaryItems(DashboardData data) {
    final double totalRevenue = data.firms.fold(0.0, (s, f) => s + f.revenue);
    final double totalTransactions = data.firms.fold(
      0.0,
      (s, f) => s + f.transactions,
    );
    final FirmModel? topFirm = data.firms.isEmpty
        ? null
        : data.firms.reduce((a, b) => a.revenue > b.revenue ? a : b);
    final ServiceModel? topService = data.services.isEmpty
        ? null
        : data.services.reduce((a, b) => a.revenue > b.revenue ? a : b);

    return [
      SummaryItem(
        title: 'Total Revenue',
        value: CurrencyUtils.format(totalRevenue),
        icon: Icons.currency_rupee,
      ),
      SummaryItem(
        title: 'Total Transactions',
        value: totalTransactions.toStringAsFixed(0),
        icon: Icons.receipt_long,
      ),
      if (topFirm != null)
        SummaryItem(
          title: 'Top Firm',
          value: '${topFirm.name} (${CurrencyUtils.format(topFirm.revenue)})',
          icon: Icons.storefront,
        ),
      if (topService != null)
        SummaryItem(
          title: 'Top Service',
          value:
              '${topService.name} (${CurrencyUtils.format(topService.revenue)})',
          icon: Icons.design_services_outlined,
        ),
    ];
  }
}
