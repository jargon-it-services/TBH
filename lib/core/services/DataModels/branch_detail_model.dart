/// ================= BRANCH SERVICE (TAG) =================
///
/// A service offered at a branch, as attached to the branch itself —
/// distinct from [ServiceModel] (the full catalog a branch picks
/// from). Only carries what the Branch Details screen needs to display.
class BranchServiceItem {
  final int id;
  final String name;

  BranchServiceItem({required this.id, required this.name});

  factory BranchServiceItem.fromJson(Map<String, dynamic> json) {
    return BranchServiceItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// ================= BRANCH EMPLOYEE (ASSIGNED STAFF) =================
///
/// A staff member assigned to a branch. This app has no dedicated
/// Employees feature/API of its own yet (see the Branch module
/// spec — employee assignment is explicitly routed to "the dedicated
/// employee management flow" instead of Add/Edit Branch), so this is
/// intentionally the minimal shape the Branch Details screen needs to
/// *display* who's assigned — not a full employee record.
class BranchEmployeeItem {
  final int id;
  final String name;
  final String role;
  final String? photo;

  BranchEmployeeItem({
    required this.id,
    required this.name,
    required this.role,
    this.photo,
  });

  factory BranchEmployeeItem.fromJson(Map<String, dynamic> json) {
    return BranchEmployeeItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      photo: json['photo'] as String?,
    );
  }
}

/// ================= BRANCH DETAIL =================
///
/// Full branch record — backs both the Branch Details screen and the
/// Edit Branch form (pre-filling every field). Mirrors the
/// `FirmDetailResponse` split: [BranchModel] is the trimmed list-item
/// shape, this is the complete one, fetched per-branch via
/// `BranchesApi.fetchBranchDetail`.
class BranchDetailResponse {
  final int id;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final String mobile;
  final String email;
  final String branchType;
  final String openingTime;
  final String closingTime;

  /// Comma-separated day names (e.g. "Monday,Tuesday"), or the literal
  /// value "None" for "No Weekly Off". Kept as a single `String` field
  /// (not a `List<String>`) so the wire shape/model stay unchanged —
  /// only how the Add/Edit Branch form interprets it changes. See
  /// [weeklyOffDays] and [isNoWeeklyOff] for the parsed view.
  final String weeklyOff;
  final String status;
  final List<BranchServiceItem> services;

  /// Staff assigned to this branch — display-only here (see
  /// [BranchEmployeeItem] doc comment for why Add/Edit Branch never
  /// writes to this list).
  final List<BranchEmployeeItem> employees;

  /// Branch logo URL, when uploaded. Null/empty means "use the default
  /// icon avatar".
  final String? logo;

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasLogo => logo != null && logo!.trim().isNotEmpty;

  bool get isNoWeeklyOff => weeklyOff.trim().toLowerCase() == 'none';

  /// Parsed view of [weeklyOff] as individual day names, ignoring blank
  /// entries. Empty when [isNoWeeklyOff] is true or nothing is set.
  List<String> get weeklyOffDays {
    if (isNoWeeklyOff || weeklyOff.trim().isEmpty) return [];
    return weeklyOff
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();
  }

  /// Display string for the Weekly Off row on the Details screen.
  String get weeklyOffDisplay {
    if (isNoWeeklyOff) return 'No Weekly Off';
    final days = weeklyOffDays;
    return days.isEmpty ? '-' : days.join(', ');
  }

  /// Single-line address for display, combining both address lines.
  String get fullAddress {
    final parts = [
      addressLine1,
      addressLine2,
      city,
      state,
      pincode,
    ].where((p) => p.trim().isNotEmpty);
    return parts.join(', ');
  }

  BranchDetailResponse({
    required this.id,
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.latitude,
    this.longitude,
    required this.mobile,
    required this.email,
    required this.branchType,
    required this.openingTime,
    required this.closingTime,
    required this.weeklyOff,
    required this.status,
    required this.services,
    this.employees = const [],
    this.logo,
  });

  factory BranchDetailResponse.fromJson(Map<String, dynamic> json) {
    return BranchDetailResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      addressLine1: json['address_line1'] ?? '',
      addressLine2: json['address_line2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      branchType: json['branch_type'] ?? '',
      openingTime: json['opening_time'] ?? '',
      closingTime: json['closing_time'] ?? '',
      weeklyOff: json['weekly_off'] ?? '',
      status: json['status'] ?? '',
      services: (json['services'] as List? ?? [])
          .map((e) => BranchServiceItem.fromJson(e))
          .toList(),
      employees: (json['employees'] as List? ?? [])
          .map((e) => BranchEmployeeItem.fromJson(e))
          .toList(),
      logo: json['logo'] as String?,
    );
  }
}
