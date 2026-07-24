import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class InsightsCard extends StatelessWidget {
  final String name;
  final String description;
  final String revenue;
  final String transactions;
  final String percent;
  final bool positive;
  final VoidCallback? onViewDetails;
  final bool showTrophy;
  final bool showViewDetailsButton;

  const InsightsCard({
    super.key,
    required this.name,
    required this.description,
    required this.revenue,
    required this.transactions,
    required this.percent,
    required this.positive,
    this.onViewDetails,
    this.showTrophy = false,
    this.showViewDetailsButton = true,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          /// 🏆 Background Trophy (optional)
          if (showTrophy)
            Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 110, // slightly bigger looks better in center
                  color: AppColors.secondary.withOpacity(0.07), // softer
                ),
              ),
            ),

          /// 🧩 Main Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.h3.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        positive ? Icons.trending_up : Icons.trending_down,
                        color: positive ? AppColors.income : AppColors.expense,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        percent,
                        style: TextStyle(
                          color:
                              positive ? AppColors.income : AppColors.expense,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.verticalSmall),

              /// Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statColumn("Revenue", revenue),
                  _statColumn("Transactions", transactions),
                ],
              ),

              // const SizedBox(height: AppSpacing.verticalSmall),

              /// View Details
              if (showViewDetailsButton)
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    onTap: onViewDetails,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "View details",
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          height: 25,
                          width: 25,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.secondary.withOpacity(0.09),
                          ),
                          child: const Icon(
                            Icons.navigate_next,
                            size: 25,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Column _statColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
