// ============================================================================
// sticky_org_header.dart
//
// A reusable, fully-dynamic "sticky header" widget for a multi-branch org app.
//
// Shows:
//   - Org logo / avatar
//   - Org name
//   - Role + account code (e.g. "Org Admin · TBH2024")
//   - Notification bell with live badge count
//   - Profile avatar (initials or image) that opens a menu/profile screen
//   - Branch switcher pill (e.g. "All Branches (4)") that:
//       * Opens a bottom sheet to pick a branch / "All Branches" WHEN the
//         org has more than 1 branch.
//       * Is rendered as a plain, non-interactive label (no dropdown arrow,
//         no tap ripple) WHEN the org has 0 or 1 branch.
//
// FUTURE-PROOF / API INTEGRATION NOTES
// -------------------------------------------------------------------------
// This widget takes NO hardcoded data. Everything comes from the
// constructor / a callback. It's wired to the real dashboard-header API
// by [DashboardStickyHeader] (features/dashboard/widgets), which:
//
//   1. Fetches the role-scoped data via `DashboardHeaderApi` and maps
//      it to `BranchModel`s (Organizations for Super Admin, Branches
//      for Account Admin, or a single assigned Branch otherwise).
//   2. Passes the currently selected branch via `selectedBranch`.
//   3. Listens to `onBranchChanged` to update local selection state
//      (wiring that into a branch-scoped dashboard body reload is
//      follow-up work — out of scope for the header itself).
//   4. Passes the live notification count straight from that response.
//
// `BranchModel` / `AllBranches` live in
// core/services/DataModels/dashboard_header_model.dart (the project's
// model layer) rather than in this widget file, following the existing
// convention (e.g. FirmModel lives in DataModels, not in FirmListPage).
//
// Because the widget is stateless and driven entirely by props + callbacks,
// it works with ANY state management approach without modification.
// ============================================================================

import 'package:flutter/material.dart';

