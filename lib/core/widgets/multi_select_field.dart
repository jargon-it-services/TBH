import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// A single selectable option for [MultiSelectField].
class MultiSelectOption {
  final int id;
  final String label;

  const MultiSelectOption({required this.id, required this.label});
}

/// Tap-to-open multi-select field — the multi-select counterpart to
/// [JargonDropdown] (same bottom-sheet shell: drag handle, title,
/// scrollable option list), generalized for picking any number of
/// options instead of exactly one.
///
/// No multi-select component previously existed anywhere in this app
/// (Branch's Weekly Off picker is the closest precedent, but it's a
/// feature-local `Wrap` of chips, not a shared widget). This lives in
/// `core/widgets` from the start so the first screen that needs a
/// multi-select — Service's Branch Assignment — and any future one
/// share a single implementation instead of another bespoke copy.
class MultiSelectField extends StatelessWidget {
  const MultiSelectField({
    super.key,
    required this.label,
    required this.icon,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
    this.emptyHint = 'Tap to select',
    this.sheetTitle,
  });

  final String label;
  final IconData icon;
  final List<MultiSelectOption> options;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;

  /// Shown as the field's value text when nothing is selected yet.
  final String emptyHint;

  /// Title shown atop the bottom sheet. Defaults to [label].
  final String? sheetTitle;

  String get _valueText {
    if (selectedIds.isEmpty) return emptyHint;
    final names = options
        .where((o) => selectedIds.contains(o.id))
        .map((o) => o.label)
        .toList();
    return names.join(', ');
  }

  Future<void> _openSheet(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<Set<int>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MultiSelectBottomSheet(
        title: sheetTitle ?? label,
        options: options,
        initiallySelected: selectedIds,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIds.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _valueText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasSelection
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
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

class _MultiSelectBottomSheet extends StatefulWidget {
  final String title;
  final List<MultiSelectOption> options;
  final Set<int> initiallySelected;

  const _MultiSelectBottomSheet({
    required this.title,
    required this.options,
    required this.initiallySelected,
  });

  @override
  State<_MultiSelectBottomSheet> createState() =>
      _MultiSelectBottomSheetState();
}

class _MultiSelectBottomSheetState extends State<_MultiSelectBottomSheet> {
  late Set<int> _selected = {...widget.initiallySelected};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
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
                  Expanded(child: Text(widget.title, style: AppTextStyles.h3)),
                  TextButton(
                    onPressed: () => setState(() => _selected.clear()),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: widget.options.isEmpty
                    ? Center(
                        child: Text(
                          'No options available',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: widget.options.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.verticalSmall),
                        itemBuilder: (context, index) {
                          final option = widget.options[index];
                          final isSelected = _selected.contains(option.id);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (isSelected) {
                                _selected.remove(option.id);
                              } else {
                                _selected.add(option.id);
                              }
                            }),
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
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      option.label,
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
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? AppColors.secondary
                                        : AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                  onPressed: () => Navigator.pop(context, _selected),
                  child: Text(
                    _selected.isEmpty
                        ? 'Done'
                        : 'Apply (${_selected.length} selected)',
                    style: const TextStyle(
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
}
