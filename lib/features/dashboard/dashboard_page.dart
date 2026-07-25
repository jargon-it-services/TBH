import 'package:flutter/material.dart';

import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import 'dashboard_registry.dart';
import 'widgets/dashboard_sticky_header.dart';

/// The "Dashboard" bottom-nav tab.
///
/// This widget owns only the chrome shared by every role (the sticky
/// header) — the body is resolved for the current user's role through
/// [DashboardRegistry], and the header's own role-based dropdown
/// behavior (Organizations for Super Admin, Branches for Account
/// Admin, assigned-branch label otherwise) is resolved inside
/// [DashboardStickyHeader]. This widget itself never checks `role ==
/// something`; that branching lives in exactly those two places so it
/// can't drift out of sync as roles are added.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.instance.role;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const DashboardStickyHeader(),
      body: SafeArea(child: DashboardRegistry.contentFor(context, role)),
    );
  }
}