import '../services/DataModels/dashboard_header_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class StickyOrgHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Organization / chain name, e.g. "Beauty Hub Chain".
  final String orgName;

  /// Optional small logo/avatar shown to the left of the org name.
  /// If null, a placeholder icon avatar is used instead.
  final ImageProvider? orgLogo;

  /// e.g. "Org Admin"
  final String roleLabel;

  /// e.g. "TBH2024"
  final String accountCode;

  /// Full list of branches available to the current user.
  /// - length == 0 or 1  -> branch switcher becomes a static, non-tappable
  ///   label (nothing to switch to).
  /// - length  > 1        -> branch switcher becomes tappable and opens a
  ///   picker (bottom sheet) including an "All Branches" option.
  final List<BranchModel> branches;

  /// Currently selected branch. Use `const AllBranches()` to represent the
  /// "All Branches (N)" state shown in the design.
  final BranchModel selectedBranch;

  /// Fired whenever the user picks a different branch (or "All Branches").
  /// Hook your API refresh logic here.
  final ValueChanged<BranchModel>? onBranchChanged;

  /// Unread notification count. 0 or null hides the badge.
  final int notificationCount;

  final VoidCallback? onNotificationTap;

  /// Profile avatar: initials fallback if `profileImage` not provided.
  final String profileInitials;
  final ImageProvider? profileImage;
  final VoidCallback? onProfileTap;

  final Color backgroundColor;
  final Color foregroundColor;
  final Color accentColor;

  /// Label prefix used for the "All ..." aggregate state, e.g. "All Branches"
  /// or "All Organizations" for a super-admin org switcher. The count is
  /// appended automatically: "All Organizations (128)".
  final String allEntitiesLabel;

  /// Title shown at the top of the picker bottom sheet, e.g. "Switch Branch"
  /// or "Switch Organization".
  final String switchSheetTitle;

  /// Icon shown at the start of the switcher pill.
  final IconData switcherIcon;

  const StickyOrgHeader({
    super.key,
    required this.orgName,
    required this.roleLabel,
    required this.accountCode,
    required this.branches,
    required this.selectedBranch,
    this.onBranchChanged,
    this.orgLogo,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.profileInitials = '',
    this.profileImage,
    this.onProfileTap,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.accentColor = AppColors.secondary,
    this.allEntitiesLabel = 'All Branches',
    this.switchSheetTitle = 'Switch Branch',
    this.switcherIcon = Icons.grid_view_rounded,
  });

  bool get _canSwitchBranch => branches.length > 1;

  String get _branchLabel {
    if (selectedBranch is AllBranches) {
      return '$allEntitiesLabel (${branches.length})';
    }
    return selectedBranch.name;
  }

  void _openBranchPicker(BuildContext context) {
    if (!_canSwitchBranch) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  switchSheetTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _branchTile(
                      context,
                      const AllBranches(),
                      '$allEntitiesLabel (${branches.length})',
                    ),
                    for (final branch in branches)
                      _branchTile(context, branch, branch.name),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _branchTile(BuildContext context, BranchModel branch, String label) {
    final bool isSelected = branch == selectedBranch;
    return ListTile(
      leading: Icon(
        Icons.storefront_outlined,
        color: isSelected ? accentColor : Colors.grey.shade500,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? accentColor : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: accentColor)
          : null,
      onTap: () {
        Navigator.of(context).pop();
        onBranchChanged?.call(branch);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.large),
        ),
      ),
      child: SafeArea(
        bottom: false,
        // Cap system font scaling inside the header only. This is a
        // fixed-height piece of chrome (see `preferredSize` below); an
        // unclamped scale factor (large accessibility/system font
        // settings) is the main way the content could end up taller
        // than the slot Scaffold hands a custom `appBar`. Content still
        // grows with scale up to 1.2x — it just can't run away the way
        // an unclamped 1.5x-2x setting could.
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _OrgLogo(image: orgLogo, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orgName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foregroundColor,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$roleLabel · $accountCode',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foregroundColor.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _NotificationBell(
                      count: notificationCount,
                      color: foregroundColor,
                      badgeColor: accentColor,
                      onTap: onNotificationTap,
                    ),
                    const SizedBox(width: 10),
                    _ProfileAvatar(
                      initials: profileInitials,
                      image: profileImage,
                      accentColor: accentColor,
                      onTap: onProfileTap,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _BranchSwitcherPill(
                  label: _branchLabel,
                  interactive: _canSwitchBranch,
                  foregroundColor: foregroundColor,
                  icon: switcherIcon,
                  onTap: () => _openBranchPicker(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Approximate collapsed height; tune to taste if used inside a
  /// SliverAppBar / AppBar `bottom`.
  @override
  Size get preferredSize => const Size.fromHeight(140);
}

class _OrgLogo extends StatelessWidget {
  final ImageProvider? image;
  final Color color;

  const _OrgLogo({required this.image, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        image: image != null
            ? DecorationImage(image: image!, fit: BoxFit.cover)
            : null,
      ),
      child: image == null
          ? Icon(Icons.storefront_rounded, color: color)
          : null,
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final Color color;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _NotificationBell({
    required this.count,
    required this.color,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none_rounded, color: color, size: 26),
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String initials;
  final ImageProvider? image;
  final Color accentColor;
  final VoidCallback? onTap;

  const _ProfileAvatar({
    required this.initials,
    required this.image,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: CircleAvatar(
        radius: 18,
        backgroundColor: accentColor,
        backgroundImage: image,
        child: image == null
            ? Text(
                initials.isNotEmpty ? initials.toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              )
            : null,
      ),
    );
  }
}

class _BranchSwitcherPill extends StatelessWidget {
  final String label;
  final bool interactive;
  final Color foregroundColor;
  final IconData icon;
  final VoidCallback onTap;

  const _BranchSwitcherPill({
    required this.label,
    required this.interactive,
    required this.foregroundColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: foregroundColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          // Only show the dropdown affordance when switching is possible.
          if (interactive)
            Icon(Icons.keyboard_arrow_down_rounded, color: foregroundColor),
        ],
      ),
    );

    if (!interactive) {
      // Non-tappable, no ripple, no chevron - communicates "nothing to switch".
      return pill;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: pill,
      ),
    );
  }
}

// ============================================================================
// REAL USAGE
// ============================================================================
//
// See features/dashboard/widgets/dashboard_sticky_header.dart for the
// live integration: it fetches DashboardHeaderModel via
// DashboardHeaderApi, resolves the right `branches` list + labels for
// the logged-in user's UserRole, and renders this widget as the
// DashboardPage's `appBar`.
