import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Shown once, right after a successful Delete Account call — the flow
/// is:
///
///   Account -> Delete Account -> Confirm -> (API + session cleared) ->
///   Account Deleted Screen -> Login
///
/// Mirrors [RegistrationSuccessPage]'s design language (same circular
/// icon badge, heading/body/CTA layout, page background, and button
/// styling) so this reads as one more screen in the same app rather
/// than a new visual pattern. By the time this screen is shown, the
/// caller (AccountPage) has already cleared the local session — this
/// screen itself performs no session/API work, it only confirms the
/// outcome and hands off to Login.
class AccountDeletedPage extends StatelessWidget {
  const AccountDeletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The account is already deleted and the session already
      // cleared by the time this screen shows — there is no
      // authenticated screen left behind it to accidentally return to,
      // but disabling system back here keeps the only way forward
      // being the explicit "Continue" action below, matching how
      // RegistrationSuccessPage treats its own terminal screen.
      canPop: false,
      child: Scaffold(
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
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.verticalLarge),
                const Text(
                  'Account Deleted',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h1,
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
                Text(
                  'Your account has been deleted successfully.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
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
                      // Same "land on Login with a clean stack" call
                      // RegistrationSuccessPage and Logout both use —
                      // by this point the stack was already cleared
                      // down to this screen (see AccountPage), so this
                      // is belt-and-suspenders rather than strictly
                      // necessary, but keeps this screen self-contained
                      // if it's ever reached another way.
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/login', (route) => false);
                    },
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
