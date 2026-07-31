import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Selected filter values for the Branch List screen. All fields are
/// single-select and optional — `null` means "any".
class BranchFilter {
  final String? branchType;
  final String? status;
  final String? city;
  final String? state;

  const BranchFilter({this.branchType, this.status, this.city, this.state});

  bool get isEmpty =>
      branchType == null && status == null && city == null && state == null;

  int get activeCount => [branchType, status, city, state]
      .where((v) => v != null && v.isNotEmpty)
      .length;

  BranchFilter copyWith({
    String? branchType,
    bool clearBranchType = false,
    String? status,
    bool clearStatus = false,
    String? city,
    bool clearCity = false,
    String? state,
    bool clearState = false,
  }) {
    return BranchFilter(
      branchType: clearBranchType ? null : (branchType ?? this.branchType),
      status: clearStatus ? null : (status ?? this.status),
      city: clearCity ? null : (city ?? this.city),
      state: clearState ? null : (state ?? this.state),
    );
  }
}

/// Bottom sheet used by [BranchListPage]'s Filter button. Options for
/// each field are derived from the branches actually loaded (so the
/// sheet never offers a city/state/type with zero matching results).
class BranchFilterSheet extends StatefulWidget {
  const BranchFilterSheet({
    super.key,
    required this.current,
    required this.branchTypes,
    required this.statuses,
    required this.cities,
    required this.states,
  });

  final BranchFilter current;
  final List<String> branchTypes;
  final List<String> statuses;
  final List<String> cities;
  final List<String> states;

  static Future<BranchFilter?> show(
    BuildContext context, {
    required BranchFilter current,
    required List<String> branchTypes,
    required List<String> statuses,
    required List<String> cities,
    required List<String> states,
  }) {
    return showModalBottomSheet<BranchFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BranchFilterSheet(
        current: current,
        branchTypes: branchTypes,
        statuses: statuses,
        cities: cities,
        states: states,
      ),
    );
  }

  @override
  State<BranchFilterSheet> createState() => _BranchFilterSheetState();
}

class _BranchFilterSheetState extends State<BranchFilterSheet> {
  late BranchFilter _filter = widget.current;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
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
                  Text('Filter Branches', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _filter = const BranchFilter()),
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
                      'Branch Type',
                      widget.branchTypes,
                      _filter.branchType,
                      (v) => setState(() => _filter = _filter.copyWith(
                            branchType: v,
                            clearBranchType: v == null,
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
                    _section(
                      'City',
                      widget.cities,
                      _filter.city,
                      (v) => setState(() => _filter = _filter.copyWith(
                            city: v,
                            clearCity: v == null,
                          )),
                    ),
                    _section(
                      'State',
                      widget.states,
                      _filter.state,
                      (v) => setState(() => _filter = _filter.copyWith(
                            state: v,
                            clearState: v == null,
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
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
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
