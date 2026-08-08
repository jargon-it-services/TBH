import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';

/// Dashboard content shown to a [UserRole.superAdmin] user.
///
/// Placeholder for now — swap the body of [build] for the real
/// super-admin widgets (org-wide stats, tenant/branch management, etc.)
/// whenever that's ready. Nothing outside [DashboardRegistry] needs to
/// change when this widget grows.
class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Super Admin Dashboard', style: AppTextStyles.h2),
    );
  }
}
