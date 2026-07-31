import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Card-style search field — white background, soft shadow, rounded
/// border, leading search icon, clear (x) button once there's text.
///
/// Extracted from `PaymentHistoryPage._searchBar()` (previously
/// duplicated by hand wherever a screen wanted this exact look) so
/// every list screen that wants the "Payment History search UI" —
/// Branch List included — shares one implementation instead of
/// copy-pasting the `Container`/`TextField`/decoration each time.
/// Purely local/instant filtering is still each screen's own
/// responsibility via [onChanged]; this widget owns only the look and
/// the clear-button affordance.
class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  /// Optional trailing widget shown after the clear button — e.g. a
  /// Filter icon button. Kept outside the text field's own suffixIcon
  /// so the clear button and this can coexist without fighting over
  /// the same slot.
  final Widget? trailing;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.hintText = "Search",
    this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              // Purely local filtering -- no API call while typing, so
              // this needs no debounce, matching Payment History /
              // Transactions' identical local-search boxes.
              onChanged: onChanged,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodySmall,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          controller.clear();
                          onChanged?.call('');
                        },
                      ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.horizontalSmall),
          trailing!,
        ],
      ],
    );
  }
}
