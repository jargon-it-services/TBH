import 'package:flutter/material.dart';

import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import 'dashboard_registry.dart';

/// The "Dashboard" bottom-nav tab.
///
/// This widget owns only the chrome shared by every role (the app
/// bar) — the body is resolved for the current user's role through
/// [DashboardRegistry]. This widget itself never checks `role ==
/// something`; that branching lives in exactly one place
/// ([DashboardRegistry]) so it can't drift out of sync as roles are
/// added.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionManager.instance.role;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(AppRadius.large)),
        ),
        centerTitle: true,
        title: Text(
          'Dashboard',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: DashboardRegistry.contentFor(context, role),
      ),
    );
  }
}
