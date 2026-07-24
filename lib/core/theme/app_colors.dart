import 'package:flutter/material.dart';

/// ==============================
/// APP COLORS
/// ==============================
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ------------------------------
  // BRAND COLORS
  // ------------------------------
  static const Color primary = Color(0xFF345995); // Steel Blue
  static const Color secondary = Color(0xFFE76425); // Burnt Orange

  // ------------------------------
  // BACKGROUND COLORS
  // ------------------------------
  static const Color foregroundBackground = Color(0xFFFFFEFE); // White
  static const Color pageBackground = Color(0xFFFFFEFE); // White
  static const Color cardBackground =
      Color(0xFFFFFFFF); // Card default background
  static const Color scaffoldBackground =
      Color(0xFFF5F5F5); // Light gray for scaffolds

  // ------------------------------
  // TEXT COLORS
  // ------------------------------
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ------------------------------
  // ICON COLORS
  // ------------------------------
  static const Color iconPrimary = Color(0xFF000000);
  static const Color iconSecondary = Color(0xFF9E9E9E);
  static const Color iconOnPrimary = Color(0xFFFFFFFF);

  // ------------------------------
  // BORDERS & DIVIDERS
  // ------------------------------
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color buttonSliderBackground = Color(0xFFEEEEEE);
  static const Color buttonText = Color(0xFFEEEEEE);

  // ------------------------------
  // TRANSACTION / FINANCE COLORS
  // ------------------------------
  static const Color income = Color(0xFF2E7D32); // Green
  static const Color expense = Color(0xFFC62828); // Red
  static const Color pending = Color(0xFFFFA000); // Amber

  // ------------------------------
  // SUCCESS / ERROR / WARNING / INFO (Optional, for UX feedback)
  // ------------------------------
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
}
