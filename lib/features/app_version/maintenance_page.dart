import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../splash/splash_page.dart';

/// Full-screen, non-dismissible gate shown when the backend reports
/// `maintenance: true` (see AppVersionService). There is no way out of
/// this screen except Retry — no back button, no bottom nav, nothing
/// else ever mounts while this is showing.
///
/// That last part is also how "prevent API usage while maintenance is
/// enabled" is satisfied without touching the networking layer: since
/// no other screen in the app ever gets the chance to build while this
/// one is on screen, nothing else gets the chance to make a request
/// either. The version-check call itself is the only network call made
/// before this gate is resolved.
class MaintenancePage extends StatelessWidget {
  final String? message;

  const MaintenancePage({super.key, this.message});

  void _retry(BuildContext context) {
    // Re-entering SplashPage re-runs its whole startup flow from
    // scratch — including a fresh version check — rather than
    // duplicating that check-and-navigate logic here.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SplashPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // no way back into the app from here
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
                    Icons.build_circle_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.verticalMedium),
                  Text(
                    'Under Maintenance',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: AppSpacing.verticalSmall),
                  Text(
                    message ??
                        "We're currently performing maintenance. Please check back shortly.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.verticalLarge),
                  ElevatedButton.icon(
                    onPressed: () => _retry(context),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
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
