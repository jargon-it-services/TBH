import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

typedef SummaryRowTap = void Function();

class BusinessSummaryCard extends StatelessWidget {
  final List<SummaryItem> items;
  final String periodLabel;

  const BusinessSummaryCard({
    super.key,
    required this.items,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text("Business Summary", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "This summary is based on the current $periodLabel data",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          /// Generate summary rows dynamically
          ...items.map(
            (item) => _SummaryRowWidget(item: item),
          ),
        ],
      ),
    );
  }
}

/// ---------------- Summary Item ----------------
class SummaryItem {
  final String title;
  final String value;
  final IconData icon;
  final SummaryRowTap? onTap;

  SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });
}

/// ---------------- Summary Row Widget ----------------
class _SummaryRowWidget extends StatelessWidget {
  final SummaryItem item;

  const _SummaryRowWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(item.icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            item.title,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            item.value,
            textAlign: TextAlign.right,
            maxLines: 3,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (item.onTap != null) ...[
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textSecondary),
        ]
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: item.onTap != null
          ? InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: rowContent,
            )
          : rowContent,
    );
  }
}
