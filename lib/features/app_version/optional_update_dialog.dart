import 'package:flutter/material.dart';

import '../../core/app_version/app_version_service.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/apis/app_version_api.dart';
import '../../core/services/app_store_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// "A new version is available" dialog for [AppVersionCheckStatus.optionalUpdate]
/// — Update or Later, and either way the user keeps using the app.
/// Same [AlertDialog] shape/styling already established by the logout
/// confirmation in `account_page.dart` (rounded corners, h3 title, body
/// content, text-button actions) — no new dialog style introduced.
class OptionalUpdateDialog {
  OptionalUpdateDialog._();

  /// Shown from Splash via the global navigator context (see
  /// [AppNavigator]) rather than a screen's own [BuildContext] — by the
  /// time this fires, Splash has already navigated away to whichever
  /// screen the user actually lands on (Login, Home, or Introduction),
  /// so there's no single local context this could reliably use
  /// instead. Same reasoning [AppNavigator.goToLoginAndClearStack]
  /// already relies on for a forced logout.
  static Future<void> maybeShow(AppVersionResult result) async {
    final context = AppNavigator.key.currentContext;
    if (context == null) return;

    final wantsUpdate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: const Text('Update Available', style: AppTextStyles.h3),
        content: Text(
          result.message ??
              'A new version of the app is available. Update now for the latest features and fixes.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Later',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Update',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (wantsUpdate == true) {
      await AppStoreLauncher.open(result.storeUrl);
    }
  }
}
