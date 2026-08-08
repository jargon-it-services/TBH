import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';

/// Centered label/value tile — a name (e.g. "Revenue"), a big value
/// beneath it, and an optional small caption under that (e.g. a
/// "vs last month" delta). Extracted from `BranchOverviewCard`'s
/// private `_Metric` so `TopPerformerCard`'s Revenue/Services/
/// Expenses/Profit/Commission grid can render with the exact same
/// look instead of a second near-identical private widget.
class ReportMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? caption;

  const ReportMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.h3.copyWith(fontSize: 17, color: valueColor),
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}
