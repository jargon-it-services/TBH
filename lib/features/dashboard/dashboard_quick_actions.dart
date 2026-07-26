import 'package:flutter/material.dart';

import '../../core/models/user_role.dart';

/// One tappable Quick Action tile shown at the top of the dashboard
/// body. [key] is a stable identifier (e.g. for wiring up real
/// navigation/analytics later) kept separate from [label] so the
/// display text can change without anything keyed off [key] breaking.
class QuickActionSpec {
  final String key;
  final String label;
  final IconData icon;

  const QuickActionSpec({
    required this.key,
    required this.label,
    required this.icon,
  });
}

/// Role -> Quick Actions lookup — the single place that decides which
/// actions a role sees, so the dashboard body itself never carries a
/// role switch of its own; it just asks [forRole] and renders whatever
/// comes back. Unlike the rest of the merged dashboard (which is
/// visibility-driven entirely by API data), Quick Actions are a fixed,
/// explicitly-specified set per role rather than something the backend
/// currently controls.
class DashboardQuickActions {
  DashboardQuickActions._();

  static const _addBranch = QuickActionSpec(
    key: 'add_branch',
    label: 'Add Branch',
    icon: Icons.store_mall_directory_outlined,
  );
  static const _addStaff = QuickActionSpec(
    key: 'add_staff',
    label: 'Add Staff',
    icon: Icons.person_add_alt_1_outlined,
  );
  static const _addService = QuickActionSpec(
    key: 'add_service',
    label: 'Add Service',
    icon: Icons.design_services_outlined,
  );
  static const _addExpenses = QuickActionSpec(
    key: 'add_expenses',
    label: 'Add Expenses',
    icon: Icons.receipt_long_outlined,
  );
  static const _viewPayslip = QuickActionSpec(
    key: 'view_payslip',
    label: 'View Payslip',
    icon: Icons.account_balance_wallet_outlined,
  );
  static const _viewStaff = QuickActionSpec(
    key: 'view_staff',
    label: 'View Staff',
    icon: Icons.groups_outlined,
  );
  static const _transactions = QuickActionSpec(
    key: 'transactions',
    label: 'Transactions',
    icon: Icons.swap_horiz_rounded,
  );
  static const _reports = QuickActionSpec(
    key: 'reports',
    label: 'Reports',
    icon: Icons.bar_chart_rounded,
  );

  /// Returns the ordered Quick Actions for [role]. Super Admin's
  /// dashboard is separate/untouched, so it gets none here.
  static List<QuickActionSpec> forRole(UserRole role) {
    switch (role) {
      case UserRole.employee:
        return const [_addService, _addExpenses, _viewPayslip];
      case UserRole.manager:
        return const [_addService, _addExpenses, _viewPayslip, _viewStaff];
      case UserRole.branchAdmin:
        return const [_addStaff, _addService, _transactions, _reports];
      case UserRole.accountAdmin:
        return const [_addBranch, _addStaff, _addService, _reports];
      case UserRole.superAdmin:
        return const [];
    }
  }
}
