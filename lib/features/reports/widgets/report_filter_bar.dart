import 'package:flutter/material.dart';

import '../../../core/services/DataModels/pnl_report_model.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/jargon_dropdown.dart';
import 'report_segment_selector.dart';

/// The filter row every report screen (PnL, Payment Mode, Revenue &
/// Expense) opens with: the segment toggle, the branch selector below
/// it, and — only while a custom range is active — a small label
/// showing which dates are in effect.
///
/// This exists because that combination was duplicated near-verbatim
/// across all three report pages' `_body()` methods, including the
/// branch-name-to-id lookup each page repeated in its own
/// `_handleBranchChange` wrapper. Centralizing it here means a future
/// fourth report gets this filter bar with one widget call instead of
/// copying ~20 lines and a lookup method again — and any future tweak
/// (spacing, a new filter, another selector bugfix) needs making once.
///
/// [onBranchChanged] receives the resolved branch **id** directly (not
/// the display name `JargonDropdown` works in) — the name-to-id lookup
/// happens inside this widget, against [branches], so callers can wire
/// it straight to `ReportPageState.handleBranchChange`.
///
/// [showBranchSelector] defaults to `true` for the three per-branch
/// reports above. Branch Performance Breakdown is the exception — it
/// *compares* branches, so filtering down to one would defeat the
/// report's purpose — and sets this `false` to get the segment toggle
/// and custom-range label without the dropdown, rather than reaching
/// for `ReportSegmentSelector` on its own.
class ReportFilterBar extends StatelessWidget {
  final List<PnlPeriodOption> periods;
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  final List<PnlBranchOption> branches;
  final String selectedBranchId;
  final ValueChanged<String>? onBranchChanged;
  final bool showBranchSelector;

  /// Formatted "12 Mar 2026 — 18 Jun 2026" label, or empty/null when no
  /// custom range is set. Only shown when [selectedPeriod] is
  /// `'custom'` *and* this is non-empty.
  final String? customRangeLabel;

  const ReportFilterBar({
    super.key,
    required this.periods,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    this.branches = const [],
    this.selectedBranchId = 'all',
    this.onBranchChanged,
    this.customRangeLabel,
    this.showBranchSelector = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBranchName = branches
        .firstWhere(
          (b) => b.id == selectedBranchId,
          orElse: () => const PnlBranchOption(id: 'all', name: 'All Branches'),
        )
        .name;

    final showCustomRangeLabel =
        selectedPeriod == 'custom' && (customRangeLabel?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ReportSegmentSelector(
          periods: periods,
          selectedKey: selectedPeriod,
          onChanged: onPeriodChanged,
        ),
        if (showBranchSelector) ...[
          const SizedBox(height: AppSpacing.verticalSmall),
          JargonDropdown(
            label: 'Branch',
            value: selectedBranchName,
            icon: Icons.storefront_outlined,
            options: branches.map((b) => b.name).toList(),
            onChanged: (name) {
              final match = branches.where((b) => b.name == name);
              onBranchChanged?.call(match.isNotEmpty ? match.first.id : 'all');
            },
            showIconBackground: false,
            showLabel: false,
          ),
        ],
        if (showCustomRangeLabel) ...[
          const SizedBox(height: AppSpacing.verticalSmall),
          Text(
            'Showing data for $customRangeLabel',
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }
}
