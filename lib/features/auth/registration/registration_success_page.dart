import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/app_snackbar.dart';

/// Shown once, right after registration succeeds — the flow is:
///
///   Register -> Registration Success Screen -> Login
///
/// Deliberately does NOT establish a session or navigate to Dashboard.
/// The account may still be pending document verification, so handing
/// out a working session immediately would be wrong; funneling every
/// user through the same Login screen also means there's exactly one
/// code path in the app that creates a session (LoginPage), instead of
/// Registration needing its own copy of that logic too.
class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({super.key, this.businessId});

  /// The organization/business id returned by the registration API
  /// (`RegistrationResult.businessId`). Nullable and never hardcoded —
  /// if the backend doesn't return one, the Organization ID card is
  /// simply omitted rather than showing a broken/empty value.
  final String? businessId;

  @override
  Widget build(BuildContext context) {
    final hasBusinessId = businessId != null && businessId!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 44),
                ),
              ),
              const SizedBox(height: AppSpacing.verticalLarge),
              const Text(
                'Congratulations!',
                textAlign: TextAlign.center,
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: AppSpacing.verticalMedium),
              const Text(
                'Your registration has been completed successfully.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.verticalMedium),
              Text(
                'Our team is currently validating your uploaded documents. '
                'Your account will be fully activated once the verification '
                'process is complete.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.verticalMedium),
              Text(
                'Your free trial has already been activated, so you can log '
                'in and start using the application immediately.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (hasBusinessId) ...[
                const SizedBox(height: AppSpacing.verticalLarge),
                _OrganizationIdCard(businessId: businessId!),
              ],
              const SizedBox(height: AppSpacing.verticalLarge),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  onPressed: () {
                    // Clears the entire registration wizard's stack —
                    // Back must not be able to return into the
                    // now-completed multi-step form. Reuses the same
                    // named '/login' route Logout uses, so there's one
                    // consistent way to "land on Login with a clean
                    // stack" across the app.
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.verticalMedium),
              const Text(
                'Please log in using your credentials.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Highlighted card showing the Organization ID (business_id), with a
/// tap-to-copy affordance so the user can save it without retyping.
class _OrganizationIdCard extends StatelessWidget {
  const _OrganizationIdCard({required this.businessId});

  final String businessId;

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: businessId));
    if (!context.mounted) return;
    AppSnackbar.success(context, 'Organization ID copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.verticalMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Organization ID',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            onTap: () => _copyToClipboard(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      businessId,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.verticalSmall),
          Text(
            'This is your Organization ID (Account Code). Please save it '
            'carefully. You will need this Organization ID along with your '
            'login credentials to sign in to your account.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
