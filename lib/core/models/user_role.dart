/// The set of roles the backend can assign to a logged-in user.
///
/// This is the single source of truth for "what roles exist in this
/// app". Anything that needs to behave differently per role — which
/// dashboard to show, which features to enable, which API scopes to
/// request — should be driven off this enum (and a registry/map keyed
/// by it, e.g. [DashboardRegistry]) rather than scattered
/// `if (role == 'super_admin')` string checks throughout the codebase.
enum UserRole {
  superAdmin,
  accountAdmin,
  branchAdmin,
  manager,
  employee;

  /// Maps the raw role string returned by the backend (snake_case,
  /// e.g. `"super_admin"`) to a [UserRole]. Case- and whitespace-
  /// insensitive, and also accepts the no-underscore form
  /// (`"superadmin"`) in case the backend's casing ever changes.
  ///
  /// Falls back to [employee] — the least-privileged role — for any
  /// value the app doesn't recognize (null, empty, unexpected string),
  /// so an unrecognized role can never silently grant more access than
  /// intended.
  static UserRole fromApiValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'account_admin':
      case 'accountadmin':
        return UserRole.accountAdmin;
      case 'branch_admin':
      case 'branchadmin':
        return UserRole.branchAdmin;
      case 'manager':
        return UserRole.manager;
      case 'employee':
        return UserRole.employee;
      default:
        return UserRole.employee;
    }
  }

  /// Inverse of [fromApiValue] — the canonical wire/storage form of
  /// this role. Used both when persisting the role to secure storage
  /// (so it round-trips through [fromApiValue] identically on the next
  /// app launch) and if the role ever needs to be sent back to an API.
  String get apiValue {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.accountAdmin:
        return 'account_admin';
      case UserRole.branchAdmin:
        return 'branch_admin';
      case UserRole.manager:
        return 'manager';
      case UserRole.employee:
        return 'employee';
    }
  }

  /// Human-readable label for showing the role in the UI.
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.accountAdmin:
        return 'Account Admin';
      case UserRole.branchAdmin:
        return 'Branch Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.employee:
        return 'Employee';
    }
  }
}
