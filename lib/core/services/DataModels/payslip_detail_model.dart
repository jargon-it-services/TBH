/// ================= PAYSLIP LINE ITEM =================
///
/// A single Earnings or Deductions row (e.g. "Basic Salary" / ₹20,000).
/// Shared shape for both sections — same split used by the reference
/// Payslip Details design.
class PayslipLineItem {
  final String label;
  final double amount;

  PayslipLineItem({required this.label, required this.amount});

  factory PayslipLineItem.fromJson(Map<String, dynamic> json) {
    return PayslipLineItem(
      label: json['label'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// ================= PAYSLIP DETAILS =================
///
/// Full shape returned by `GET /payslips/{id}/details` — everything the
/// Payslip Details screen needs: employee header, Earnings/Deductions
/// breakdown, Net Salary, and the Generated/Approved/Rejected/Paid By
/// audit trail (§5.1 of the module spec). Each "*_by" field is only
/// populated once the corresponding status has actually happened —
/// callers must treat null/empty as "not shown" rather than hardcoding
/// which fields apply to which status in more than one place.
class PayslipDetailResponse {
  final int id;
  final int employeeId;
  final String employeeName;
  final String designation;
  final String? photo;

  final int month;
  final int year;
  final String status;

  final List<PayslipLineItem> earnings;
  final double totalEarnings;
  final List<PayslipLineItem> deductions;
  final double totalDeductions;
  final double netSalary;

  final String? generatedBy;
  final String? approvedBy;
  final String? rejectedBy;
  final String? paidBy;

  /// URL for the Download action once the payslip is Paid. Null while
  /// not yet available.
  final String? downloadUrl;

  String get monthYearLabel => '${_monthName(month)} $year';

  bool get isGenerated => status.toLowerCase() == 'generated';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isPaid => status.toLowerCase() == 'paid';

  PayslipDetailResponse({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.designation,
    this.photo,
    required this.month,
    required this.year,
    required this.status,
    required this.earnings,
    required this.totalEarnings,
    required this.deductions,
    required this.totalDeductions,
    required this.netSalary,
    this.generatedBy,
    this.approvedBy,
    this.rejectedBy,
    this.paidBy,
    this.downloadUrl,
  });

  factory PayslipDetailResponse.fromJson(Map<String, dynamic> json) {
    return PayslipDetailResponse(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      employeeName: json['employee_name'] ?? '',
      designation: json['designation'] ?? '',
      photo: json['photo'] as String?,
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      status: json['status'] ?? '',
      earnings: (json['earnings'] as List? ?? [])
          .map((e) => PayslipLineItem.fromJson(e))
          .toList(),
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      deductions: (json['deductions'] as List? ?? [])
          .map((e) => PayslipLineItem.fromJson(e))
          .toList(),
      totalDeductions: (json['total_deductions'] as num?)?.toDouble() ?? 0,
      netSalary: (json['net_salary'] as num?)?.toDouble() ?? 0,
      generatedBy: json['generated_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      rejectedBy: json['rejected_by'] as String?,
      paidBy: json['paid_by'] as String?,
      downloadUrl: json['download_url'] as String?,
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
