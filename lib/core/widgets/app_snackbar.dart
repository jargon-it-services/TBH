import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Message severity — drives the icon, color, and default duration used
/// by [AppSnackbar]. Kept as a public enum so callers can also branch on
/// it if a screen needs custom handling per type.
enum AppSnackbarType { success, error, warning, info }

/// Common helper for showing a transient status message.
///
/// Originally extracted from ForgotPasswordPage's `_showSnack` (plain
/// message, default Material [SnackBar] look). Extended here into a
/// small typed system so every flow gets the same success/error/warning/
/// info styling — icon, color, shape, duration — instead of each screen
/// hand-rolling its own `ScaffoldMessenger.of(context).showSnackBar(...)`.
///
/// [show] keeps its original signature and behavior (defaults to the
/// neutral `info` styling), so existing call sites don't need to change.
/// New code should prefer the named [success]/[error]/[warning]/[info]
/// helpers for clarity at the call site.
class AppSnackbar {
  const AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackbarType type = AppSnackbarType.info,
    Duration? duration,
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    final config = _configFor(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(config.icon, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.iconText),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.body.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: config.color,
          behavior: SnackBarBehavior.floating,
          duration: duration ?? config.duration,
          margin: const EdgeInsets.all(AppSpacing.page),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          action: action,
        ),
      );
  }

  /// Positive confirmation — e.g. "Registration submitted", "Payment
  /// successful".
  static void success(BuildContext context, String message,
          {Duration? duration, SnackBarAction? action}) =>
      show(context, message,
          type: AppSnackbarType.success, duration: duration, action: action);

  /// API failures, blocked actions — anything that stopped the user.
  static void error(BuildContext context, String message,
          {Duration? duration}) =>
      show(context, message, type: AppSnackbarType.error, duration: duration);

  /// Validation nudges, "you need to do X first" — didn't fail, but
  /// needs the user's attention before continuing.
  static void warning(BuildContext context, String message,
          {Duration? duration}) =>
      show(context, message, type: AppSnackbarType.warning, duration: duration);

  /// Neutral, non-blocking status updates.
  static void info(BuildContext context, String message,
          {Duration? duration}) =>
      show(context, message, type: AppSnackbarType.info, duration: duration);

  static _SnackConfig _configFor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return const _SnackConfig(
          color: AppColors.success,
          icon: Icons.check_circle_outline,
          duration: Duration(seconds: 3),
        );
      case AppSnackbarType.error:
        return const _SnackConfig(
          color: AppColors.error,
          icon: Icons.error_outline,
          duration: Duration(seconds: 4),
        );
      case AppSnackbarType.warning:
        return const _SnackConfig(
          color: Color(0xFFB27B00), // darker than AppColors.warning so
          // white icon/text stay readable — AppColors.warning (amber)
          // is too light for white-on-color contrast.
          icon: Icons.warning_amber_rounded,
          duration: Duration(seconds: 3),
        );
      case AppSnackbarType.info:
        return const _SnackConfig(
          color: AppColors.info,
          icon: Icons.info_outline,
          duration: Duration(seconds: 3),
        );
    }
  }
}

class _SnackConfig {
  final Color color;
  final IconData icon;
  final Duration duration;

  const _SnackConfig({
    required this.color,
    required this.icon,
    required this.duration,
  });
}
