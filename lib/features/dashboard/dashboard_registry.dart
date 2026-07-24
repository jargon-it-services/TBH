import 'package:flutter/material.dart';

import '../../core/models/user_role.dart';
import 'role_dashboards/account_admin_dashboard.dart';
import 'role_dashboards/branch_admin_dashboard.dart';
import 'role_dashboards/employee_dashboard.dart';
import 'role_dashboards/manager_dashboard.dart';
import 'role_dashboards/super_admin_dashboard.dart';

/// Resolves "which dashboard content does this role see" as a single
/// table lookup instead of `if (role == ...) ... else if (role == ...)`
/// logic scattered around the widget tree.
///
/// To add a new role's dashboard: create its content widget under
/// `role_dashboards/`, add it to [_builders] below, and — if it's a
/// genuinely new role — add it to [UserRole]. No other file in the app
/// needs to know this table exists; [DashboardPage] just calls
/// [DashboardRegistry.contentFor].
class DashboardRegistry {
  DashboardRegistry._();

  static final Map<UserRole, WidgetBuilder> _builders = {
    UserRole.superAdmin: (_) => const SuperAdminDashboard(),
    UserRole.accountAdmin: (_) => const AccountAdminDashboard(),
    UserRole.branchAdmin: (_) => const BranchAdminDashboard(),
    UserRole.manager: (_) => const ManagerDashboard(),
    UserRole.employee: (_) => const EmployeeDashboard(),
  };

  /// Builds the dashboard content for [role]. Every [UserRole] value is
  /// registered above, so this never has a genuinely missing case — the
  /// [EmployeeDashboard] fallback exists only as a defensive guard
  /// against the map above ever getting out of sync with [UserRole]
  /// (e.g. a new role added to the enum but not yet given content
  /// here), rather than something reachable in normal operation.
  static Widget contentFor(BuildContext context, UserRole role) {
    final builder = _builders[role] ?? _builders[UserRole.employee]!;
    return builder(context);
  }
}
