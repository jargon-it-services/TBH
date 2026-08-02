import 'branch_model.dart';
import 'salary_rule_model.dart';

/// ================= STAFF FORM CONFIG =================
///
/// Everything the Add/Edit Staff form needs to populate its dropdowns,
/// fetched in a single `GET /staff/form-config` call instead of one
/// request per picker. Branches and Salary Rules reuse the same
/// [BranchModel]/[SalaryRuleModel] shapes their own list endpoints
/// already return — this just bundles them alongside Specialist
/// options (previously a hardcoded list in the form) so all three come
/// from one backend-driven config payload.
class StaffFormConfig {
  final List<BranchModel> branches;
  final List<SalaryRuleModel> salaryRules;
  final List<String> specialists;

  StaffFormConfig({
    required this.branches,
    required this.salaryRules,
    required this.specialists,
  });

  factory StaffFormConfig.fromJson(Map<String, dynamic> json) {
    return StaffFormConfig(
      branches: (json['branches'] as List? ?? [])
          .map((e) => BranchModel.fromJson(e))
          .toList(),
      salaryRules: (json['salary_rules'] as List? ?? [])
          .map((e) => SalaryRuleModel.fromJson(e))
          .toList(),
      specialists: (json['specialists'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
