import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/DataModels/dashboard_models.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/services/dashboard_icon_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/alert_slider.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';
import '../../../core/widgets/no_internet_page.dart';
import '../../subscriptions/subscription_plans_page.dart';
import '../dashboard_quick_actions.dart';

/// =====================================================================
/// SHARED DASHBOARD-BODY BUILDING BLOCKS (merged-response roles)
/// =====================================================================
///
/// Used by the single, consolidated dynamic dashboard body
/// ([DashboardDynamicBody]) shared by Account Admin, Branch Admin,
/// Manager and Employee now that they all consume the same merged
/// `/dashboard` response. Every widget here is schema-driven off the
/// models in `dashboard_models.dart` (arbitrary item counts, no fixed
/// card slots) rather than the previous per-role, fixed-shape widgets
/// they replace.
///
/// [AlertSlider], [AnimatedEmptyState], [CardWrapper] and
/// [NoInternetPage] are reused as-is from `core/widgets`.

/// ---------------------------------------------------------------------
/// Quick Actions — role-wise, always a single horizontal row
/// ---------------------------------------------------------------------

/// Lays out [actions] evenly spaced and centered across the available
/// width whenever they fit — the professional, "app home screen" look
/// — and only falls back to a horizontally scrollable row if the tile
/// count genuinely doesn't fit (e.g. a future role with many actions,
/// or a narrow device). Still always a single row, per spec — it never
/// wraps to a grid.
///
/// Tapping a tile currently has an intentionally empty `onTap` — the
/// same "wire real navigation once each destination exists" precedent
/// used elsewhere in this dashboard (e.g. `DashboardAlertCard` before
/// its `action.screen` values had real destinations), since none of
/// these actions (Add Branch, View Payslip, Reports, ...) have a
/// corresponding screen/route in the app yet.
class QuickActionsRow extends StatelessWidget {
  final List<QuickActionSpec> actions;
  final ValueChanged<QuickActionSpec>? onActionTap;

  const QuickActionsRow({super.key, required this.actions, this.onActionTap});

  static const double _tileWidth = 76;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 92,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tiles = [
            for (final action in actions)
              _QuickActionTile(
                action: action,
                onTap: () => onActionTap?.call(action),
              ),
          ];

          // Minimum width needed to lay every tile out with at least
          // some breathing room between them.
          final minRequiredWidth =
              (actions.length * _tileWidth) + ((actions.length - 1) * 12);

