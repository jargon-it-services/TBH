import 'package:flutter/material.dart';

import '../../../core/services/DataModels/employee_performance_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/InitialsAvatar.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';
import 'report_metric_tile.dart';

/// "Top Performer" card — the single highest-revenue employee for the
/// selected period/branch: photo, name, designation and branch, then
/// a Revenue / Services / Expenses / Profit / Commission grid using
/// the same [ReportMetricTile] the "All Branches Overview" card uses.
/// Photo fallback (initials avatar when no photo is uploaded) mirrors
/// `StaffListPage._photoAvatar()` exactly, so this card looks like it
/// belongs next to the rest of the Staff module, not like a one-off.
class TopPerformerCard extends StatelessWidget {
  final TopPerformer? performer;
  final String currencySymbol;

  const TopPerformerCard({
    super.key,
    required this.performer,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.horizontalSmall),
              const Expanded(child: Text('Top Performer', style: AppTextStyles.h3)),
              if (performer != null)
                const Icon(Icons.emoji_events, color: Color(0xFFF5A623), size: 26),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (performer == null)
            const SizedBox(
              width: double.infinity,
              child: AnimatedEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No Top Performer Yet',
                message:
                    'The highest-revenue employee for this period will appear here once data is available.',
                height: 160,
              ),
            )
          else
            _buildContent(performer!),
        ],
      ),
    );
  }

  Widget _buildContent(TopPerformer performer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _photoAvatar(performer),
            const SizedBox(width: AppSpacing.horizontalMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    performer.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                  ),
                  if (performer.designation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      performer.designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (performer.branchName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            performer.branchName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.verticalMedium),
        Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: AppSpacing.verticalMedium),
        Row(
          children: [
            Expanded(
              child: ReportMetricTile(
                label: 'Revenue',
                value: CurrencyUtils.format(performer.revenue, symbol: currencySymbol),
              ),
            ),
            Expanded(
              child: ReportMetricTile(
                label: 'Services',
                value: '${performer.servicesServed}',
              ),
            ),
            Expanded(
              child: ReportMetricTile(
                label: 'Expenses',
                value: CurrencyUtils.format(performer.expenses, symbol: currencySymbol),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.verticalMedium),
        Row(
          children: [
            Expanded(
              child: ReportMetricTile(
                label: 'Profit',
                value: CurrencyUtils.format(performer.profit, symbol: currencySymbol),
                valueColor: AppColors.success,
              ),
            ),
            Expanded(
              child: ReportMetricTile(
                label: 'Commission',
                value: CurrencyUtils.format(performer.commission, symbol: currencySymbol),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _photoAvatar(TopPerformer performer) {
    if (performer.hasPhoto) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        backgroundImage: NetworkImage(performer.photo!),
      );
    }
    return InitialsAvatar(name: performer.fullName, radius: 28);
  }
}
