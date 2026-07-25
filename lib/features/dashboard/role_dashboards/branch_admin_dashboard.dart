import 'package:flutter/material.dart';

import '../../../core/connectivity/connectivity_aware_refresh.dart';
import '../../../core/network/apis/dashboard_api.dart';
import '../../../core/services/DataModels/dashboard_models.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/business_summary_card.dart';
import '../../../core/widgets/card_wrapper.dart';
import '../../../core/widgets/revenue_trend_chart.dart';
import '../../../core/widgets/shimmers/dashboard_shimmer.dart';
import 'account_admin_dashboard.dart'
    show
        DashboardAlertData,
        DashboardBodyErrorView,
        DashboardKpiData,
        DashboardPeriod,
        DashboardPeriodX,
        DashboardPeriodSelector,
        KpiSection,
        RevenueContributionChart,
        RevenueContributionSlice,
        importantAlertsSection;

/// Dashboard content shown to a [UserRole.branchAdmin] user.
///
/// Same widget set as [AccountAdminDashboard] — Important Alerts, Period
/// Selector, KPI section, Business Summary, Revenue Trend, Revenue
/// Contribution — reusing the shared building blocks defined alongside
/// it (see the note at the top of `account_admin_dashboard.dart`), but
/// scoped to the Branch Admin's single assigned branch rather than a
/// switchable org/branch: there's no in-body scope picker here, since
/// [DashboardStickyHeader] already shows the assigned branch as a static
/// label for this role. The Revenue Contribution split is therefore
/// shown by staff within the branch rather than by firm, since a single
/// branch has only one "firm" to show a split of.
class BranchAdminDashboard extends StatefulWidget {
  const BranchAdminDashboard({super.key});

  @override
  State<BranchAdminDashboard> createState() => _BranchAdminDashboardState();
}

class _BranchAdminDashboardState extends State<BranchAdminDashboard>
    with ConnectivityAwareRefresh<BranchAdminDashboard> {
  final DashboardApi _api = DashboardApi();

  bool _loading = true;
  String? _error;
  bool _isConnectivityError = false;
  DashboardData? _data;

  DashboardPeriod _period = DashboardPeriod.thisMonth;

  @override
  void initState() {
    super.initState();
    _load();
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
      setState(() {
        _data = result.data!.data;
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
            importantAlertsSection(const <DashboardAlertData>[]),
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
                revenueTrend: (data.overviewTrend?.points ?? [])
                    .map((e) => RevenueTrendData(label: e.label, value: e.value))
                    .toList(),
                onLoadTrend: ({String? cursor, bool isNext = false}) {},
                periodLabel: (_) => _period.noun,
              ),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            CardWrapper(
              child: RevenueContributionChart(
                title: 'Revenue Contribution by Staff',
                slices: data.staff
                    .map(
                      (s) => RevenueContributionSlice(
                        label: s.name,
                        value: s.revenue,
                      ),
                    )
                    .toList(),
                period: _period,
                emptyTitle: 'No Staff Contribution Yet',
                emptyMessage:
                    'Revenue by staff will appear once sales are recorded for this branch.',
              ),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
          ],
        ),
      ),
    );
  }

  List<SummaryItem> _businessSummaryItems(DashboardData data) {
    final double totalRevenue = data.staff.fold(0.0, (s, m) => s + m.revenue);
    final double totalTransactions = data.staff.fold(
      0.0,
      (s, m) => s + m.transactions,
    );
    final StaffModel? topStaff = data.staff.isEmpty
        ? null
        : data.staff.reduce((a, b) => a.revenue > b.revenue ? a : b);
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
      if (topStaff != null)
        SummaryItem(
          title: 'Top Performer',
          value:
              '${topStaff.name} (${CurrencyUtils.format(topStaff.revenue)})',
          icon: Icons.person_outline,
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
