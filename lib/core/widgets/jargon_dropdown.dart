import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class JargonDropdown extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<String> options;
  final ValueChanged<String>? onChanged;

  /// 🔥 NEW – UI controls
  final bool showCard;
  final bool showIconBackground;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  /// 🔥 NEW – controls whether the small label above the value is shown.
  /// Defaults to false (hidden).
  final bool showLabel;

  const JargonDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.options,
    this.onChanged,
    this.showCard = true,
    this.showIconBackground = true,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.showLabel = false,
  });

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.4,
          maxChildSize: 0.8,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.page),
              decoration: const BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.large),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.circle),
                      ),
                    ),
                  ),
                  Text("Select Option", style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: options.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.verticalSmall),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option == value;

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            onChanged?.call(option);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondary.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.medium),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.secondary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.secondary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: AppColors.secondary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: () => _showOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: showCard
            ? BoxDecoration(
                color: backgroundColor ?? AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: borderColor ?? AppColors.border),
                boxShadow: boxShadow ??
                    [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
              )
            : null,
        child: Row(
          children: [
            /// ICON
            showIconBackground
                ? Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 20),
                  )
                : Icon(icon, color: AppColors.primary, size: 25),

            const SizedBox(width: 12),

            /// LABEL + VALUE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLabel) ...[
                    Text(
                      label,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    value,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary, size: 26),
          ],
        ),
      ),
    );
  }
}
