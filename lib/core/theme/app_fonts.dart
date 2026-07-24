import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ==============================
/// FONT STYLES
/// ==============================
class AppTextStyles {
  AppTextStyles._(); // private constructor

  static const String fontFamily = 'Horizon';

  // ------------------------------
  // HEADINGS
  // ------------------------------
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // ------------------------------
  // BODY TEXT
  // ------------------------------
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  // ------------------------------
  // BUTTONS
  // ------------------------------
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
    color: AppColors.primary,
    letterSpacing: 0.5,
  );

  // ------------------------------
  // LABELS & PLACEHOLDERS
  // ------------------------------
  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelPlaceholder = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
    color: AppColors.textSecondary,
  );
}

/// ==============================
/// SPACING
/// ==============================
class AppSpacing {
  AppSpacing._();

  static const double page = 20.0;
  static const double iconText = 8.0;
  static const double verticalSmall = 8.0;
  static const double verticalMedium = 16.0;
  static const double verticalLarge = 24.0;
  static const double horizontalSmall = 8.0;
  static const double horizontalMedium = 16.0;

  // ratio-based spacing (for dynamic layouts)
  static const double inputGapRatio = 0.02; // relative to screen height
  static const double contentGapRatio = 0.03; // relative to screen height
}

/// ==============================
/// RADII / CORNERS
/// ==============================
class AppRadius {
  AppRadius._();

  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double circle = 50.0;
}

/// ==============================
/// ICONS
/// ==============================
class AppIcons {
  AppIcons._();

  static const double defaultSize = 24.0;
}

/// ==============================
/// BUTTONS
/// ==============================
class AppButtonStyles {
  AppButtonStyles._();

  static final ButtonStyle primary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.foregroundBackground,
    textStyle: AppTextStyles.button,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  );

  static final ButtonStyle secondary = ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.foregroundBackground,
    textStyle: AppTextStyles.button,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  );
}
