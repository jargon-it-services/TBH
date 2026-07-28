import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Design tokens approved specifically for the Subscription screen.
///
/// [AppColors.primary] (`#345995`) and [AppColors.secondary] (`#E76425`)
/// already match the approved tokens exactly, so those are reused
/// as-is rather than duplicated here. The remaining approved tokens
/// (`ink`, `sub`, `surface`, `line`, `success`, `danger`) don't have
/// exact matches in the shared theme (e.g. `AppColors.success` is
/// `#4CAF50`, not the approved `#1E8E5A`) -- rather than change
/// `app_colors.dart` globally (out of scope, and would affect every
/// other screen using those tokens), they're kept scoped to this
/// feature only, here.
class SubscriptionTokens {
  SubscriptionTokens._();

  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.secondary;

  static const Color ink = Color(0xFF14213A);
  static const Color sub = Color(0xFF5B6478);
  static const Color surface = Color(0xFFF5F7FB);
  static const Color line = Color(0xFFE3E8F2);
  static const Color success = Color(0xFF1E8E5A);
  static const Color danger = Color(0xFFC0392B);

  static const Color warnBg = Color(0xFFFFF4E5);
  static const Color dangerBg = Color(0xFFFBE9E7);
  static const Color okBg = Color(0xFFE7F3EC);
  static const Color infoBg = Color(0xFFEAF0FB);
}
