import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/constants/app_lables_messages.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/network/apis/logout_api.dart';
import '../../core/network/apis/profile_api.dart';
import '../../core/network/apis/referral_api.dart';
import '../../core/services/DataModels/login_response_model.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/InitialsAvatar.dart';
import '../../core/widgets/app_snackbar.dart';
import '../payments/payment_history_page.dart';
import '../subscriptions/subscription_plans_page.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

/// Builds the "code • branch" subtitle shown on the Account Info /
/// Settings tile from `account.code` and `account.branch_name`.
/// Returns null when neither is available, so the tile falls back to
/// having no subtitle rather than showing a stray separator.
String? _accountSubtitle(LoginAccountInfo? account) {
  if (account == null) return null;
  final parts = [
    account.code,
    account.branchName,
  ].where((part) => part.isNotEmpty);
  return parts.isEmpty ? null : parts.join(' • ');
}

class _AccountPageState extends State<AccountPage>
    with ConnectivityAwareRefresh<AccountPage> {
  final ProfileApi _profileApi = ProfileApi();

  /// True while a `/user/profile` fetch is in flight. Purely
  /// informational (e.g. could drive a subtle refresh indicator) —
  /// the screen never blocks on this, since it already has the
  /// login-time (or last successfully refreshed) session to show
  /// immediately.
  bool _isRefreshingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Future<void> onReconnected() => _loadProfile();

  /// Profile screen previously read the signed-in user's profile
  /// purely from the session snapshot captured at login. This fetches
  /// the latest `/user/profile` (see [ProfileApi] — same response
  /// shape as login's `data`, minus the token fields) and writes it
  /// back into [SessionManager], so this screen — and anything else
  /// reading `SessionManager.instance.currentSession` — reflects
  /// current server state instead of a stale login-time snapshot.
  ///
  /// Always runs silently: there's already valid session data to
  /// display while this is in flight, so a failure here (including no
  /// connectivity) just leaves the existing session/UI as-is rather
  /// than blanking the screen.
  Future<void> _loadProfile() async {
    if (_isRefreshingProfile) return;
    setState(() => _isRefreshingProfile = true);

    final response = await _profileApi.fetchProfile();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess && response.data != null) {
      final profile = response.data!;
      await SessionManager.instance.updateProfile(
        userInfo: profile.userInfo,
        account: profile.account,
        recentPlan: profile.recentPlan,
        management: profile.management,
        featureLock: profile.featureLock,
      );
      if (!mounted) return;
      setState(() => _isRefreshingProfile = false);
      return;
    }

    setState(() => _isRefreshingProfile = false);
    if (!response.isConnectivityError) {
      AppSnackbar.error(
        context,
        response.error ?? "Couldn't refresh your profile.",
      );
    }
  }

  Future<void> _handleSubscription() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
    );
  }

  Future<void> _handlePaymentHistory() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentHistoryPage()),
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

  /// Builds the menu section cards shown below the subscription card,
  /// scoped to the signed-in user's role (`SessionManager.instance.role`).
  ///
  /// Role → sections:
  /// - Account Admin: Report (full) · Account Setup · Account Management
  ///   (+ Subscription, Payment History, Delete Account) · Support · Logout
  /// - Branch Admin: Report (full) · Account Setup (Branch editable:
  ///   logo & address) · Account Management (Account Info, Update
  ///   Password only) · Support · Logout
  /// - Manager / Employee: Report (Payslip only) · Account Management
  ///   (Account Info, Update Password only) · Support · Logout
  ///
  /// "Report", "Account Setup", and "Account Management" are each
  /// wrapped in [_LockableSectionCard] with their own `featureId`
  /// ("report" / "account_setup" / "account_management") matched
  /// against the session's `feature_lock` list — see
  /// [UserSession.isFeatureLocked]. Locking is entirely data-driven:
  /// whenever the backend adds a new key to `feature_lock`, that
  /// section locks automatically the next time the profile/login
  /// response is read, with no new branching needed here. Wrapping any
  /// *other* future section the same way (just give it a `featureId`)
  /// makes it lockable too. "Account Setup" and the admin-only Account
  /// Management items are only included for the two admin roles.
  List<Widget> _buildRoleMenuSections(BuildContext context) {
    final roleLabel = SessionManager.instance.role.displayName;
    final isAccountAdmin = roleLabel == 'Account Admin';
    final isBranchAdmin = roleLabel == 'Branch Admin';
    final hasAccountSetup = isAccountAdmin || isBranchAdmin;
    const fullReports = [
      _AccountTile(icon: Icons.receipt_long_outlined, title: "Payslip"),
      _AccountTile(icon: Icons.subject_outlined, title: "PnL"),
      _AccountTile(
        icon: Icons.summarize_outlined,
        title: "Revenue & Expense Summary",
      ),

      _AccountTile(
        icon: Icons.pie_chart_outline,
        title: "Payment Mode Breakdown Charts",
      ),
      _AccountTile(
        icon: Icons.insights_outlined,
        title: "Employee Performance Report",
      ),
    ];
    const reportPayslipOnly = [
      _AccountTile(icon: Icons.receipt_long_outlined, title: "Payslip"),
    ];
    final reports = hasAccountSetup ? fullReports : reportPayslipOnly;

    return [
      // ---- Report (locked as one unit via featureId "report") ----
      _LockableSectionCard(
        featureId: 'report',
        title: "Report",
        items: reports,
      ),
      const SizedBox(height: AppSpacing.verticalMedium),

      // ---- Account Setup (Account Admin & Branch Admin only; locked
      // as one unit via featureId "account_setup") ----
      if (hasAccountSetup) ...[
        _LockableSectionCard(
          featureId: 'account_setup',
          title: "Account Setup",
          items: [
            _AccountTile(
              icon: Icons.storefront_outlined,
              title: "Branch",
              subtitle: isBranchAdmin ? "Allowed to edit logo & address" : null,
              count: SessionManager
                  .instance
                  .currentSession
                  ?.management
                  ?.totalFirms,
            ),
            _AccountTile(
              icon: Icons.people_outline,
              title: "Staff",
              count: SessionManager
                  .instance
                  .currentSession
                  ?.management
                  ?.totalStaff,
            ),
            _AccountTile(
              icon: Icons.miscellaneous_services_outlined,
              title: "Services",
              count: SessionManager
                  .instance
                  .currentSession
                  ?.management
                  ?.totalServices,
            ),
            const _AccountTile(
              icon: Icons.rule_folder_outlined,
              title: "Salary Rule",
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.verticalMedium),
      ],

      // ---- Account Management (locked as one unit via featureId
      // "account_management") ----
      _LockableSectionCard(
        featureId: 'account_management',
        title: "Account Management",
        items: [
          _AccountTile(
            icon: Icons.admin_panel_settings_outlined,
            title: "Account Info",
            subtitle: _accountSubtitle(
              SessionManager.instance.currentSession?.account,
            ),
          ),
          if (isAccountAdmin) ...[
            _AccountTile(
              icon: Icons.subject_outlined,
              title: "Subscription",
              onTap: _handleSubscription,
            ),
            _AccountTile(
              icon: Icons.credit_card_outlined,
              title: "Payment History",
              onTap: _handlePaymentHistory,
            ),
          ],
          if (!hasAccountSetup)
            _AccountTile(
              icon: Icons.miscellaneous_services_outlined,
              title: "Services",
              count: SessionManager
                  .instance
                  .currentSession
                  ?.management
                  ?.totalServices,
            ),
          const _AccountTile(
            icon: Icons.lock_reset_outlined,
            title: "Update Password",
          ),
          if (isAccountAdmin)
            const _AccountTile(
              icon: Icons.delete_outline,
              title: "Delete Account",
              isDestructive: true,
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.verticalMedium),

      // ---- Support ----
      _SectionCard(
        title: "Support",
        items: [
          _AccountTile(
            icon: Icons.contact_support_outlined,
            title: "Contact Us",
            onTap: _openContactWebsite,
          ),
          _AccountTile(
            icon: Icons.policy_outlined,
            title: "Terms & Conditions",
            onTap: _openTermsWebsite,
          ),
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
          const _AccountTile(icon: Icons.star_outline, title: "Rate Us"),
        ],
      ),
      const SizedBox(height: AppSpacing.verticalLarge),

      // ---- Logout (standalone terminal action, not tucked inside a
      // section) ----
      _LogoutTile(onTap: _handleLogout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isAccountAdmin =
        SessionManager.instance.role.displayName == 'Account Admin';
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        toolbarHeight: 110,
        backgroundColor: AppColors.primary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.large),
          ),
        ),
        centerTitle: true,
        title: _ProfileHeaderCard(),
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
              // Plan card is only relevant to the Account Admin, who
              // owns billing/subscription for the account — Branch
              // Admin, Manager, and Employee never see it.
              if (isAccountAdmin) ...[
                _PlanCard(),
                const SizedBox(height: AppSpacing.verticalLarge),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildRoleMenuSections(context),
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

/// Wraps an entire menu section so it can be locked/unlocked as one
/// unit, keyed by [featureId] against the session's `feature_lock`
/// list — see [UserSession.isFeatureLocked]. This is the section-level
/// counterpart to [_AccountTile.featureId] (which locks a single row);
/// use this one when the whole section (Report, Account Setup, Account
/// Management, or any future one) should lock/unlock together.
///
/// Purely data-driven: passing a new [featureId] here is the only step
/// needed to make another section lockable — no per-feature branching
/// lives in [_AccountPageState] itself, so a backend adding a new
/// `feature_lock` key (e.g. `"account_setup"`) starts locking that
/// section immediately, without any app changes.
class _LockableSectionCard extends StatelessWidget {
  final String featureId;
  final String title;
  final List<Widget> items;

  const _LockableSectionCard({
    required this.featureId,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked =
        SessionManager.instance.currentSession?.isFeatureLocked(featureId) ??
        false;

    // The heading (title + divider, rendered by _SectionCard) always
    // stays visible and unlocked — only the menu items themselves swap
    // for the frosted "locked" placeholder. This intentionally does
    // NOT blur/hide the whole card (title included) the way the old
    // report-only implementation did.
    return _SectionCard(
      title: title,
      items: isLocked ? [_LockedSectionItems(sectionTitle: title)] : items,
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;

  /// Identifier matched against the login session's `feature_lock`
  /// list (e.g. `"report"`, `"payment_slip"`, `"pnl"`). When present
  /// and locked, this tile stays visible with its existing styling,
  /// shows a lock icon instead of the chevron, and tapping it explains
  /// why instead of navigating — see [build]. Tiles that don't
  /// represent a lockable feature simply leave this null. New
  /// lockable identifiers work automatically — no per-feature
  /// branching needed here.
  final String? featureId;

  /// Optional count badge (e.g. `management.total_firms`) shown just
  /// before the trailing chevron/lock icon. Null/omitted for tiles
  /// that don't represent a countable resource.
  final int? count;

  const _AccountTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.onTap,
    this.featureId,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : Colors.black87;
    final isLocked =
        featureId != null &&
        (SessionManager.instance.currentSession?.isFeatureLocked(featureId!) ??
            false);

    // Locked tiles get their own explanatory subtitle (overriding
    // whatever [subtitle] was passed — none of the lockable tiles set
    // one today) so the "not on your plan" reason is visible without
    // needing to tap first.
    final effectiveSubtitle = isLocked
        ? 'Not available on your plan'
        : subtitle;

    return ListTile(
      leading: Icon(icon, color: color, size: AppIcons.defaultSize),
      title: Text(title, style: AppTextStyles.body.copyWith(color: color)),
      subtitle: effectiveSubtitle != null && effectiveSubtitle.isNotEmpty
          ? Text(
              effectiveSubtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: isLocked ? AppColors.error : Colors.grey.shade600,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isLocked && count != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.horizontalSmall,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(AppRadius.circle),
              ),
              child: Text(
                "$count",
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          isLocked
              ? Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade600)
              : Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
        ],
      ),
      // Locked tiles stay tappable — tapping doesn't navigate, it tells
      // the user why (and to upgrade) instead of just doing nothing.
      onTap: isLocked
          ? () => AppSnackbar.warning(
              context,
              '$title isn\'t available on your current plan. '
              'Upgrade your plan to unlock it.',
            )
          : (onTap ?? () {}),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      dense: true,
    );
  }
}

/// Blurred/frosted "these items are locked" placeholder, shown as the
/// sole item inside a [_SectionCard] by [_LockableSectionCard] when its
/// `featureId` is present in the session's `feature_lock` list.
///
/// Unlike the earlier implementation, this does NOT blur or hide the
/// section's heading — [_SectionCard] renders the real title + divider
/// above this widget exactly as it would for an unlocked section; only
/// the menu items themselves (this widget) get the frosted/blurred
/// lock treatment. Not tied to any one section — [sectionTitle] only
/// drives the default explanatory message, so the same widget serves
/// Report, Account Setup, Account Management, or any future lockable
/// section.
class _LockedSectionItems extends StatelessWidget {
  /// Title of the section being locked (e.g. "Report", "Account
  /// Setup") — used only to build the default [message] when one
  /// isn't supplied; never rendered directly by this widget.
  final String sectionTitle;

  /// Explanatory copy shown under "Feature Locked". Defaults to a
  /// generic upgrade message built from [sectionTitle] when omitted.
  final String? message;

  const _LockedSectionItems({required this.sectionTitle, this.message});

  @override
  Widget build(BuildContext context) {
    final effectiveMessage =
        message ??
        'This feature is locked.\n'
            'Upgrade your plan to access ${sectionTitle.toLowerCase()}.';

    return ClipRRect(
      // Only the bottom corners need rounding — the top of this widget
      // butts up against _SectionCard's (unlocked, unblurred) title
      // and divider, and the outer Card already clips its own corners.
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.medium),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          //--------------------------------------------------
          // Blurred stand-in rows, just so there's *something*
          // underneath the frosted glass to blur (an empty area
          // blurred looks identical to no blur at all).
          //--------------------------------------------------
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Opacity(
                opacity: .9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (_) => ListTile(
                      leading: Icon(
                        Icons.circle,
                        size: AppIcons.defaultSize,
                        color: Colors.grey.shade400,
                      ),
                      title: Container(
                        height: 12,
                        width: 120,
                        color: Colors.grey.shade300,
                      ),
                      dense: true,
                    ),
                  ),
                ),
              ),
            ),
          ),

          //--------------------------------------------------
          // Frosted Glass
          //--------------------------------------------------
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(.72)),
          ),

          //--------------------------------------------------
          // Lock UI
          //--------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: AppSpacing.verticalMedium,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //------------------------------------------
                // Glass Lock Circle
                //------------------------------------------
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(.55),
                        Colors.white.withOpacity(.18),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(.65),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.black,
                    size: AppIcons.defaultSize - 6,
                  ),
                ),

                const SizedBox(height: AppSpacing.verticalSmall),

                Text(
                  "Feature Locked",
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: AppSpacing.verticalSmall / 2),

                Text(
                  effectiveMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Standalone Logout action, kept separate from "Account Management" so
/// it reads as the terminal action of the menu (per the role/menu spec)
/// rather than one more settings row.
class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        side: BorderSide(color: AppColors.error.withOpacity(0.25)),
      ),
      elevation: 0,
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppColors.error),
        title: Text(
          "Logout",
          style: AppTextStyles.body.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 18,
          color: AppColors.error.withOpacity(0.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.page,
          vertical: AppSpacing.verticalSmall / 2,
        ),
        onTap: onTap,
      ),
    );
  }
}

