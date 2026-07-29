// login_response_model.dart
//
// Nested models backing the new `/auth/login` response shape.
//
// The login response's `data` object used to be flat (`token`,
// `refresh_token`, `user_name`, `role`). It is now nested:
//
//   data.token, data.refresh_token, data.expires_in
//   data.user_info    -> LoginUserInfo
//   data.account      -> LoginAccountInfo
//   data.recent_plan  -> LoginRecentPlan
//   data.management   -> LoginManagementInfo
//   data.feature_lock -> List<String>
//
// [LoginResult] (in `login_api.dart`) is the top-level container that
// ties these together; these classes exist separately (rather than
// inlined in `login_api.dart`) to match how every other domain in this
// app already organizes its response models — see
// `dashboard_header_model.dart`, `firm_model.dart`, etc.
//
// NOTE ON `account`: the migration spec that introduced this shape
// refers to this block as `account_info`, but the actual sample
// payload (and the mock fixture) key it as `account`. [LoginAccountInfo]
// parses `account` — the key the payload actually sends. If a future
// backend contract renames the wire key to `account_info`, only the
// single lookup in `LoginResult.fromJson` needs to change.

/// `data.user_info` — the logged-in user's own identity/profile.
///
/// This is where `user_name` and `role` now live (previously
/// top-level on the login response). See [LoginResult.userName] and
/// [LoginResult.role] for the backward-compatible accessors that keep
/// existing call sites working unchanged.
class LoginUserInfo {
  final int id;
  final String userName;
  final String email;
  final String mobile;

  /// Raw role string exactly as sent by the backend (e.g.
  /// `"account_admin"`). Use [LoginResult.role] to get a typed
  /// [UserRole] instead of reading this directly.
  final String role;

  final String? profileImage;
  final String status;

  const LoginUserInfo({
    required this.id,
    required this.userName,
    required this.email,
    required this.mobile,
    required this.role,
    this.profileImage,
    required this.status,
  });

  /// Empty/default instance — used as a safe fallback if a login
  /// response is ever missing `user_info` entirely (shouldn't happen,
  /// but keeps [LoginResult.fromJson] from throwing on a malformed
  /// payload).
  static const empty = LoginUserInfo(
    id: 0,
    userName: '',
    email: '',
    mobile: '',
    role: '',
    status: '',
  );

  factory LoginUserInfo.fromJson(Map<String, dynamic> json) {
    return LoginUserInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userName: json['user_name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      role: json['role'] ?? '',
      profileImage: json['profile_image'] as String?,
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_name': userName,
    'email': email,
    'mobile': mobile,
    'role': role,
    if (profileImage != null) 'profile_image': profileImage,
    'status': status,
  };
}

/// `data.account` — the organization/account the logged-in user
/// belongs to. See the file-level note above on the `account` vs.
/// `account_info` wire-key discrepancy.
class LoginAccountInfo {
  final String name;
  final String code;
  final String branchName;

  const LoginAccountInfo({
    required this.name,
    required this.code,
    required this.branchName,
  });

  factory LoginAccountInfo.fromJson(Map<String, dynamic> json) {
    return LoginAccountInfo(
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      branchName: json['branch_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'branch_name': branchName,
  };
}

/// `data.recent_plan` — the account's current subscription plan, as
/// known at login time. (The Subscriptions feature has its own richer
/// plan models fetched separately — this is just the login-time
/// snapshot.)
class LoginRecentPlan {
  final String name;
  final String validUntil;
  final String status;

  /// Format string (e.g. `"dd MMM yyyy"`) the backend suggests for
  /// displaying [validUntil].
  final String dateFormat;

  const LoginRecentPlan({
    required this.name,
    required this.validUntil,
    required this.status,
    required this.dateFormat,
  });

  factory LoginRecentPlan.fromJson(Map<String, dynamic> json) {
    return LoginRecentPlan(
      name: json['name'] ?? '',
      validUntil: json['valid_until'] ?? '',
      status: json['status'] ?? '',
      dateFormat: json['date_format'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'valid_until': validUntil,
    'status': status,
    'date_format': dateFormat,
  };
}

/// `data.management` — account-wide usage counters.
class LoginManagementInfo {
  final int totalFirms;
  final int totalStaff;
  final int totalServices;

  const LoginManagementInfo({
    required this.totalFirms,
    required this.totalStaff,
    required this.totalServices,
  });

  factory LoginManagementInfo.fromJson(Map<String, dynamic> json) {
    return LoginManagementInfo(
      totalFirms: (json['total_firms'] as num?)?.toInt() ?? 0,
      totalStaff: (json['total_staff'] as num?)?.toInt() ?? 0,
      totalServices: (json['total_services'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_firms': totalFirms,
    'total_staff': totalStaff,
    'total_services': totalServices,
  };
}
