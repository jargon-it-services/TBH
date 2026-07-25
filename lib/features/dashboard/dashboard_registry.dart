import 'package:flutter/material.dart';

import 'role_dashboards/super_admin_dashboard.dart';

/// Resolves Super Admin's dashboard content.
///
/// Account Admin, Branch Admin, Manager and Employee no longer go
/// through this registry: since they all now consume the same merged
/// `/dashboard` response, [DashboardPage] renders them with one shared,
/// fully data-driven body ([DashboardDynamicBody]) instead of a
/// per-role widget looked up from a table -- see
/// `dashboard_dynamic_body.dart`. Super Admin is unaffected by that
/// merge (it keeps its own separate header + dashboard flow), so it
/// keeps this registry indirection.
class DashboardRegistry {
  DashboardRegistry._();

  /// Builds Super Admin's dashboard content. [DashboardPage] only calls
  /// this when the signed-in role is [UserRole.superAdmin].
  static Widget contentFor(BuildContext context) {
    return const SuperAdminDashboard();
  }
}
