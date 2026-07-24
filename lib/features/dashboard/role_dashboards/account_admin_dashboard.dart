import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';

/// Dashboard content shown to a [UserRole.accountAdmin] user.
///
/// Placeholder for now — swap the body of [build] for the real
/// account-admin widgets whenever that's ready. Nothing outside
/// [DashboardRegistry] needs to change when this widget grows.
class AccountAdminDashboard extends StatelessWidget {
  const AccountAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Account Admin Dashboard', style: AppTextStyles.h2),
    );
  }
}
