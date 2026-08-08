import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Selected filter values for the Transaction List screen. All fields
/// are single-select and optional — `null` means "any". Mirrors
/// `SalaryRuleFilter`'s shape exactly.
class TransactionFilter {
  final String? status;
  final String? paymentMode;
  final String? type;

  const TransactionFilter({this.status, this.paymentMode, this.type});

  bool get isEmpty => status == null && paymentMode == null && type == null;

  int get activeCount =>
      [status, paymentMode, type].where((v) => v != null && v.isNotEmpty).length;

  TransactionFilter copyWith({
    String? status,
    bool clearStatus = false,
    String? paymentMode,
    bool clearPaymentMode = false,
    String? type,
    bool clearType = false,
  }) {
    return TransactionFilter(
      status: clearStatus ? null : (status ?? this.status),
      paymentMode: clearPaymentMode ? null : (paymentMode ?? this.paymentMode),
      type: clearType ? null : (type ?? this.type),
    );
  }
}

/// Bottom sheet used by `TransactionsPage`'s Filter button. Same shell,
/// same "Reset" + "Apply Filters" flow as `SalaryRuleFilterSheet`.
class TransactionFilterSheet extends StatefulWidget {
  const TransactionFilterSheet({
    super.key,
    required this.current,
    required this.statuses,
    required this.paymentModes,
    required this.types,
  });

  final TransactionFilter current;
  final List<String> statuses;
  final List<String> paymentModes;
  final List<String> types;

  static Future<TransactionFilter?> show(
    BuildContext context, {
    required TransactionFilter current,
    required List<String> statuses,
    required List<String> paymentModes,
    required List<String> types,
  }) {
    return showModalBottomSheet<TransactionFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionFilterSheet(
        current: current,
        statuses: statuses,
        paymentModes: paymentModes,
        types: types,
      ),
    );
  }

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late TransactionFilter _filter = widget.current;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
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
                  Text('Filter Transactions', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _filter = const TransactionFilter()),
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
                      'Status',
                      widget.statuses,
                      _filter.status,
                      (v) => setState(() => _filter = _filter.copyWith(
                            status: v,
                            clearStatus: v == null,
                          )),
                    ),
                    _section(
                      'Payment Mode',
                      widget.paymentModes,
                      _filter.paymentMode,
                      (v) => setState(() => _filter = _filter.copyWith(
                            paymentMode: v,
                            clearPaymentMode: v == null,
                          )),
                    ),
                    _section(
                      'Type',
                      widget.types,
                      _filter.type,
                      (v) => setState(() => _filter = _filter.copyWith(
                            type: v,
                            clearType: v == null,
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
                    // Capitalize each option for display only — the
                    // underlying value (used for matching) is untouched.
                    option.isEmpty
                        ? option
                        : option[0].toUpperCase() + option.substring(1),
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
