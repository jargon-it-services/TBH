import 'package:flutter/material.dart';

import '../../core/network/apis/app_version_api.dart';
import '../../core/services/app_store_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Full-screen, non-dismissible gate shown when
/// `currentBuild < minimumBuild` (see AppVersionService). Only an
/// Update button — no way to continue into the app, matching the
/// [MaintenancePage] gate for the same reasons (see its doc comment
/// for how this also satisfies "prevent API usage" without touching
/// the networking layer).
///
/// Requires the `url_launcher` package to open the store link. If this
/// project doesn't already depend on it, add it to pubspec.yaml.
class ForceUpdatePage extends StatelessWidget {
  final AppVersionResult result;

  const ForceUpdatePage({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // no way to continue into the app from here
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.system_update_alt_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.verticalMedium),
                  Text(
                    'Update Required',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: AppSpacing.verticalSmall),
                  Text(
                    result.message ??
                        'A new version of the app is required to continue.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.verticalLarge),
                  ElevatedButton.icon(
                    onPressed: () => AppStoreLauncher.open(result.storeUrl),
                    icon: const Icon(Icons.system_update_alt_rounded),
                    label: const Text('Update'),
                    style: AppButtonStyles.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
