import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_lables_messages.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/network/apis/logout_api.dart';
import '../../../core/network/apis/referral_api.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../firms/firms_list_page.dart';
import '../subscriptions/subscription_plans_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  Future<void> _handleSubscription() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
    );
  }

  /// Profile → Logout → Confirmation Dialog → Logout API → Delete JWT →
  /// Delete Refresh Token → Delete Session → Clear Authentication State
  /// → (onboarding_completed untouched) → Navigate Login → Clear Nav Stack.
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: const Text('Logout', style: AppTextStyles.h3),
        content: const Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Non-dismissible loading state while the (best-effort) server call
    // and local cleanup run — styled as a themed card (page background +
    // secondary-color spinner) instead of a bare platform-default dialog.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.verticalLarge),
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: const CircularProgressIndicator(color: AppColors.secondary),
        ),
      ),
    );

    // Best-effort server-side invalidation. Its result is intentionally
    // unused: a network failure or already-invalid token shouldn't trap
    // the user in a logged-in-looking state — local logout proceeds
    // below regardless of how this call resolves.
    await LogoutApi().logout();

    // Delete JWT + Delete Refresh Token + Delete Session + Clear
    // Authentication State — all one call, and it never touches
    // onboarding_completed (separate storage entirely).
    await SessionManager.instance.clearSession();

    // Deliberately NOT gated on `mounted`: AppNavigator.
    // goToLoginAndClearStack() drives the navigator via its own global
    // key (see AppNavigator), not this widget's BuildContext, so it
    // must still run even if AccountPage happens to unmount mid-flow.
    // Gating it on `mounted` would leave the non-dismissible loading
    // dialog opened above stuck on screen with no way to close it.
    //
    // Clears the ENTIRE navigation stack (including that dialog) and
    // lands on Login — Back can never return to an authenticated
    // screen from here. Reuses the same AppNavigator DioClient falls
    // back to on a forced logout, so there's exactly one implementation
    // of "go to Login and clear the stack" in the app.
    AppNavigator.goToLoginAndClearStack();
  }

  /// Invite Friend → Show loading → Call /referrals/invite-link → Open
  /// native share sheet with the backend-issued link. Flutter never
  /// generates the invite link itself — the backend owns invite
  /// generation entirely (see ReferralApi).
  Future<void> _handleInviteFriend() async {
    // Same themed, non-dismissible loading dialog used by Logout above
    // — reusing the existing loading UI rather than introducing a new
    // pattern.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.verticalLarge),
          decoration: BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          child: const CircularProgressIndicator(color: AppColors.secondary),
        ),
      ),
    );

    final response = await ReferralApi().getInviteLink();

    // Unlike Logout (which clears the whole nav stack on its way to
    // Login), this flow stays on AccountPage, so the loading dialog
    // needs to be dismissed explicitly.
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    if (!mounted) return;

    if (!response.isSuccess || response.data == null) {
      AppSnackbar.error(
        context,
        response.error ?? 'Could not generate invite link',
      );
      return;
    }

    final inviteUrl = response.data!.inviteUrl;
    final message =
        '🎉 Join The Beauty Hub!\n\n'
        'Manage your business using TBH.\n\n'
        'Create your account using my invitation.\n\n'
        '$inviteUrl';

    await SharePlus.instance.share(ShareParams(text: message));
  }

  Future<void> _showAppInfo() async {
    final info = await PackageInfo.fromPlatform();

    if (!mounted) return;

    showAboutDialog(
      context: context,
      applicationName: info.appName,
      applicationVersion: info.version,
      applicationIcon: Image.asset("assets/logo.png", width: 56, height: 56),
      children: [
        const SizedBox(height: 12),
        const Text(
          "The Beauty Hub, that enables multiple independent salon and beauty businesses to manage their operati(tenants/organisations)ons on a single shared platform with complete data isolation.",
          style: AppTextStyles.body,
        ),
      ],
    );
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.parse(url);

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  _openContactWebsite() => _launchExternal(AppConstantData.contact);

  _openTermsWebsite() => _launchExternal(AppConstantData.terms);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.large),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Profile",
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.verticalMedium,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ProfileHeaderCard(),
              const SizedBox(height: AppSpacing.verticalMedium),
              const _StatsSection(),
              const SizedBox(height: AppSpacing.verticalMedium),
              const _SubscriptionCard(),
              const SizedBox(height: AppSpacing.verticalLarge),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionCard(
                    title: "Firm Management",
                    items: [
                      _AccountTile(
                        icon: Icons.document_scanner_outlined,
                        title: "Report",
                      ),
                      _AccountTile(
                        icon: Icons.payment_outlined,
                        title: "Payment Slip",
                      ),
                      _AccountTile(icon: Icons.subject_outlined, title: "PnL"),
                      _AccountTile(
                        icon: Icons.add_comment_outlined,
                        title: "Incentive Config",
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.verticalMedium),
                  _SectionCard(
                    title: "Account Management",
                    items: [
                      const _AccountTile(
                        icon: Icons.admin_panel_settings_outlined,
                        title: "Account Info / Settings",
                      ),
                      const _AccountTile(
                        icon: Icons.credit_card_outlined,
                        title: "Payment History",
                      ),
                      _AccountTile(
                        icon: Icons.subject_outlined,
                        title: "Subscriptions",
                        onTap: _handleSubscription,
                      ),
                      const _AccountTile(
                        icon: Icons.delete_outline,
                        title: "Delete Account",
                        isDestructive: true,
                      ),
                      _AccountTile(
                        icon: Icons.logout,
                        title: "Logout",
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.verticalMedium),
                  _SectionCard(
                    title: "Support",
                    items: [
                      _AccountTile(
                        icon: Icons.contact_page,
                        title: "Contact",
                        onTap: _openContactWebsite,
                      ),
                      _AccountTile(
                        icon: Icons.policy,
                        title: "Terms & Policy",
                        onTap: _openTermsWebsite,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.verticalMedium),
                  _SectionCard(
                    title: "Others",
                    items: [
                      _AccountTile(
                        icon: Icons.share_outlined,
                        title: "Invite Friends",
                        onTap: _handleInviteFriend,
                      ),
                      _AccountTile(
                        icon: Icons.info_outline,
                        title: "App Info",
                        onTap: () => _showAppInfo(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SectionCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.page,
              vertical: AppSpacing.verticalSmall,
            ),
            child: Text(
              title,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 0.5),
          ...items,
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback? onTap;

  const _AccountTile({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : Colors.black87;

    return ListTile(
      leading: Icon(icon, color: color, size: AppIcons.defaultSize),
      title: Text(title, style: AppTextStyles.body.copyWith(color: color)),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: Colors.grey.shade600,
      ),
      onTap: onTap ?? () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      dense: true,
    );
  }
}

/* ---------------- Header ---------------- */
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          /// ---------- Top Row (Avatar + Name) ----------
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: const CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
                ),
              ),
              const SizedBox(width: AppSpacing.horizontalMedium),

              /// Name + Company + Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("John Anderson", style: AppTextStyles.body),
                    const SizedBox(height: 2),
                    Text(
                      "Acme Technologies Pvt. Ltd.",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.verticalSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.horizontalSmall,
                        vertical: AppSpacing.verticalSmall / 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.circle),
                      ),
                      child: Text(
                        "Administrator",
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Edit Button
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.circle),
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.verticalSmall / 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.password_outlined,
                    size: AppIcons.defaultSize - 6,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.verticalSmall),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: AppSpacing.verticalSmall),

          /// Info Grid
          const Row(
            children: [
              Expanded(
                child: _ProfileInfoTile(
                  icon: Icons.phone_outlined,
                  label: "Mobile",
                  value: "+91 8793052520",
                ),
              ),
              SizedBox(width: AppSpacing.horizontalMedium),
              Expanded(
                child: _ProfileInfoTile(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: "john@company.com",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalSmall,
        vertical: AppSpacing.verticalSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: AppIcons.defaultSize, color: AppColors.primary),
          const SizedBox(width: AppSpacing.horizontalSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- Stats ---------------- */
class _StatsSection extends StatelessWidget {
  const _StatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InteractiveStatCard(
          icon: Icons.business,
          value: "12",
          label: "Firms",
          actionText: "Manage",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FirmListPage()),
            );
          },
        ),
        _InteractiveStatCard(
          icon: Icons.people,
          value: "48",
          label: "Staff",
          actionText: "Manage",
          onTap: () {},
        ),
        _InteractiveStatCard(
          icon: Icons.miscellaneous_services,
          value: "25",
          label: "Services",
          actionText: "Manage",
          onTap: () {},
        ),
      ],
    );
  }
}

class _InteractiveStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String actionText;
  final VoidCallback onTap;

  const _InteractiveStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalSmall / 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.verticalMedium,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Label
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),

              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 64,
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                  Text(value, style: AppTextStyles.h1.copyWith(fontSize: 28)),
                ],
              ),
              const SizedBox(height: AppSpacing.verticalSmall),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: AppSpacing.verticalSmall),
              // Action
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    actionText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.indigo.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.indigo.shade500,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- Subscription ---------------- */
class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Active Subscription",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Premium Plan",
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Valid until: March 15, 2026",
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontalSmall,
              vertical: AppSpacing.verticalSmall / 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.circle),
            ),
            child: Text(
              "Active",
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