/* ---------------- Header ---------------- */
/* ---------------- Header ---------------- */
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionManager.instance.currentSession;
    final userInfo = session?.userInfo;
    final profileImage = userInfo?.profileImage;
    final displayName = userInfo?.userName.isNotEmpty == true
        ? userInfo!.userName
        : (session?.userName ?? '');
    final accountName = session?.account?.name ?? '';
    // Role badge stays driven by SessionManager.role (backed by
    // user_info.role) rather than the raw string, so it gets the same
    // human-readable label ("Account Admin") the rest of the app uses.
    final roleLabel = SessionManager.instance.role.displayName;
    final mobile = userInfo?.mobile ?? '';
    final email = userInfo?.email ?? '';
    final accountCode = session?.account?.code ?? '';
    return Material(
      color: AppColors.primary,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.large),
        ),
      ),
      child: SafeArea(
        bottom: false,
        // Cap system font scaling inside the header only. This is a
        // fixed-height piece of chrome (see `toolbarHeight` on the
        // AppBar); an unclamped scale factor (large accessibility/
        // system font settings) is the main way the content could end
        // up taller than the slot Scaffold hands a custom `appBar`.
        // Content still grows with scale up to 1.25x — it just can't
        // run away the way an unclamped 1.5x-2x setting could.
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(minScaleFactor: 0.8, maxScaleFactor: 1.25),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: profileImage != null && profileImage.isNotEmpty
                        ? Image.network(
                            profileImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.white24,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          )
                        : InitialsAvatar(name: displayName),
                  ),
                ),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.h3.copyWith(color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (roleLabel.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.verticalSmall),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.horizontalSmall,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(
                              AppRadius.circle,
                            ),
                          ),
                          child: Text(
                            roleLabel,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.horizontalSmall),
                _InfoButton(
                  mobile: mobile,
                  email: email,
                  accountCode: accountCode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Info icon button — opens the contact-details bottom sheet.
class _InfoButton extends StatelessWidget {
  final String mobile;
  final String email;
  final String accountCode;

  const _InfoButton({
    required this.mobile,
    required this.email,
    required this.accountCode,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _ContactSheet(
          mobile: mobile,
          email: email,
          accountCode: accountCode,
        ),
      ),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
      ),
    );
  }
}

