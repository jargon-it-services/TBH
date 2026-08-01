import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Pill-style segmented toggle — same visual design as the
/// Subscriptions page's Monthly/Annual `BillingCycleToggle` (rounded
/// outer pill, 4px padding, an `AnimatedContainer` filled-primary pill
/// sliding onto whichever segment is selected), generalized here for
/// any list of string options instead of being hardcoded to two
/// billing cycles. `BillingCycleToggle` itself is untouched — it also
/// carries a per-segment discount badge Branch Type has no equivalent
/// of, so it wasn't worth collapsing the two into one, but any other
/// screen wanting this exact toggle look should reach for this widget
/// instead of another bespoke copy.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: options
            .map(
              (option) => Expanded(
                child: _segment(
                  label: option,
                  selected: option == value,
                  onTap: () => onChanged(option),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
