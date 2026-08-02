/// ================= SALARY RULE (LIST ITEM) =================
///
/// Lightweight shape returned by `GET /salary-rules` — just enough to
/// populate the Staff Create/Edit form's Salary Rule picker. Mirrors
/// how the pre-existing, similarly lightweight `ServiceModel` backs
/// the Branch form's service picker: staff reference a salary rule by
/// id, they never carry salary figures directly (per the Staff module
/// spec's "Salary values should not be stored directly in Staff").
///
/// `lib/features/salary_rules/` exists as an empty placeholder feature
/// folder (same starting point `lib/features/services/` was in before
/// the Service module) — full Salary Rule management (create/edit
/// rules themselves) is out of scope here; this is only the read-only
/// picker support the Staff module needs.
class SalaryRuleModel {
  final int id;
  final String name;
  final bool active;

  SalaryRuleModel({
    required this.id,
    required this.name,
    this.active = true,
  });

  factory SalaryRuleModel.fromJson(Map<String, dynamic> json) {
    return SalaryRuleModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      active: json['active'] ?? true,
    );
  }
}