/// Bottom sheet: Mobile / Email / Account Code, each with a
/// copy-to-clipboard action.
class _ContactSheet extends StatelessWidget {
  final String mobile;
  final String email;
  final String accountCode;

  const _ContactSheet({
    required this.mobile,
    required this.email,
    required this.accountCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppRadius.circle),
              ),
            ),
          ),
          Text(
            "Contact Details",
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.verticalSmall),
          _ContactRow(
            icon: Icons.call_outlined,
            label: 'Mobile',
            value: mobile.isNotEmpty ? "+91 $mobile" : '—',
          ),
          _ContactRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email.isNotEmpty ? email : '—',
          ),
          _ContactRow(
            icon: Icons.badge_outlined,
            label: 'Account Code',
            value: accountCode.isNotEmpty ? accountCode : '—',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showDivider
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.horizontalSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Only offer copy for values that actually exist.
          if (value != '—')
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.copy_outlined, size: 16, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}

/* ---------------- Plan ----------------
 * Adapted from the shared ProfileScreen's _PlanCard, styled with the
 * same primary gradient as the header (rather than the shared
 * design's dark ink tile) so the two feel like one continuous surface.
 * `daysRemaining` is computed from `recentPlan.validUntil` (no
 * activation/start date exists on the session model today — see note
 * below).
 */
