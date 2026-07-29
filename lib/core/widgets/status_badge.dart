import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final Color color = switch (normalized) {
      "paid" => AppColors.success,
      "active" => AppColors.success,
      "success" => AppColors.success,
      "pending" => AppColors.warning,
      "cancelled" => AppColors.error,
      "failed" => AppColors.error,
      "refunded" => AppColors.primary,
      _ => AppColors.textSecondary,
    };

    final IconData icon = switch (normalized) {
      "paid" => Icons.check_circle,
      "success" => Icons.check_circle,
      "pending" => Icons.schedule,
      "cancelled" => Icons.cancel,
      "failed" => Icons.cancel,
      "refunded" => Icons.replay_circle_filled,
      _ => Icons.schedule,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
