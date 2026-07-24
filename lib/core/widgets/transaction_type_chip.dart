import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class TransactionTypeChip extends StatelessWidget {
  final String type;

  const TransactionTypeChip({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = type.toLowerCase();

    final IconData icon = switch (normalized) {
      "service" => Icons.content_cut,
      "expense" => Icons.payments_outlined,
      _ => Icons.payment,
    };

    final Color color = switch (normalized) {
      "service" => AppColors.primary,
      "expense" => AppColors.secondary,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
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
