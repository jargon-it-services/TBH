import 'package:flutter/material.dart';

import '../../../core/services/DataModels/dashboard_header_model.dart';
import '../../../core/services/DataModels/dashboard_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/sticky_org_header.dart';

/// Sticky header for Account Admin / Branch Admin / Manager / Employee
/// — the four roles whose header now arrives as `dashboard_header`
/// inside the merged `/dashboard` response instead of from its own
/// `/dashboard/header` call.
///
/// Unlike [DashboardStickyHeader] (kept untouched, Super-Admin-only),
/// this widget does no fetching of its own: [DashboardPage] owns the
/// single merged request and hands the parsed [DashboardHeaderData]
/// straight in, along with the page's own loading/error state so the
/// header can show the same shimmer/error chrome while that one fetch
/// is in flight. This is what "two APIs merged into one" means for the
/// header specifically — one fetch, one lifecycle, shared by both the
/// header and the body.
///
/// Branch-switcher behavior is unchanged from the existing pattern:
/// [StickyOrgHeader] itself already renders a static label for 0/1
/// branches and a tappable dropdown (with an "All Branches" option)
/// for 2+, so this widget only needs to track which branch is
/// currently selected — it doesn't re-implement that Case 1 / Case 2
/// logic.
class MergedDashboardHeader extends StatefulWidget
    implements PreferredSizeWidget {
  const MergedDashboardHeader({
    super.key,
    required this.headerData,
    this.loading = false,
    this.error,
    this.isOffline = false,
    this.onRetry,
    this.onScopeChanged,
  });

  /// Null only while [loading] is true or [error] is set on the very
  /// first load (no header to show yet).
  final DashboardHeaderData? headerData;
  final bool loading;
  final String? error;
  final bool isOffline;
  final VoidCallback? onRetry;

  /// Fired whenever the user picks a different branch (or "All
  /// Branches"). Purely a UI notification for now, same as
  /// [DashboardStickyHeader]'s equivalent callback — wiring a branch
  /// selection through to reload branch-scoped body data is follow-up
  /// work, not part of this merge.
  final ValueChanged<BranchModel>? onScopeChanged;

  @override
  State<MergedDashboardHeader> createState() => _MergedDashboardHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(140);
}

class _MergedDashboardHeaderState extends State<MergedDashboardHeader> {
  BranchModel? _selectedScope;

  BranchModel _defaultSelection(DashboardHeaderData header) {
    if (header.branches.length > 1) return const AllBranches();
    if (header.branches.isNotEmpty) return header.branches.first;
    return const BranchModel(id: '', name: 'No Branch Assigned');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.headerData == null) {
      return const _MergedHeaderShimmer();
    }

    final header = widget.headerData;

    if (header == null) {
      return _MergedHeaderErrorBar(
        message: widget.error ?? 'Failed to load dashboard header.',
        isOffline: widget.isOffline,
        onRetry: widget.onRetry,
      );
    }

    _selectedScope ??= _defaultSelection(header);
    if (header.branches.length <= 1) {
      // Nothing to switch between — always reflect the single/only
      // branch directly rather than any stale prior selection.
      _selectedScope = _defaultSelection(header);
    } else if (_selectedScope is! AllBranches &&
        !header.branches.contains(_selectedScope)) {
      // The previously-selected branch disappeared from a fresh
      // payload (e.g. reassigned) — fall back to the aggregate view
      // instead of pointing at a branch that no longer exists.
      _selectedScope = const AllBranches();
    }

    return StickyOrgHeader(
      orgName: header.accountName,
      roleLabel: header.roleLabel,
      accountCode: header.accountCode,
      branches: header.branches,
      selectedBranch: _selectedScope!,
      onBranchChanged: header.branches.length > 1
          ? (branch) {
              setState(() => _selectedScope = branch);
              widget.onScopeChanged?.call(branch);
            }
          : null,
      notificationCount: header.notificationCount,
      onNotificationTap: () {},
      profileInitials: header.profileInitials,
      onProfileTap: () {},
      allEntitiesLabel: 'All Branches',
      switchSheetTitle: 'Switch Branch',
      switcherIcon: Icons.storefront_rounded,
    );
  }
}

class _MergedHeaderShimmer extends StatelessWidget {
  const _MergedHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    // Mirrors DashboardHeaderShimmer's layout/height exactly so the
    // page doesn't jump once real data arrives; kept file-local since
    // Super Admin's shimmer file is out of scope to modify.
    return Material(
      color: AppColors.primary,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.large)),
      ),
      child: const SafeArea(
        bottom: false,
        child: SizedBox(height: 116),
      ),
    );
  }
}

/// Compact inline "couldn't load your header" bar with a retry button —
/// same shape as [DashboardStickyHeader]'s private error bar, kept as
/// its own small widget here since that one is file-private to the
/// (untouched) Super Admin header file.
class _MergedHeaderErrorBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String message;
  final bool isOffline;
  final VoidCallback? onRetry;

  const _MergedHeaderErrorBar({
    required this.message,
    required this.isOffline,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.large)),
      ),
      child: SafeArea(
        bottom: false,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              children: [
                Icon(
                  isOffline ? Icons.wifi_off_rounded : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(140);
}
