import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Selected filter values for the Service List screen. All fields are
/// single-select and optional — `null` means "any". Mirrors
/// `BranchFilter`'s shape exactly.
class ServiceFilter {
  final String? category;
  final String? applicableGender;
  final String? status;

  const ServiceFilter({this.category, this.applicableGender, this.status});

  bool get isEmpty =>
      category == null && applicableGender == null && status == null;

  int get activeCount => [category, applicableGender, status]
      .where((v) => v != null && v.isNotEmpty)
      .length;

  ServiceFilter copyWith({
    String? category,
    bool clearCategory = false,
    String? applicableGender,
    bool clearApplicableGender = false,
    String? status,
    bool clearStatus = false,
  }) {
    return ServiceFilter(
      category: clearCategory ? null : (category ?? this.category),
      applicableGender: clearApplicableGender
          ? null
          : (applicableGender ?? this.applicableGender),
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

/// Bottom sheet used by `ServiceListPage`'s Filter button. Options for
/// each field are derived from the services actually loaded, same as
/// `BranchFilterSheet`, so the sheet never offers a category/gender/
/// status with zero matching results.
class ServiceFilterSheet extends StatefulWidget {
  const ServiceFilterSheet({
    super.key,
    required this.current,
    required this.categories,
    required this.genders,
    required this.statuses,
  });

  final ServiceFilter current;
  final List<String> categories;
  final List<String> genders;
  final List<String> statuses;

  static Future<ServiceFilter?> show(
    BuildContext context, {
    required ServiceFilter current,
    required List<String> categories,
    required List<String> genders,
    required List<String> statuses,
  }) {
    return showModalBottomSheet<ServiceFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ServiceFilterSheet(
        current: current,
        categories: categories,
        genders: genders,
        statuses: statuses,
      ),
    );
  }

  @override
  State<ServiceFilterSheet> createState() => _ServiceFilterSheetState();
}

class _ServiceFilterSheetState extends State<ServiceFilterSheet> {
  late ServiceFilter _filter = widget.current;

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
                  Text('Filter Services', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        setState(() => _filter = const ServiceFilter()),
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
                      'Category',
                      widget.categories,
                      _filter.category,
                      (v) => setState(() => _filter = _filter.copyWith(
                            category: v,
                            clearCategory: v == null,
                          )),
                    ),
                    _section(
                      'Applicable Gender',
                      widget.genders,
                      _filter.applicableGender,
                      (v) => setState(() => _filter = _filter.copyWith(
                            applicableGender: v,
                            clearApplicableGender: v == null,
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
          Text(label,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.verticalSmall),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selected == option;
              return GestureDetector(
                onTap: () => onSelected(isSelected ? null : option),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
