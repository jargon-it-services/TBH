import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Reusable "No Internet Connection" state for any screen whose content
/// is entirely network-dependent — i.e. there's nothing useful to show
/// without a successful fetch, so this replaces the whole body rather
/// than sitting alongside stale/partial content.
///
/// The caller owns what "retry" means (typically just re-running its own
/// fetch method) — this widget is purely presentational.
class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            const Text('No Internet Connection', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.verticalSmall),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label:
                  const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
