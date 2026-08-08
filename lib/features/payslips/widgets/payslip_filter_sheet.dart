import 'package:flutter/material.dart';

import '../../../core/services/DataModels/payslip_list_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Selected filter values for the Payslip List screen — currently just
/// Month/Year (§1.3 of the module spec: branch and status already have
/// their own dedicated controls, so this sheet only owns the one
/// leftover filter). `null` means "any".
class PayslipFilter {
  final int? month;
  final int? year;

  const PayslipFilter({this.month, this.year});

  bool get isEmpty => month == null && year == null;

  int get activeCount => (month != null && year != null) ? 1 : 0;

  PayslipFilter copyWith({int? month, int? year}) {
    return PayslipFilter(month: month, year: year);
  }
}

/// A single selectable Month/Year option, e.g. "January 2026".
class _MonthYearOption {
  final int month;
  final int year;
  final String label;

  _MonthYearOption(this.month, this.year, this.label);
}

/// Bottom sheet used by `PayslipListPage`'s Filter button. Options are
/// derived from the payslips actually loaded, same approach as
/// `SalaryRuleFilterSheet`/`ExpenseFilterSheet`.
class PayslipFilterSheet extends StatefulWidget {
  const PayslipFilterSheet({
    super.key,
    required this.current,
    required this.payslips,
  });

  final PayslipFilter current;
  final List<PayslipListItem> payslips;

  static Future<PayslipFilter?> show(
    BuildContext context, {
    required PayslipFilter current,
    required List<PayslipListItem> payslips,
  }) {
    return showModalBottomSheet<PayslipFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayslipFilterSheet(current: current, payslips: payslips),
    );
  }

  @override
  State<PayslipFilterSheet> createState() => _PayslipFilterSheetState();
}

class _PayslipFilterSheetState extends State<PayslipFilterSheet> {
  late PayslipFilter _filter = widget.current;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<_MonthYearOption> get _options {
    final seen = <String>{};
    final options = <_MonthYearOption>[];
    for (final p in widget.payslips) {
      final key = '${p.year}-${p.month}';
      if (seen.add(key)) {
        options.add(_MonthYearOption(p.month, p.year, '${_monthNames[p.month - 1]} ${p.year}'));
      }
    }
    options.sort((a, b) {
      if (a.year != b.year) return b.year.compareTo(a.year);
      return b.month.compareTo(a.month);
    });
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final options = _options;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
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
                  Text('Filter by Month / Year', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _filter = const PayslipFilter()),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: options.isEmpty
                    ? Center(
                        child: Text(
                          'No payslips to filter yet',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView(
                        controller: scrollController,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: options.map((option) {
                              final isSelected =
                                  _filter.month == option.month && _filter.year == option.year;
                              return GestureDetector(
                                onTap: () => setState(() {
                                  _filter = isSelected
                                      ? const PayslipFilter()
                                      : PayslipFilter(month: option.month, year: option.year);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    option.label,
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
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                  ),
                  onPressed: () => Navigator.pop(context, _filter),
                  child: const Text('Apply Filter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
