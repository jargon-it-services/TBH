/// ================= EXPENSE TYPE (LIST ITEM) =================
///
/// Lightweight shape returned by `GET /expenses/list` — just enough to
/// render the Expense List screen. Full details live in
/// [ExpenseDetailResponse], fetched separately per-expense-type.
///
/// Expenses is a configuration screen: it defines the *types* of
/// expenses available (and which branch(es) each applies to), not
/// individual expense transactions — so this deliberately carries no
/// amount, category, or attachment.
class ExpenseListItem {
  final int id;
  final String name;
  final String description;

  /// True when this expense type applies to every branch. When false,
  /// [branchNames] lists which specific branches it applies to.
  final bool allBranches;
  final List<String> branchNames;

  final String status;

  bool get isActive => status.toLowerCase() == 'active';

  ExpenseListItem({
    required this.id,
    required this.name,
    required this.description,
    required this.allBranches,
    required this.branchNames,
    required this.status,
  });

  factory ExpenseListItem.fromJson(Map<String, dynamic> json) {
    return ExpenseListItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      allBranches: json['all_branches'] ?? true,
      branchNames: (json['branches'] as List? ?? [])
          .map((e) => (e['name'] ?? '').toString())
          .toList(),
      status: json['status'] ?? '',
    );
  }
}
