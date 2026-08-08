/// ================= PAYSLIP (LIST ITEM) =================
///
/// Lightweight shape returned by `GET /payslips/list` — just enough to
/// render the Payslip List screen's cards (status segment, branch
/// filter, search, month/year filter). Full breakdown (earnings,
/// deductions, generated/approved/rejected/paid-by) lives in
/// [PayslipDetailResponse], fetched separately per-payslip. Mirrors the
/// [SalaryRuleListItem]/`SalaryRuleDetailResponse` split already used
/// by the Salary Rules module.
class PayslipListItem {
  final int id;
  final int employeeId;
  final String employeeName;
  final String designation;
  final int branchId;
  final String branchName;

  /// Employee profile photo URL, when uploaded. Null/empty falls back
  /// to [InitialsAvatar], same fallback pattern used by Staff/Branch.
  final String? photo;

  /// Total earned amount shown on the list card (per module spec §2).
  final double amount;

  final int month; // 1-12
  final int year;
  final String status; // generated | approved | rejected | paid

  String get monthYearLabel => '${_monthName(month)} $year';

  bool get isGenerated => status.toLowerCase() == 'generated';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPaid => status.toLowerCase() == 'paid';

  bool get hasPhoto => photo != null && photo!.trim().isNotEmpty;

  PayslipListItem({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.designation,
    required this.branchId,
    required this.branchName,
    this.photo,
    required this.amount,
    required this.month,
    required this.year,
    required this.status,
  });

  factory PayslipListItem.fromJson(Map<String, dynamic> json) {
    return PayslipListItem(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'] ?? '',
      designation: json['designation'] ?? '',
      branchId: json['branch_id'] ?? 0,
      branchName: json['branch_name'] ?? '',
      photo: json['photo'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      status: json['status'] ?? '',
    );
  }

  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (month < 1 || month > 12) return '';
    return names[month - 1];
  }
}