class _PlanCard extends StatelessWidget {
  const _PlanCard({super.key});

  /// Formats [validUntil] (an ISO date from `recent_plan.valid_until`)
  /// using [pattern] (`recent_plan.date_format`, e.g. `"dd MMM yyyy"`)
  /// rather than any hardcoded pattern. Falls back to the raw value if
  /// either is missing/unparsable, instead of throwing.
  static String _formatValidUntil(String? validUntil, String? pattern) {
    if (validUntil == null || validUntil.isEmpty) return '';
    final parsed = DateTime.tryParse(validUntil);
    if (parsed == null) return validUntil;
    if (pattern == null || pattern.isEmpty) return validUntil;
    try {
      return DateFormat(pattern).format(parsed);
    } catch (_) {
      return validUntil;
    }
  }

  /// `recent_plan.status` comes from the API as a lowercase key (e.g.
  /// `"active"`); this only adjusts capitalization for display, it
  /// doesn't hardcode any particular status value.
  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  /// Whole-days between today and [validUntil] (negative once expired).
  /// Null when `validUntil` is missing/unparsable.
  static int? _daysRemaining(String? validUntil) {
    final parsed = DateTime.tryParse(validUntil ?? '');
    if (parsed == null) return null;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final untilDateOnly = DateTime(parsed.year, parsed.month, parsed.day);
    return untilDateOnly.difference(todayDateOnly).inDays;
  }

