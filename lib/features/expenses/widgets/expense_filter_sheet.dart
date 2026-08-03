import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Selected filter values for the Expense List screen. Both fields are
/// single-select and optional — `null` means "any". Category was
/// dropped along with the rest of the transaction-style fields;
/// Expenses is now a configuration screen (Name/Description/Branch
/// Assignment only), so Branch and Status are all that's left to
/// filter by.
class ExpenseFilter {
  final String? branchName;
  final String? status;

  const ExpenseFilter({this.branchName, this.status});

  bool get isEmpty => branchName == null && status == null;

  int get activeCount => [branchName, status].where((v) => v != null && v.isNotEmpty).length;

  ExpenseFilter copyWith({
    String? branchName,
    bool clearBranchName = false,
    String? status,
    bool clearStatus = false,
  }) {
    return ExpenseFilter(
      branchName: clearBranchName ? null : (branchName ?? this.branchName),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

/// Bottom sheet used by `ExpenseListPage`'s Filter button. Options are
/// derived from the expenses actually loaded, same as
/// `ServiceFilterSheet`. "Branch" here filters expenses whose scope
/// includes the given branch (either assigned directly, or via "All
/// Branches") — see `ExpenseListPage._applyFilters`.
class ExpenseFilterSheet extends StatefulWidget {
  const ExpenseFilterSheet({
    super.key,
    required this.current,
    required this.branchNames,
    required this.statuses,
  });

  final ExpenseFilter current;
  final List<String> branchNames;
  final List<String> statuses;

  static Future<ExpenseFilter?> show(
    BuildContext context, {
    required ExpenseFilter current,
    required List<String> branchNames,
    required List<String> statuses,
  }) {
    return showModalBottomSheet<ExpenseFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExpenseFilterSheet(
        current: current,
        branchNames: branchNames,
        statuses: statuses,
      ),
    );
  }

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  late ExpenseFilter _filter = widget.current;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Filter Expenses', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _filter = const ExpenseFilter()),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _section(
                      'Branch',
                      widget.branchNames,
                      _filter.branchName,
                      (v) => setState(() => _filter = _filter.copyWith(
                            branchName: v,
                            clearBranchName: v == null,
                          )),
                    ),
                    _section(
                      'Status',
                      widget.statuses,
                      _filter.status,
                      (v) => setState(() => _filter = _filter.copyWith(
                            status: v,
                            clearStatus: v == null,
                          )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, _filter),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(
    String label,
    List<String> options,
    String? selected,
    ValueChanged<String?> onSelected,
  ) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.verticalSmall),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected == option;
              return GestureDetector(
                onTap: () => onSelected(isSelected ? null : option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    option,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.primary,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
