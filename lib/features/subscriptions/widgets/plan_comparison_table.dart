import 'package:flutter/material.dart';

import '../../../core/services/DataModels/subscription_models.dart';
import '../../../core/theme/app_fonts.dart';
import '../subscription_tokens.dart';
import 'subscription_feature_rows.dart';

/// Full side-by-side comparison across every catalog plan. Per spec:
/// entirely hidden when the account is locked/suspended, replaced by
/// [PlanComparisonLockedNotice] instead -- never rendered blurred,
/// unlike the individual plan cards.
///
/// With 4 plans at a readable column width, this table is almost
/// always wider than the screen, so it needs an explicit "there's more
/// to scroll" affordance -- a persistent hint above it, plus fading
/// edges that track real scroll position (the right fade disappears
/// once you've actually reached the last column; a left fade appears
/// once you've scrolled away from the first).
class PlanComparisonTable extends StatefulWidget {
  final List<PlanCatalogItem> plans;

  const PlanComparisonTable({super.key, required this.plans});

  @override
  State<PlanComparisonTable> createState() => _PlanComparisonTableState();
}

class _PlanComparisonTableState extends State<PlanComparisonTable> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFadeVisibility);
    // Column widths aren't known until after the first layout pass, so
    // check again once it's actually happened rather than only at
    // initState (where hasClients/maxScrollExtent would still be 0).
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFadeVisibility());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateFadeVisibility);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateFadeVisibility() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canScrollRight = position.pixels < position.maxScrollExtent - 1;
    final canScrollLeft = position.pixels > 1;
    if (canScrollRight != _canScrollRight || canScrollLeft != _canScrollLeft) {
      setState(() {
        _canScrollRight = canScrollRight;
        _canScrollLeft = canScrollLeft;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = widget.plans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.swap_horiz_rounded, size: 15, color: SubscriptionTokens.sub),
            const SizedBox(width: 6),
            Text(
              'Swipe to compare all ${plans.length} plans',
              style: AppTextStyles.caption.copyWith(color: SubscriptionTokens.sub),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: SubscriptionTokens.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: const FixedColumnWidth(160),
                    for (var i = 0; i < plans.length; i++)
                      i + 1: const FixedColumnWidth(110),
                  },
                  children: [
                    _headerRow(plans),
                    for (final row in subscriptionFeatureRows) _featureRow(row, plans),
                  ],
                ),
              ),
              if (_canScrollLeft) _edgeFade(alignLeft: true),
              if (_canScrollRight) _edgeFade(alignLeft: false),
            ],
          ),
        ),
      ],
    );
  }

  /// A ~24px gradient fading from opaque white (matching the table's
  /// own background) to transparent, overlaid on whichever edge still
  /// has unscrolled content -- the standard "there's more this way"
  /// affordance. `IgnorePointer`'d so it never blocks the scroll
  /// gesture underneath it.
  Widget _edgeFade({required bool alignLeft}) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: alignLeft ? 0 : null,
      right: alignLeft ? null : 0,
      width: 24,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: alignLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [Colors.white, Colors.white.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }

  TableRow _headerRow(List<PlanCatalogItem> plans) {
    return TableRow(
      decoration: BoxDecoration(color: SubscriptionTokens.surface),
      children: [
        const Padding(
          padding: EdgeInsets.all(AppSpacing.horizontalMedium),
          child: SizedBox.shrink(),
        ),
        for (final plan in plans)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.verticalSmall,
              horizontal: 8,
            ),
            child: Text(
              plan.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: SubscriptionTokens.ink,
              ),
            ),
          ),
      ],
    );
  }

  TableRow _featureRow(SubscriptionFeatureRow row, List<PlanCatalogItem> plans) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SubscriptionTokens.line)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.horizontalMedium),
          child: Text(
            row.label,
            style: AppTextStyles.bodySmall.copyWith(color: SubscriptionTokens.sub),
          ),
        ),
        for (final plan in plans) _cellFor(row, plan),
      ],
    );
  }

  Widget _cellFor(SubscriptionFeatureRow row, PlanCatalogItem plan) {
    final value = row.valueOf(plan);
    final isLimit = row.type == SubscriptionFeatureRowType.limit;
    final boolValue = isLimit ? false : value as bool;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: isLimit
            ? Text(
                formatFeatureLimit(value as int?),
                style: AppTextStyles.bodySmall.copyWith(color: SubscriptionTokens.ink),
              )
            : Icon(
                boolValue ? Icons.check_circle : Icons.remove_circle_outline,
                size: 18,
                color: boolValue
                    ? SubscriptionTokens.success
                    : SubscriptionTokens.sub.withOpacity(0.4),
              ),
      ),
    );
  }
}

/// Replaces [PlanComparisonTable] entirely when the account is
/// suspended -- a one-line notice rather than the table.
class PlanComparisonLockedNotice extends StatelessWidget {
  const PlanComparisonLockedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: SubscriptionTokens.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: SubscriptionTokens.line),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: SubscriptionTokens.sub),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Plan comparison is hidden while this account is suspended.',
              style: AppTextStyles.bodySmall.copyWith(color: SubscriptionTokens.sub),
            ),
          ),
        ],
      ),
    );
  }
}
