/// ================= EXPENSE BRANCH (ASSIGNMENT) =================
///
/// A branch this expense type applies to — mirrors `ServiceBranchItem`
/// on the Service module.
class ExpenseBranchItem {
  final int id;
  final String name;

  ExpenseBranchItem({required this.id, required this.name});

  factory ExpenseBranchItem.fromJson(Map<String, dynamic> json) {
    return ExpenseBranchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// ================= EXPENSE TYPE DETAIL =================
///
/// Full expense-type record — backs both the Expense Details screen
/// and the Edit Expense form. Expenses is a configuration screen: it
/// only defines a Name, Description, and which branch(es) it applies
/// to (all, or a specific selection) — no amount, category, photo, or
/// type field, per the module's latest scope.
class ExpenseDetailResponse {
  final int id;
  final String name;
  final String description;

  final bool allBranches;
  final List<ExpenseBranchItem> branches;

  final String status;

  bool get isActive => status.toLowerCase() == 'active';

  ExpenseDetailResponse({
    required this.id,
    required this.name,
    required this.description,
    this.allBranches = true,
    this.branches = const [],
    required this.status,
  });

  factory ExpenseDetailResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseDetailResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      allBranches: json['all_branches'] ?? true,
      branches: (json['branches'] as List? ?? [])
          .map((e) => ExpenseBranchItem.fromJson(e))
          .toList(),
      status: json['status'] ?? '',
    );
  }
}
