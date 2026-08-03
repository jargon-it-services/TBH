/// ================= SALARY RULE (LIST ITEM) =================
///
/// Lightweight shape returned by `GET /salary-rules/list` — just enough
/// to render the Salary Rule List screen. Full details live in
/// [SalaryRuleDetailResponse], fetched separately per-rule. Mirrors the
/// [ServiceListItem]/`ServiceDetailResponse` split.
///
/// Distinct from the pre-existing, even-lighter `SalaryRuleModel`
/// (`core/services/DataModels/salary_rule_model.dart`), which only
/// backs the Staff form's Salary Rule picker (id/name/active) and is
/// left untouched here so that usage keeps working unchanged.
///
/// Carries no commission fields — commission is configured per-Service
/// (Customer Price / Commission Type / Commission Value, in the
/// Service module), not duplicated here.
class SalaryRuleListItem {
  final int id;
  final String name;
  final String salaryType;
  final double? fixedSalary;
  final String status;

  bool get isActive => status.toLowerCase() == 'active';

  SalaryRuleListItem({
    required this.id,
    required this.name,
    required this.salaryType,
    this.fixedSalary,
    required this.status,
  });

  factory SalaryRuleListItem.fromJson(Map<String, dynamic> json) {
    return SalaryRuleListItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      salaryType: json['salary_type'] ?? '',
      fixedSalary: (json['fixed_salary'] as num?)?.toDouble(),
      status: json['status'] ?? '',
    );
  }
}
