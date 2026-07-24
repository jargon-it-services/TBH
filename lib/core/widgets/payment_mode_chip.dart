import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class PaymentModeChip extends StatelessWidget {
  final String mode;

  const PaymentModeChip({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = mode.toLowerCase();

    final IconData icon = switch (normalized) {
      "upi" => Icons.qr_code_2,
      "card" => Icons.credit_card,
      "cash" => Icons.payments,
      _ => Icons.payment,
    };

    final Color color = switch (normalized) {
      "upi" => AppColors.primary,
      "card" => AppColors.secondary,
      "cash" => AppColors.success,
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
            mode.toUpperCase(),
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
