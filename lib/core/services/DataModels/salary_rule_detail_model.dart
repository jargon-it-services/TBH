/// ================= SALARY RULE DETAIL =================
///
/// Full salary rule record — backs both the Salary Rule Details screen
/// and the Edit Salary Rule form (pre-filling every field). Mirrors the
/// `ServiceDetailResponse` split: [SalaryRuleListItem] is the trimmed
/// list-item shape, this is the complete one.
///
/// Carries no commission fields. Commission is already configured
/// per-Service (Customer Price / Commission Type / Commission Value,
/// in the Service module) — Salary Rule only describes fixed pay, bonus,
/// and advance recovery, so it never duplicates that configuration.
class SalaryRuleDetailResponse {
  final int id;
  final String name;
  final String description;

  /// "Fixed Salary", "Service Commission", or "Hybrid". Only
  /// "Fixed Salary" and "Hybrid" show a Salary Configuration section
  /// (the Fixed Salary field) — "Service Commission" has nothing left
  /// to configure here since commission itself lives on the Service.
  final String salaryType;

  final double? fixedSalary;

  final double? monthlyTarget;
  final double? targetBonus;

  final bool allowAdvanceRecovery;
  final double? maxRecoveryPerMonth;

  final String status;

  bool get isActive => status.toLowerCase() == 'active';

  /// Whether the Salary Configuration section (Fixed Salary) applies —
  /// true for Fixed Salary and Hybrid, false for Service Commission.
  bool get showSalaryConfiguration => salaryType == 'Fixed Salary' || salaryType == 'Hybrid';

  SalaryRuleDetailResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.salaryType,
    this.fixedSalary,
    this.monthlyTarget,
    this.targetBonus,
    this.allowAdvanceRecovery = false,
    this.maxRecoveryPerMonth,
    required this.status,
  });

  factory SalaryRuleDetailResponse.fromJson(Map<String, dynamic> json) {
    return SalaryRuleDetailResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      salaryType: json['salary_type'] ?? '',
      fixedSalary: (json['fixed_salary'] as num?)?.toDouble(),
      monthlyTarget: (json['monthly_target'] as num?)?.toDouble(),
      targetBonus: (json['target_bonus'] as num?)?.toDouble(),
      allowAdvanceRecovery: json['allow_advance_recovery'] ?? false,
      maxRecoveryPerMonth: (json['max_recovery_per_month'] as num?)?.toDouble(),
      status: json['status'] ?? '',
    );
  }
}
