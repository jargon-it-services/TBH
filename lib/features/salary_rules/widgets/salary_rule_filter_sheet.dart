import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Selected filter values for the Salary Rule List screen. All fields
/// are single-select and optional — `null` means "any".
class SalaryRuleFilter {
  final String? salaryType;
  final String? status;

  const SalaryRuleFilter({this.salaryType, this.status});

  bool get isEmpty => salaryType == null && status == null;

  int get activeCount => [salaryType, status].where((v) => v != null && v.isNotEmpty).length;

  SalaryRuleFilter copyWith({
    String? salaryType,
    bool clearSalaryType = false,
    String? status,
    bool clearStatus = false,
  }) {
    return SalaryRuleFilter(
      salaryType: clearSalaryType ? null : (salaryType ?? this.salaryType),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

/// Bottom sheet used by `SalaryRuleListPage`'s Filter button. Options
/// are derived from the rules actually loaded, same as
/// `ExpenseFilterSheet`.
class SalaryRuleFilterSheet extends StatefulWidget {
  const SalaryRuleFilterSheet({
    super.key,
    required this.current,
    required this.salaryTypes,
    required this.statuses,
  });

  final SalaryRuleFilter current;
  final List<String> salaryTypes;
  final List<String> statuses;

  static Future<SalaryRuleFilter?> show(
    BuildContext context, {
    required SalaryRuleFilter current,
    required List<String> salaryTypes,
    required List<String> statuses,
  }) {
    return showModalBottomSheet<SalaryRuleFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SalaryRuleFilterSheet(
        current: current,
        salaryTypes: salaryTypes,
        statuses: statuses,
      ),
    );
  }

  @override
  State<SalaryRuleFilterSheet> createState() => _SalaryRuleFilterSheetState();
}

class _SalaryRuleFilterSheetState extends State<SalaryRuleFilterSheet> {
  late SalaryRuleFilter _filter = widget.current;

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
                  Text('Filter Salary Rules', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _filter = const SalaryRuleFilter()),
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
                      'Salary Type',
                      widget.salaryTypes,
                      _filter.salaryType,
                      (v) => setState(() => _filter = _filter.copyWith(
                            salaryType: v,
                            clearSalaryType: v == null,
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