  /// "Renews in N days" / "Renews today" / "Plan expired", driven purely
  /// by [daysRemaining] — there's no activation date on the session
  /// model to compute this from more precisely.
  static String _renewsInText(int? daysRemaining) {
    if (daysRemaining == null) return '';
    if (daysRemaining < 0) return 'Plan expired';
    if (daysRemaining == 0) return 'Renews today';
    return 'Renews in $daysRemaining day${daysRemaining == 1 ? '' : 's'}';
  }

  /// Progress bar fill (0.0–1.0). With no plan start date available,
  /// this approximates elapsed time against a standard 365-day cycle
  /// from [daysRemaining] alone — a visual cue, not an exact fraction.
  static double _progress(int? daysRemaining) {
    if (daysRemaining == null) return 0.0;
    final clampedRemaining = daysRemaining.clamp(0, 365);
    return (1 - (clampedRemaining / 365)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final plan = SessionManager.instance.currentSession?.recentPlan;
    final planName = plan?.name ?? '';
    final planStatus = _titleCase(plan?.status ?? '');
    final validUntilLabel = _formatValidUntil(
      plan?.validUntil,
      plan?.dateFormat,
    );
    final daysRemaining = _daysRemaining(plan?.validUntil);
    final renewsInText = _renewsInText(daysRemaining);
    final progress = _progress(daysRemaining);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Stack(
        children: [
          Container(
            color: AppColors.secondary.withOpacity(0.20),
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subscription',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            planName,
                            style: AppTextStyles.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (planStatus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.horizontalSmall,
                          vertical: AppSpacing.verticalSmall / 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(AppRadius.circle),
                        ),
                        child: Text(
                          planStatus,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.circle),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(AppColors.secondary),
                  ),
                ),
                const SizedBox(height: AppSpacing.verticalSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (renewsInText.isNotEmpty)
                      Text(renewsInText, style: AppTextStyles.caption),
                    if (validUntilLabel.isNotEmpty)
                      Text(validUntilLabel, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          // Decorative soft circle, matches the coral accent in the
          // shared design.
          Positioned(
            right: -20,
            top: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
