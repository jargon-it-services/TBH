import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Selected filter values for the Staff List screen. All fields are
/// single-select and optional — `null` means "any". Mirrors
/// `ServiceFilter`'s shape exactly.
class StaffFilter {
  final String? designation;
  final String? branchName;
  final String? status;

  const StaffFilter({this.designation, this.branchName, this.status});

  bool get isEmpty => designation == null && branchName == null && status == null;

  int get activeCount =>
      [designation, branchName, status].where((v) => v != null && v.isNotEmpty).length;

  StaffFilter copyWith({
    String? designation,
    bool clearDesignation = false,
    String? branchName,
    bool clearBranchName = false,
    String? status,
    bool clearStatus = false,
  }) {
    return StaffFilter(
      designation: clearDesignation ? null : (designation ?? this.designation),
      branchName: clearBranchName ? null : (branchName ?? this.branchName),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

/// Bottom sheet used by `StaffListPage`'s Filter button. Options for
/// each field are derived from the staff actually loaded, same as
/// `ServiceFilterSheet`, so the sheet never offers a designation/
/// branch/status with zero matching results.
class StaffFilterSheet extends StatefulWidget {
  const StaffFilterSheet({
    super.key,
    required this.current,
    required this.designations,
    required this.branchNames,
    required this.statuses,
  });

  final StaffFilter current;
  final List<String> designations;
  final List<String> branchNames;
  final List<String> statuses;

  static Future<StaffFilter?> show(
    BuildContext context, {
    required StaffFilter current,
    required List<String> designations,
    required List<String> branchNames,
    required List<String> statuses,
  }) {
    return showModalBottomSheet<StaffFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StaffFilterSheet(
        current: current,
        designations: designations,
        branchNames: branchNames,
        statuses: statuses,
      ),
    );
  }

  @override
  State<StaffFilterSheet> createState() => _StaffFilterSheetState();
}

class _StaffFilterSheetState extends State<StaffFilterSheet> {
  late StaffFilter _filter = widget.current;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                  Text('Filter Staff', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _filter = const StaffFilter()),
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
                      'Designation',
                      widget.designations,
                      _filter.designation,
                      (v) => setState(() => _filter = _filter.copyWith(
                            designation: v,
                            clearDesignation: v == null,
                          )),
                    ),
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
