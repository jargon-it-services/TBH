import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';

/// Dashboard content shown to a [UserRole.employee] user.
///
/// Placeholder for now — swap the body of [build] for the real
/// employee widgets whenever that's ready. Nothing outside
/// [DashboardRegistry] needs to change when this widget grows. Also
/// the fallback content for any role value the app fails to recognize
/// (see [UserRole.fromApiValue]), since employee is the
/// least-privileged role.
class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Employee Dashboard', style: AppTextStyles.h2),
    );
  }
}
