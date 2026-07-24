import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';

/// Dashboard content shown to a [UserRole.manager] user.
///
/// Placeholder for now — swap the body of [build] for the real
/// manager widgets whenever that's ready. Nothing outside
/// [DashboardRegistry] needs to change when this widget grows.
class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Manager Dashboard', style: AppTextStyles.h2),
    );
  }
}
