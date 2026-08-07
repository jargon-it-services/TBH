import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Icon + color per payment mode `key`. Kept in one place so the bar
/// list, donut chart, and transaction-count tiles never drift out of
/// sync with each other. Falls back to a neutral look for any mode key
/// the app doesn't recognise yet, so an unexpected value from the API
/// degrades gracefully instead of crashing.
class PaymentModeStyle {
  final IconData icon;
  final Color color;

  const PaymentModeStyle({required this.icon, required this.color});

  static const Map<String, PaymentModeStyle> _styles = {
    'cash': PaymentModeStyle(icon: Icons.payments_outlined, color: AppColors.success),
    'upi': PaymentModeStyle(icon: Icons.qr_code_scanner_rounded, color: AppColors.primary),
    'card': PaymentModeStyle(icon: Icons.credit_card_rounded, color: AppColors.secondary),
  };

  static PaymentModeStyle of(String key) =>
      _styles[key] ??
      const PaymentModeStyle(icon: Icons.account_balance_wallet_outlined, color: AppColors.textSecondary);
}
