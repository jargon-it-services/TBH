import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Shown when [ReportPageState.isStale] is true: the data on screen is
/// left over from the last successful load, and the most recent
/// background refresh failed for a non-connectivity reason. A
/// snackbar alone disappears after a few seconds -- this stays put
/// until the next successful load, so a screen someone glances back at
/// later doesn't quietly look current when it isn't.
///
/// Uses [AppColors.secondary] (the app's existing orange accent) as
/// the caution tone rather than introducing a new "warning" color —
/// there isn't one in [AppColors] today.
class ReportStaleBanner extends StatelessWidget {
  const ReportStaleBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.secondary.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Showing the last loaded data — couldn't refresh just now.",
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
