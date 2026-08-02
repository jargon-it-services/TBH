/// ================= STAFF DETAIL =================
///
/// Full staff record — backs both the Staff Details screen and the
/// Edit Staff form (pre-filling every field). Mirrors the
/// `ServiceDetailResponse` split: [StaffListItem] is the trimmed
/// list-item shape, this is the complete one, fetched per-staff-member
/// via `StaffApi.fetchStaffDetail`.
///
/// Note [password]/[confirmPassword] deliberately have no fields here
/// — the backend never returns a password, and Edit Staff always
/// starts with the Application Access password fields blank (changing
/// it is opt-in), same as how login credentials are handled everywhere
/// else in this app.
class StaffDetailResponse {
  // ------------- Personal Information -------------
  final int id;
  final String fullName;
  final String mobile;
  final String email;
  final String? photo;
  final String gender;
  final String aadhaarNumber;
  final String? aadhaarCardUrl;

  // ------------- Employment Details -------------
  final String employeeCode;

  /// ISO-8601 date string (yyyy-MM-dd), same convention as every other
  /// date the API layer already hands back as plain text.
  final String joiningDate;
  final String designation;
  final String specialist;
  final int branchId;
  final String branchName;
  final int salaryRuleId;
  final String salaryRuleName;
  final String status;

  // ------------- Application Access -------------
  final bool allowAppLogin;
  final String appRole;
  final String username;

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasPhoto => photo != null && photo!.trim().isNotEmpty;
  bool get hasAadhaarCard =>
      aadhaarCardUrl != null && aadhaarCardUrl!.trim().isNotEmpty;

  StaffDetailResponse({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    this.photo,
    required this.gender,
    this.aadhaarNumber = '',
    this.aadhaarCardUrl,
    required this.employeeCode,
    required this.joiningDate,
    required this.designation,
    required this.specialist,
    required this.branchId,
    required this.branchName,
    required this.salaryRuleId,
    required this.salaryRuleName,
    required this.status,
    this.allowAppLogin = false,
    this.appRole = '',
    this.username = '',
  });

  factory StaffDetailResponse.fromJson(Map<String, dynamic> json) {
    return StaffDetailResponse(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      photo: json['photo'] as String?,
      gender: json['gender'] ?? '',
      aadhaarNumber: json['aadhaar_number'] ?? '',
      aadhaarCardUrl: json['aadhaar_card_url'] as String?,
      employeeCode: json['employee_code'] ?? '',
      joiningDate: json['joining_date'] ?? '',
      designation: json['designation'] ?? '',
      specialist: json['specialist'] ?? '',
      branchId: (json['branch_id'] as num?)?.toInt() ?? 0,
      branchName: json['branch_name'] ?? '',
      salaryRuleId: (json['salary_rule_id'] as num?)?.toInt() ?? 0,
      salaryRuleName: json['salary_rule_name'] ?? '',
      status: json['status'] ?? '',
      allowAppLogin: json['allow_app_login'] ?? false,
      appRole: json['app_role'] ?? '',
      username: json['username'] ?? '',
    );
  }
}
