import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/app_snackbar.dart';

/// A tap-to-open, searchable list picker — visually identical to
/// AppTextField (same fill color, radius, icon) so it doesn't
/// stand out the way a white-card JargonDropdown would in the middle of
/// a form full of grey-filled text fields. Built as an InkWell, not a
/// TextFormField, so it never triggers the on-screen keyboard.
class SearchableSelectField extends StatelessWidget {
  const SearchableSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onSelected,
    this.enabled = true,
    this.loading = false,
    this.disabledHint,
    this.errorText,
    this.failed = false,
    this.onRetry,
    this.failedMessage,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final bool loading;
  final String? disabledHint;
  final String? errorText;

  /// True when the last fetch for `options` failed (network/API error) —
  /// distinct from "fetch succeeded but returned nothing". Shows a retry
  /// affordance instead of a silent empty list.
  final bool failed;
  final VoidCallback? onRetry;

  /// Optional override for the failed-state message (e.g. "You're
  /// offline" vs the generic "Couldn't load $label").
  final String? failedMessage;

  Future<void> _open(BuildContext context) async {
    if (failed) {
      onRetry?.call();
      return;
    }
    if (!enabled) {
      if (disabledHint != null) {
        AppSnackbar.info(context, disabledHint!);
      }
      return;
    }
    if (loading) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _SearchSheet(title: label, options: options, initial: value),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            onTap: () => _open(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: failed
                    ? AppColors.error.withOpacity(0.06)
                    : enabled
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: (errorText != null || failed)
                    ? Border.all(color: AppColors.error, width: 1.2)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    failed ? Icons.wifi_off_rounded : icon,
                    size: AppIcons.defaultSize,
                    color: failed
                        ? AppColors.error
                        : enabled
                            ? AppColors.textPrimary
                            : AppColors.textDisabled,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      failed
                          ? (failedMessage ??
                              "Couldn't load $label — tap to retry")
                          : (hasValue ? value! : label),
                      style: AppTextStyles.body.copyWith(
                        color: failed
                            ? AppColors.error
                            : hasValue
                                ? AppColors.textPrimary
                                : Colors.grey,
                        fontWeight: failed ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (failed)
                    const Icon(Icons.refresh_rounded, color: AppColors.error)
                  else
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: enabled
                          ? AppColors.textSecondary
                          : AppColors.textDisabled,
                    ),
                ],
              ),
            ),
          ),
          if (errorText != null && !failed)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 13, color: AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    errorText!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({
    required this.title,
    required this.options,
    this.initial,
  });

  final String title;
  final List<String> options;
  final String? initial;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late List<String> _filtered = widget.options;
  final _searchController = TextEditingController();

  void _filter(String query) {
    setState(() {
      _filtered = widget.options
          .where((o) => o.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.page),
          decoration: const BoxDecoration(
            color: AppColors.pageBackground,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
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
              Text('Select ${widget.title}', style: AppTextStyles.h3),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.primary.withOpacity(0.1),
                  prefixIcon:
                      const Icon(Icons.search, size: AppIcons.defaultSize),
                  hintText: 'Search ${widget.title}',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text('No matches found',
                            style: AppTextStyles.bodySmall),
                      )
                    : ListView.separated(
                        controller: controller,
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.verticalSmall),
                        itemBuilder: (context, index) {
                          final option = _filtered[index];
                          final isSelected = option == widget.initial;
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, option),
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
  }
}
