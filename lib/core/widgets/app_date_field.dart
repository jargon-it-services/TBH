import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Tap-to-open date field — the date-picking counterpart to
/// [JargonDropdown] (same filled/labeled field shell as [AppTextField],
/// so it drops into a [Form] alongside it, but opens the platform
/// [showDatePicker] instead of taking keyboard input).
///
/// No date field previously existed anywhere in this app (Registration
/// collects no dates). Built here, in `core/widgets`, so Staff's
/// Joining Date and any future date field share one implementation
/// instead of another bespoke copy — same reasoning that put
/// `MultiSelectField` in `core/widgets` for the Service module.
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.validator,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final IconData icon;

  /// Currently selected date, or null when nothing's picked yet.
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  /// Wraps the picked date the same way [AppTextField]'s `validator`
  /// does, so this can sit inside the same [Form] and get validated by
  /// the same `_formKey.currentState.validate()` call — the value
  /// handed to it is the formatted display string (or empty when
  /// unset), matching [String? Function(String?)].
  final String? Function(String?)? validator;

  final DateTime? firstDate;
  final DateTime? lastDate;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _format(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';

  Future<void> _pick(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - 60),
      lastDate: lastDate ?? DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: FormField<String>(
        initialValue: value != null ? _format(value!) : '',
        validator: validator,
        builder: (state) {
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            onTap: () async {
              await _pick(context);
              state.didChange(value != null ? _format(value!) : '');
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: state.hasError
                    ? Border.all(color: AppColors.error, width: 1.2)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: AppIcons.defaultSize, color: Colors.grey.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value != null ? _format(value!) : label,
                      style: AppTextStyles.body.copyWith(
                        color: value != null
                            ? AppColors.textPrimary
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today_outlined,
                      color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
