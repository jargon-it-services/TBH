/// ================= STAFF (LIST ITEM) =================
///
/// Lightweight shape returned by `GET /staff/list` — just enough to
/// render the Staff List screen (card/list tile + search/filter). Full
/// details (Aadhaar, employment dates, salary rule, app access, etc.)
/// live in [StaffDetailResponse], fetched separately per-staff-member.
/// Mirrors the [ServiceListItem]/`ServiceDetailResponse` split built
/// for the Service module.
class StaffListItem {
  final int id;
  final String fullName;
  final String mobile;
  final String email;
  final String employeeCode;
  final String designation;
  final String specialist;
  final String branchName;
  final String status;

  /// Profile photo URL, when uploaded. Null/empty means "no photo" —
  /// callers fall back to an initials avatar, same fallback pattern
  /// used across Branch/Service.
  final String? photo;

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasPhoto => photo != null && photo!.trim().isNotEmpty;

  StaffListItem({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.employeeCode,
    required this.designation,
    required this.specialist,
    required this.branchName,
    required this.status,
    this.photo,
  });

  factory StaffListItem.fromJson(Map<String, dynamic> json) {
    return StaffListItem(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      designation: json['designation'] ?? '',
      specialist: json['specialist'] ?? '',
      branchName: json['branch_name'] ?? '',
      status: json['status'] ?? '',
      photo: json['photo'] as String?,
    );
  }
}
