import 'package:flutter/material.dart';

import '../network/api_response.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Full-space "we couldn't load this" state — icon, title, message, and
/// a Retry button — for when a screen's data request fails.
///
/// Previously `FirmListPage` had its own private `_errorView()` doing
/// exactly this shape by hand, and `TransactionsPage` had no error UI
/// at all (a failed load there silently rendered as "no transactions",
/// indistinguishable from a genuinely empty result). This is that shape
/// made shared, so future data-fetching screens don't reimplement it —
/// and it's extended with the one thing neither screen had: it reads
/// [ApiResponse.isConnectivityError] (already produced by the network
/// layer, but never read anywhere before this) to automatically show
/// offline-specific copy/icon instead of a generic error when the
/// failure was specifically "no internet".
class NetworkStateView extends StatelessWidget {
  final bool isOffline;
  final String? message;
  final VoidCallback onRetry;

  const NetworkStateView({
    super.key,
    required this.onRetry,
    this.isOffline = false,
    this.message,
  });

  /// Builds directly from a failed [ApiResponse] — picks offline vs.
  /// generic error automatically, and uses the response's own error
  /// message unless [message] overrides it.
  factory NetworkStateView.fromResponse(
    ApiResponse<dynamic> response, {
    required VoidCallback onRetry,
    String? message,
  }) {
    return NetworkStateView(
      onRetry: onRetry,
      isOffline: response.isConnectivityError,
      message: message ?? response.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final icon = isOffline ? Icons.wifi_off_rounded : Icons.error_outline;
    final title = isOffline ? 'No Internet Connection' : 'Something went wrong';
    final body = message ??
        (isOffline
            ? 'Please check your internet connection and try again.'
            : "We couldn't load this right now. Please try again.");

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.verticalSmall),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text("Retry", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
