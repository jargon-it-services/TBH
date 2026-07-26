import 'package:flutter/material.dart';

import '../../core/network/apis/dashboard_api.dart';
import '../../core/services/DataModels/dashboard_models.dart';
import '../../core/services/dashboard_date_formatter.dart';
import '../../core/services/dashboard_icon_mapper.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/business_summary_card.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/revenue_trend_chart.dart';
import 'dashboard_quick_actions.dart';
import 'widgets/dashboard_shared_widgets.dart';
import 'widgets/dashboard_transaction_tile.dart';

/// Single, fully data-driven dashboard body shared by Account Admin,
/// Branch Admin, Manager and Employee -- the four roles that now all
/// consume the same merged `/dashboard` response. Section visibility
/// is a straight null/empty check against [DashboardData]'s optional
/// fields (see `dashboard_models.dart`), never a per-role switch, per
/// "make the dashboard completely dynamic" / "avoid role-specific UI
/// logic where the API already controls visibility".
///
/// Owns only the revenue-trend cursor pagination locally (the same
/// separate `/dashboard/revenue-trend` endpoint as before, unrelated
/// to this merge); the merged fetch itself, and period selection, are
/// owned by `DashboardPage` since the sticky header needs that same
/// fetch (see `merged_dashboard_header.dart`).
class DashboardDynamicBody extends StatefulWidget {
  const DashboardDynamicBody({
    super.key,
    required this.data,
    required this.selectedPeriodKey,
    required this.onPeriodChanged,
    required this.onRefresh,
  });

  final DashboardData data;
  final String selectedPeriodKey;
  final ValueChanged<String> onPeriodChanged;
  final Future<void> Function() onRefresh;

  @override
  State<DashboardDynamicBody> createState() => _DashboardDynamicBodyState();
}

class _DashboardDynamicBodyState extends State<DashboardDynamicBody> {
  final DashboardApi _api = DashboardApi();

  late List<TrendPoint> _revenueTrend;
  late bool _hasPrevTrend;
  late bool _hasNextTrend;
  String? _prevCursor;
  String? _nextCursor;
  bool _loadingTrend = false;

  @override
  void initState() {
    super.initState();
    _resetTrendFrom(widget.data.overviewTrend);
  }

  @override
  void didUpdateWidget(covariant DashboardDynamicBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh merged fetch (new period, pull-to-refresh) always brings
    // its own first page of trend points -- reset to that rather than
    // keeping whatever page the user had paginated to before.
    if (!identical(oldWidget.data, widget.data)) {
      _resetTrendFrom(widget.data.overviewTrend);
    }
  }

  void _resetTrendFrom(OverviewTrend? trend) {
    _revenueTrend = trend?.points ?? [];
    _hasPrevTrend = trend?.prevCursor != null;
    _hasNextTrend = trend?.nextCursor != null;
    _prevCursor = trend?.prevCursor;
    _nextCursor = trend?.nextCursor;
  }

  Future<void> _loadTrend({String? cursor, required bool isNext}) async {
    if (_loadingTrend) return;
    setState(() => _loadingTrend = true);

    final result = await _api.fetchRevenueTrend(
      period: widget.selectedPeriodKey,
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

  List<QuickActionSpec> get _quickActions =>
      DashboardQuickActions.forRole(SessionManager.instance.role);

  String _selectedPeriodLabel(DashboardMeta meta) {
    for (final period in meta.periods) {
      if (period.key == widget.selectedPeriodKey) return period.label;
    }
    return widget.selectedPeriodKey;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final meta = data.meta;
    final currencySymbol = meta.currencySymbol;

    final alerts = data.importantAlerts;
    final quickInsights = data.quickInsights;
    final businessSummary = data.businessSummary;
    final overviewTrend = data.overviewTrend;
    final revenueContribution = data.revenueContribution;
    final recentTransactions = data.recentTransactions;
    final lastUpdatedLabel = DashboardDateFormatter.formatIso(
      data.lastUpdated,
      pattern: meta.dateFormat,
      timezone: meta.timezone,
    );

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (alerts != null && alerts.isNotEmpty) ...[
              importantAlertsSection(alerts),
              const SizedBox(height: AppSpacing.verticalSmall),
            ],
            if (_quickActions.isNotEmpty) ...[
              QuickActionsRow(actions: _quickActions),
              const SizedBox(height: AppSpacing.verticalMedium),
            ],
            if (meta.periods.isNotEmpty) ...[
              DashboardPeriodSelector(
                periods: meta.periods,
                selectedKey: widget.selectedPeriodKey,
                onChanged: widget.onPeriodChanged,
              ),
              const SizedBox(height: AppSpacing.verticalMedium),
            ],
            if (quickInsights != null) ...[
              QuickInsightsSection(
                insights: quickInsights,
                currencySymbol: currencySymbol,
              ),
              const SizedBox(height: AppSpacing.verticalLarge),
            ],
            if (businessSummary != null) ...[
              CardWrapper(
                child: BusinessSummaryCard(
                  periodLabel: _selectedPeriodLabel(meta),
                  items: businessSummary.items
                      .map(
                        (item) => SummaryItem(
                          title: item.title,
                          value: businessSummaryValueText(
                            item.value,
                            currencySymbol,
                          ),
                          icon: DashboardIconMapper.iconFromKey(item.icon),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.verticalLarge),
            ],
            if (overviewTrend != null) ...[
              CardWrapper(
                child: RevenueTrendChart(
                  revenueTrend: _revenueTrend
                      .map(
                        (e) => RevenueTrendData(label: e.label, value: e.value),
                      )
                      .toList(),
                  hasPrevTrend: _hasPrevTrend,
                  hasNextTrend: _hasNextTrend,
                  loading: _loadingTrend,
                  prevCursor: _prevCursor,
                  nextCursor: _nextCursor,
                  onLoadTrend: ({String? cursor, bool isNext = false}) {
                    _loadTrend(cursor: cursor, isNext: isNext);
                  },
                  periodLabel: (_) => _selectedPeriodLabel(meta),
                ),
              ),
              const SizedBox(height: AppSpacing.verticalLarge),
            ],
            if (revenueContribution != null) ...[
              CardWrapper(
                child: RevenueContributionChart(
                  contribution: revenueContribution,
                ),
              ),
              const SizedBox(height: AppSpacing.verticalLarge),
            ],
            if (recentTransactions != null) ...[
              CardWrapper(
                child: _RecentTransactionsCard(
                  transactions: recentTransactions,
                  currencySymbol: currencySymbol,
                  dateFormat: meta.dateFormat,
                  timezone: meta.timezone,
                ),
              ),
              const SizedBox(height: AppSpacing.verticalLarge),
            ],
            if (lastUpdatedLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Center(
                  child: Text(
                    'Last updated: $lastUpdatedLabel',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final RecentTransactions transactions;
  final String currencySymbol;
  final String dateFormat;
  final String timezone;

  const _RecentTransactionsCard({
    required this.transactions,
    required this.currencySymbol,
    required this.dateFormat,
    required this.timezone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.horizontalSmall),
            Text(transactions.title, style: AppTextStyles.h3),
          ],
        ),
        const SizedBox(height: AppSpacing.verticalSmall),
        ...List.generate(transactions.items.length, (index) {
          final item = transactions.items[index];
          return Column(
            children: [
              DashboardTransactionTile(
                transaction: item,
                currencySymbol: currencySymbol,
                dateFormat: dateFormat,
                timezone: timezone,
              ),
              if (index != transactions.items.length - 1)
                const Divider(height: 1, color: AppColors.divider),
            ],
          );
        }),
      ],
    );
  }
}
