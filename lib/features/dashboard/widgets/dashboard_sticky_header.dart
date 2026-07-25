import 'package:flutter/material.dart';

import '../../../core/connectivity/connectivity_aware_refresh.dart';
import '../../../core/models/user_role.dart';
import '../../../core/network/apis/dashboard_header_api.dart';
import '../../../core/services/DataModels/dashboard_header_model.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/shimmers/dashboard_header_shimmer.dart';
import '../../../core/widgets/sticky_org_header.dart';

/// Dashboard's role-aware sticky header — plugged in as [DashboardPage]'s
/// `appBar`.
///
/// Owns the header's own loading/error/success lifecycle (fetching
/// [DashboardHeaderModel] via [DashboardHeaderApi]) and resolves the
/// *role-based dropdown behavior* the header must show, per the single
/// source of truth for roles, [UserRole]:
///   - Super Admin    -> dropdown of Organizations/Accounts.
///   - Account Admin  -> dropdown of Branches under the account.
///   - Branch Admin / Manager / Employee -> a single, non-interactive
///     label showing their assigned Branch Name.
///
/// That last case needs no special-casing here: [StickyOrgHeader]
/// already renders its switcher as a static label (no chevron, no tap)
/// whenever it's given 0 or 1 entries — so passing a single-item list
/// containing just the assigned branch naturally satisfies "display
/// only the assigned Branch Name" using the exact same code path the
/// dropdown roles use.
///
/// State management follows the same pattern as the rest of the app
/// (e.g. `FirmListPage`): a plain `StatefulWidget` + `setState`, with
/// [ConnectivityAwareRefresh] for "retry automatically once back
/// online" — no new architecture introduced.
class DashboardStickyHeader extends StatefulWidget
    implements PreferredSizeWidget {
  const DashboardStickyHeader({super.key});

  @override
  State<DashboardStickyHeader> createState() => _DashboardStickyHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(152);
}

