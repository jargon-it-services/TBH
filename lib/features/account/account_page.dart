import 'dart:ui';

import 'package:flutter/material.dart';
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
import '../../core/widgets/app_snackbar.dart';
import '../firms/firms_list_page.dart';
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
            ),
            const _AccountTile(icon: Icons.people_outline, title: "Staff"),
            const _AccountTile(
              icon: Icons.miscellaneous_services_outlined,
              title: "Services",
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
            const _AccountTile(
              icon: Icons.miscellaneous_services_outlined,
              title: "Services",
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
              // NOTE: deliberately NOT `const` — these read live data off
              // SessionManager.instance.currentSession. If they're const,
              // Flutter canonicalizes them to the same widget instance on
              // every build, and the framework's `identical()` fast-path
              // in Element.updateChild then skips rebuilding them
              // entirely on setState() (see _loadProfile), so a
              // completed profile fetch would never actually repaint
              // the screen until it was torn down and remounted.
              _ProfileHeaderCard(),
              const SizedBox(height: AppSpacing.verticalMedium),
              _StatsSection(),
              const SizedBox(height: AppSpacing.verticalMedium),
              _SubscriptionCard(),
              const SizedBox(height: AppSpacing.verticalLarge),
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

  const _AccountTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.onTap,
    this.featureId,
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
      trailing: isLocked
          ? Icon(Icons.lock_outline, size: 18, color: Colors.grey.shade600)
          : Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade600),
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

/// One row inside the expandable Report section.
class _ReportItem {
  final IconData icon;
  final String title;

  const _ReportItem(this.icon, this.title);
}

/// The "Report" menu entry, rendered as a single expandable card so the
/// whole group can be locked/unlocked together via
/// `isFeatureLocked('report')` — matching the lock pattern [_AccountTile]
/// already uses for individual tiles elsewhere on this page.
///
/// [isFullReportSet] switches between the 5-report list (Account Admin /
/// Branch Admin) and the Payslip-only list (Manager / Employee).
// class _ReportSectionCard extends StatefulWidget {
//   final bool isFullReportSet;

//   const _ReportSectionCard({required this.isFullReportSet});

//   @override
//   State<_ReportSectionCard> createState() => _ReportSectionCardState();
// }

// class _ReportSectionCardState extends State<_ReportSectionCard> {
//   bool _expanded = false;

//   static const _fullReports = [
//     _ReportItem(Icons.receipt_long_outlined, "Payslip"),
//     _ReportItem(Icons.subject_outlined, "PnL"),
//     _ReportItem(Icons.summarize_outlined, "Revenue & Expense Summary"),
//     _ReportItem(Icons.pie_chart_outline, "Payment Mode Breakdown Charts"),
//     _ReportItem(Icons.insights_outlined, "Employee Performance Report"),
//   ];

//   static const _payslipOnly = [
//     _ReportItem(Icons.receipt_long_outlined, "Payslip"),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final isLocked =
//         SessionManager.instance.currentSession?.isFeatureLocked('report') ??
//         false;
//     final reports = widget.isFullReportSet ? _fullReports : _payslipOnly;
//     final showChildren = _expanded && !isLocked;

//     return Card(
//       color: Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(AppRadius.medium),
//       ),
//       elevation: 1,
//       clipBehavior: Clip.antiAlias,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           InkWell(
//             onTap: isLocked
//                 ? () => AppSnackbar.warning(
//                     context,
//                     'Report isn\'t available on your current plan. '
//                     'Upgrade your plan to unlock it.',
//                   )
//                 : () => setState(() => _expanded = !_expanded),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: AppSpacing.page,
//                 vertical: AppSpacing.verticalSmall,
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.document_scanner_outlined,
//                     color: Colors.black87,
//                     size: AppIcons.defaultSize,
//                   ),
//                   const SizedBox(width: AppSpacing.horizontalSmall),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Report",
//                           style: AppTextStyles.body.copyWith(
//                             fontWeight: FontWeight.w600,
//                             color: AppColors.primary,
//                           ),
//                         ),
//                         if (isLocked)
//                           Text(
//                             'Not available on your plan',
//                             style: AppTextStyles.bodySmall.copyWith(
//                               color: AppColors.error,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                   Icon(
//                     isLocked
//                         ? Icons.lock_outline
//                         : (_expanded ? Icons.expand_less : Icons.expand_more),
//                     size: 18,
//                     color: Colors.grey.shade600,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           AnimatedCrossFade(
//             duration: const Duration(milliseconds: 200),
//             crossFadeState: showChildren
//                 ? CrossFadeState.showFirst
//                 : CrossFadeState.showSecond,
//             firstChild: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Divider(color: Colors.grey.shade200, height: 0.5),
//                 ...reports.map(
//                   (report) => ListTile(
//                     leading: Icon(
//                       report.icon,
//                       color: Colors.black87,
//                       size: AppIcons.defaultSize,
//                     ),
//                     title: Text(report.title, style: AppTextStyles.body),
//                     trailing: Icon(
//                       Icons.chevron_right,
//                       size: 18,
//                       color: Colors.grey.shade600,
//                     ),
//                     contentPadding: const EdgeInsets.only(
//                       left: AppSpacing.page + AppSpacing.horizontalMedium,
//                       right: AppSpacing.page,
//                     ),
//                     dense: true,
//                     onTap: () {},
//                   ),
//                 ),
//               ],
//             ),
//             secondChild: const SizedBox(width: double.infinity, height: 0),
//           ),
//         ],
//       ),
//     );
//   }
// }

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
              /// Avatar — falls back to the existing placeholder when
              /// profile_image is null.
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(
                    profileImage != null && profileImage.isNotEmpty
                        ? profileImage
                        : "https://i.pravatar.cc/300",
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.horizontalMedium),

              /// Name + Company + Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: AppTextStyles.body),
                    const SizedBox(height: 2),
                    Text(
                      accountName,
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
                        roleLabel,
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
          Row(
            children: [
              Expanded(
                child: _ProfileInfoTile(
                  icon: Icons.phone_outlined,
                  label: "Mobile",
                  value: mobile.isNotEmpty ? "+91 $mobile" : '',
                ),
              ),
              const SizedBox(width: AppSpacing.horizontalMedium),
              Expanded(
                child: _ProfileInfoTile(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: email,
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
    final management = SessionManager.instance.currentSession?.management;

    return Row(
      children: [
        _InteractiveStatCard(
          icon: Icons.business,
          value: "${management?.totalFirms ?? 0}",
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
          value: "${management?.totalStaff ?? 0}",
          label: "Staff",
          actionText: "Manage",
          onTap: () {},
        ),
        _InteractiveStatCard(
          icon: Icons.miscellaneous_services,
          value: "${management?.totalServices ?? 0}",
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

  @override
  Widget build(BuildContext context) {
    final plan = SessionManager.instance.currentSession?.recentPlan;
    final planName = plan?.name ?? '';
    final planStatus = _titleCase(plan?.status ?? '');
    final validUntilLabel = _formatValidUntil(
      plan?.validUntil,
      plan?.dateFormat,
    );

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
                  planName,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (validUntilLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Valid until: $validUntilLabel",
                    style: AppTextStyles.bodySmall,
                  ),
                ],
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
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.circle),
              ),
              child: Text(
                planStatus,
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