          if (constraints.maxWidth >= minRequiredWidth) {
            // Everything fits: center the whole group and spread the
            // tiles evenly across the row instead of hugging the left
            // edge.
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: tiles,
            );
          }

          // Doesn't fit: scroll horizontally rather than compress or
          // wrap the tiles.
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tiles.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.horizontalMedium),
            itemBuilder: (context, index) => tiles[index],
          );
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final QuickActionSpec action;
  final VoidCallback onTap;

  const _QuickActionTile({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: QuickActionsRow._tileWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Icon(action.icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Period selector — driven entirely by `meta.periods[]`
/// ---------------------------------------------------------------------

class DashboardPeriodSelector extends StatelessWidget {
  final List<DashboardPeriodOption> periods;
  final String selectedKey;
  final ValueChanged<String> onChanged;

  const DashboardPeriodSelector({
    super.key,
    required this.periods,
    required this.selectedKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          for (final period in periods)
            Expanded(
              child: _PeriodTab(
                label: period.label,
                isActive: period.key == selectedKey,
                onTap: () {
                  if (period.key != selectedKey) onChanged(period.key);
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
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Quick Insights — schema-driven, arbitrary item count
/// ---------------------------------------------------------------------

/// Renders whatever `quick_insights.items[]` sends: any number of
/// tiles, each holding either a single [QuickInsightItem.value] (shown
/// as one big currency figure, same visual slot the old fixed
/// Revenue/Expenses/Profit cards used) or a [QuickInsightItem.values]
/// map (shown as several icon+count pairs side by side, same visual
/// slot the old Services+Customers card used) — never assuming which
/// shape a given item has, or how many items there are.
class QuickInsightsSection extends StatelessWidget {
  final QuickInsights insights;
  final String currencySymbol;

  const QuickInsightsSection({
    super.key,
    required this.insights,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = insights.items
        .map(
          (item) =>
              _QuickInsightTile(item: item, currencySymbol: currencySymbol),
        )
        .toList();

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(insights.title, style: AppTextStyles.h3),
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

class _QuickInsightTile extends StatelessWidget {
  final QuickInsightItem item;
  final String currencySymbol;

  const _QuickInsightTile({required this.item, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final icon = DashboardIconMapper.iconFromKey(item.icon);
    final values = item.values;

    final Widget figure;
    if (values != null && values.isNotEmpty) {
      // Several named sub-counts (e.g. services + customers) shown as
      // raw counts, not currency -- these are quantities, matching the
      // app's existing precedent for this exact shape.
      figure = Wrap(
        spacing: 20,
        runSpacing: 6,
        children: [
          for (final entry in values.entries)
            _InsightIconStat(
              icon: DashboardIconMapper.iconFromKey(entry.key),
              count: NumberFormat.decimalPattern().format(entry.value),
            ),
        ],
      );
    } else {
      figure = Text(
        CurrencyUtils.format(
          (item.value ?? 0).toDouble(),
          symbol: currencySymbol,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.h3.copyWith(fontSize: 16),
      );
    }

    return Container(
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
          figure,
          const SizedBox(height: 2),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InsightIconStat extends StatelessWidget {
  final IconData icon;
  final String count;

  const _InsightIconStat({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.secondary, size: 15),
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

/// ---------------------------------------------------------------------
/// Important Alerts
/// ---------------------------------------------------------------------

Color _alertBg(String type) {
  switch (type.toLowerCase()) {
    case 'error':
      return AppColors.error.withOpacity(0.08);
    case 'warning':
      return AppColors.warning.withOpacity(0.10);
    case 'success':
      return AppColors.success.withOpacity(0.08);
    case 'info':
    default:
      return AppColors.primary.withOpacity(0.08);
  }
}

Color _alertColor(String type) {
  switch (type.toLowerCase()) {
    case 'error':
      return AppColors.error;
    case 'warning':
      return AppColors.warning;
    case 'success':
      return AppColors.success;
    case 'info':
    default:
      return AppColors.primary;
  }
}

IconData _alertIcon(String type) {
  switch (type.toLowerCase()) {
    case 'error':
      return Icons.error_outline;
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'success':
      return Icons.check_circle_outline;
    case 'info':
    default:
      return Icons.info_outline;
  }
}

/// Renders one [DashboardAlertItem] exactly as the previous fixed alert
/// card design did, just fed from the wire model directly instead of a
/// hand-built view model.
///
/// Tapping the card (or its action button, if present) resolves
/// `alert.action.screen` and navigates accordingly -- currently just
/// `"subscription"`, which reuses the existing [SubscriptionPlansPage]
/// (and its existing Razorpay/payment flow) as-is via a plain
/// `Navigator.push`, the same direct-push pattern already used
/// elsewhere in this app (see `TransactionsPage` -> `TransactionDetailsPage`)
/// rather than a named route. Any other/unrecognized `screen` value is a
/// no-op for now -- same "wire real navigation once each destination
/// exists" precedent already used throughout this dashboard.
class DashboardAlertCard extends StatelessWidget {
  final DashboardAlertItem alert;

  const DashboardAlertCard({super.key, required this.alert});

  void _handleTap(BuildContext context) {
    switch (alert.action?.screen) {
      case 'subscription':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
        );
        break;
      default:
        // No destination wired up yet for this screen key -- no-op.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(alert.type);
    final action = alert.action;
    final hasAction = action?.screen != null && action!.screen!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasAction ? () => _handleTap(context) : null,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
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
                    Text(alert.description, style: AppTextStyles.bodySmall),
                    if (action != null && action.label.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: hasAction ? () => _handleTap(context) : null,
                        child: Text(action.label),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nothing to render when [alerts] is null/empty -- callers should
/// simply not mount this widget in that case (see
/// [DashboardDynamicBody]), same "hide the whole section, no gap" rule
/// every optional section follows.
Widget importantAlertsSection(List<DashboardAlertItem> alerts) {
  return AlertSlider<DashboardAlertItem>(
    alerts: alerts,
    itemBuilder: (_, alert) => DashboardAlertCard(alert: alert),
  );
}

/// ---------------------------------------------------------------------
/// Revenue Contribution
/// ---------------------------------------------------------------------

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

/// Pie-chart-plus-legend, fed directly by however many
/// `revenue_contribution.items[]` the API sends -- never assumes a
/// fixed count (e.g. always 5).
class RevenueContributionChart extends StatelessWidget {
  final RevenueContribution contribution;
  final String emptyTitle;
  final String emptyMessage;

  const RevenueContributionChart({
    super.key,
    required this.contribution,
    this.emptyTitle = 'No Revenue Split Available',
    this.emptyMessage =
        'Revenue contribution will appear once sales are recorded.',
  });

  double get _total => contribution.items.fold(0.0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    final slices = contribution.items;

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
            Text(contribution.title, style: AppTextStyles.h3),
          ],
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
/// Generic error view shared by the dynamic dashboard body (distinct
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
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
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

/// ---------------------------------------------------------------------
/// Business Summary value formatting
/// ---------------------------------------------------------------------

/// Numeric `value` -> formatted as currency; string `value` -> shown
/// exactly as received. No API flag needed -- the JSON type itself
/// (`num` vs `String`) tells us which.
String businessSummaryValueText(dynamic value, String currencySymbol) {
  if (value is num) {
    return CurrencyUtils.format(value.toDouble(), symbol: currencySymbol);
  }
  return value?.toString() ?? '';
}