class _DashboardStickyHeaderState extends State<DashboardStickyHeader>
    with ConnectivityAwareRefresh<DashboardStickyHeader> {
  final DashboardHeaderApi _api = DashboardHeaderApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  DashboardHeaderModel? _header;

  /// Which scope (organization or branch) the switcher pill currently
  /// shows as selected. This is UI-only state for now — Current Scope
  /// for this task is the header itself; wiring a selection change
  /// through to reload the dashboard *body* for that org/branch is
  /// follow-up work (see [_onScopeChanged]).
  BranchModel? _selectedScope;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Future<void> onReconnected() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    setState(() {
      // Only take over the header with the shimmer when there's
      // nothing else to show yet — same rule FirmListPage uses, so a
      // background retry never yanks a header the user is already
      // looking at.
      if (!silent && _header == null) _loading = true;
      _error = null;
    });

    final response = await _api.fetchHeader();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess && response.data != null) {
      final header = response.data!;
      setState(() {
        _header = header;
        _selectedScope ??=
            _resolveDefaultSelection(header, SessionManager.instance.role);
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        if (_header == null) {
          _error = response.error ?? 'Failed to load dashboard header.';
          _isOffline = response.isConnectivityError;
        }
      });
    }
  }

  /// Picks the initially-selected scope from the API's optional
  /// `selected_organization_id` / `selected_branch_id`, falling back
  /// to the "All ..." aggregate (Super Admin / Account Admin) or the
  /// single assigned branch (Branch Admin / Manager / Employee) —
  /// entirely driven by the response + role, never hardcoded.
  BranchModel _resolveDefaultSelection(
    DashboardHeaderModel header,
    UserRole role,
  ) {
    switch (role) {
      case UserRole.superAdmin:
        final selectedId = header.selectedOrganizationId;
        if (selectedId == null) return const AllBranches();
        return header.organizations.firstWhere(
          (org) => org.id == selectedId,
          orElse: () => const AllBranches(),
        );
      case UserRole.accountAdmin:
        final selectedId = header.selectedBranchId;
        if (selectedId == null) return const AllBranches();
        return header.branches.firstWhere(
          (branch) => branch.id == selectedId,
          orElse: () => const AllBranches(),
        );
      case UserRole.branchAdmin:
      case UserRole.manager:
      case UserRole.employee:
        return header.assignedBranch ??
            const BranchModel(id: '', name: 'No Branch Assigned');
    }
  }

  void _onScopeChanged(BranchModel scope) {
    setState(() => _selectedScope = scope);
    // TODO(dashboard-body): once the dashboard body is wired to a
    // scope, notify it here (e.g. via DashboardRegistry) so switching
    // org/branch refreshes branch-scoped data. Out of scope for this
    // task, which covers the header only.
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const DashboardHeaderShimmer();
    }

    if (_error != null) {
      return _DashboardHeaderErrorBar(
        message: _error!,
        isOffline: _isOffline,
        onRetry: _load,
      );
    }

    final header = _header;
    if (header == null) {
      // Defensive fallback only — unreachable in practice since
      // `_loading`/`_error` above already cover every non-success
      // state, but guards against a genuinely empty response.
      return const DashboardHeaderShimmer();
    }

    return _buildHeaderForRole(
      context,
      SessionManager.instance.role,
      header,
    );
  }

  Widget _buildHeaderForRole(
    BuildContext context,
    UserRole role,
    DashboardHeaderModel header,
  ) {
    final String roleLabel =
        header.roleLabel.isNotEmpty ? header.roleLabel : role.displayName;

    switch (role) {
      case UserRole.superAdmin:
        return StickyOrgHeader(
          orgName: header.orgName,
          roleLabel: roleLabel,
          accountCode: header.accountCode,
          branches: header.organizations,
          selectedBranch: _selectedScope ?? const AllBranches(),
          onBranchChanged: _onScopeChanged,
          notificationCount: header.notificationCount,
          onNotificationTap: () {},
          profileInitials: header.profileInitials,
          onProfileTap: () {},
          allEntitiesLabel: 'All Organizations',
          switchSheetTitle: 'Switch Organization',
          switcherIcon: Icons.apartment_rounded,
        );

      case UserRole.accountAdmin:
        return StickyOrgHeader(
          orgName: header.orgName,
          roleLabel: roleLabel,
          accountCode: header.accountCode,
          branches: header.branches,
          selectedBranch: _selectedScope ?? const AllBranches(),
          onBranchChanged: _onScopeChanged,
          notificationCount: header.notificationCount,
          onNotificationTap: () {},
          profileInitials: header.profileInitials,
          onProfileTap: () {},
          allEntitiesLabel: 'All Branches',
          switchSheetTitle: 'Switch Branch',
          switcherIcon: Icons.storefront_rounded,
        );

      case UserRole.branchAdmin:
      case UserRole.manager:
      case UserRole.employee:
        // Only the assigned branch — a single-item list makes
        // StickyOrgHeader render it as a static, non-interactive
        // label automatically (its switcher only becomes tappable for
        // 2+ entries), which is exactly "display only the assigned
        // Branch Name".
        final assignedBranch = header.assignedBranch ??
            const BranchModel(id: '', name: 'No Branch Assigned');
        return StickyOrgHeader(
          orgName: header.orgName,
          roleLabel: roleLabel,
          accountCode: header.accountCode,
          branches: [assignedBranch],
          selectedBranch: assignedBranch,
          onBranchChanged: null,
          notificationCount: header.notificationCount,
          onNotificationTap: () {},
          profileInitials: header.profileInitials,
          onProfileTap: () {},
          switcherIcon: Icons.storefront_rounded,
        );
    }
  }
}

/// Compact inline "couldn't load your header" bar with a retry button,
/// sized to fit in the same `appBar` slot the real header occupies.
///
/// Deliberately not a full-screen [NetworkStateView]: the app-wide
/// `ConnectivityBanner` (see main.dart) already tells the user they're
/// offline, so this only needs to acknowledge the header specifically
/// failed and offer a retry — the same "don't show two offline
/// messages at once" reasoning `FirmListPage` documents for its own
/// error state.
class _DashboardHeaderErrorBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String message;
  final bool isOffline;
  final VoidCallback onRetry;

  const _DashboardHeaderErrorBar({
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.large),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2),
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
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                    ),
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
  Size get preferredSize => const Size.fromHeight(152);
}
