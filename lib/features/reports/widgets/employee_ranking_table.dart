import 'package:flutter/material.dart';

import '../../../core/services/DataModels/employee_performance_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/InitialsAvatar.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/card_wrapper.dart';

enum _SortKey { name, branch, revenue, services, expenses, profit, commission }

/// "Employee Ranking" — every employee for the selected period/branch
/// as a sortable, searchable table (deliberately no chart here, unlike
/// `BranchComparisonChart` elsewhere in this feature — the brief for
/// this card is a data table, not a visualization).
///
/// The Employee column stays fixed on the left while the rest of the
/// columns (Branch / Revenue / Services / Expenses / Profit /
/// Commission) scroll horizontally as one unit underneath it — plain
/// `Row` + `SingleChildScrollView(scrollDirection: horizontal)`, both
/// halves living inside the page's own outer vertical scroll (no
/// nested vertical scrollable, no `ScrollController` syncing hack).
/// Search and sort are local/instant, same pattern `AppSearchBar`
/// already documents for Payment History / Transactions / Branch List.
class EmployeeRankingTable extends StatefulWidget {
  final EmployeeRankingSection section;
  final String currencySymbol;

  const EmployeeRankingTable({
    super.key,
    required this.section,
    required this.currencySymbol,
  });

  @override
  State<EmployeeRankingTable> createState() => _EmployeeRankingTableState();
}

class _EmployeeRankingTableState extends State<EmployeeRankingTable> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Revenue-highest-first is the natural default for a "ranking" —
  // matches how the API itself pre-sorts `ranking.items[]`.
  _SortKey _sortKey = _SortKey.revenue;
  bool _ascending = false;

  static const double _nameColWidth = 168;
  static const double _branchColWidth = 132;
  static const double _revenueColWidth = 104;
  static const double _servicesColWidth = 92;
  static const double _expensesColWidth = 104;
  static const double _profitColWidth = 96;
  static const double _commissionColWidth = 116;
  static const double _rowHeight = 56;

  static const double _scrollableWidth = _branchColWidth +
      _revenueColWidth +
      _servicesColWidth +
      _expensesColWidth +
      _profitColWidth +
      _commissionColWidth;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EmployeeRankingItem> get _visibleRows {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.section.items
        : widget.section.items
            .where((e) => e.fullName.toLowerCase().contains(query))
            .toList();

    final sorted = [...filtered];
    sorted.sort((a, b) {
      final result = switch (_sortKey) {
        _SortKey.name => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        _SortKey.branch => a.branchName.toLowerCase().compareTo(b.branchName.toLowerCase()),
        _SortKey.revenue => a.revenue.compareTo(b.revenue),
        _SortKey.services => a.servicesServed.compareTo(b.servicesServed),
        _SortKey.expenses => a.expenses.compareTo(b.expenses),
        _SortKey.profit => a.profit.compareTo(b.profit),
        _SortKey.commission => a.commission.compareTo(b.commission),
      };
      return _ascending ? result : -result;
    });
    return sorted;
  }

  void _toggleSort(_SortKey key) {
    setState(() {
      if (_sortKey == key) {
        _ascending = !_ascending;
      } else {
        _sortKey = key;
        // Text columns read naturally starting A→Z; number columns
        // read naturally starting highest→lowest.
        _ascending = key == _SortKey.name || key == _SortKey.branch;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyEmployees = widget.section.items.isNotEmpty;
    final rows = _visibleRows;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.horizontalSmall),
              Expanded(child: Text(widget.section.title, style: AppTextStyles.h3)),
              if (hasAnyEmployees)
                Text(
                  '${widget.section.items.length} employees',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (hasAnyEmployees) ...[
            AppSearchBar(
              controller: _searchController,
              hintText: 'Search employee...',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
          ],
          if (!hasAnyEmployees)
            const SizedBox(
              width: double.infinity,
              child: AnimatedEmptyState(
                icon: Icons.leaderboard_outlined,
                title: 'No Employees Yet',
                message: 'Employee-wise performance will appear here once data is available.',
                height: 160,
              ),
            )
          else if (rows.isEmpty)
            SizedBox(
              width: double.infinity,
              child: AnimatedEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No Matches',
                message: 'No employee matches "${_query.trim()}". Try a different search.',
                height: 140,
              ),
            )
          else ...[
            _table(rows),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.swipe_left_alt_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('Swipe to see more', style: AppTextStyles.caption),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _table(List<EmployeeRankingItem> rows) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: AppColors.divider)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pinned Employee column — stays put while the rest scrolls.
            Container(
              width: _nameColWidth,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.divider, width: 1.2)),
              ),
              child: Column(
                children: [
                  _HeaderCell(
                    label: 'Employee',
                    width: _nameColWidth,
                    alignStart: true,
                    active: _sortKey == _SortKey.name,
                    ascending: _ascending,
                    onTap: () => _toggleSort(_SortKey.name),
                  ),
                  for (int i = 0; i < rows.length; i++)
                    _NameCell(item: rows[i], zebra: i.isOdd),
                ],
              ),
            ),
            // Branch / Revenue / Services / Expenses / Profit / Commission
            // — one horizontally-scrolling unit.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _scrollableWidth,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _HeaderCell(
                            label: 'Branch',
                            width: _branchColWidth,
                            alignStart: true,
                            active: _sortKey == _SortKey.branch,
                            ascending: _ascending,
                            onTap: () => _toggleSort(_SortKey.branch),
                          ),
                          _HeaderCell(
                            label: 'Revenue',
                            width: _revenueColWidth,
                            active: _sortKey == _SortKey.revenue,
                            ascending: _ascending,
                            onTap: () => _toggleSort(_SortKey.revenue),
                          ),
                          _HeaderCell(
                            label: 'Services',
                            width: _servicesColWidth,
                            active: _sortKey == _SortKey.services,
                            ascending: _ascending,
                            onTap: () => _toggleSort(_SortKey.services),
                          ),
                          _HeaderCell(
                            label: 'Expenses',
                            width: _expensesColWidth,
                            active: _sortKey == _SortKey.expenses,
                            ascending: _ascending,
                            onTap: () => _toggleSort(_SortKey.expenses),
                          ),
                          _HeaderCell(
                            label: 'Profit',
                            width: _profitColWidth,
                            active: _sortKey == _SortKey.profit,
                            ascending: _ascending,
                            onTap: () => _toggleSort(_SortKey.profit),
                          ),
                          _HeaderCell(
                            label: 'Commission',
                            width: _commissionColWidth,
                            active: _sortKey == _SortKey.commission,
                            ascending: _ascending,
                            onTap: () => _toggleSort(_SortKey.commission),
                          ),
                        ],
                      ),
                      for (int i = 0; i < rows.length; i++)
                        _DataRow(
                          item: rows[i],
                          currencySymbol: widget.currencySymbol,
                          zebra: i.isOdd,
                          branchColWidth: _branchColWidth,
                          revenueColWidth: _revenueColWidth,
                          servicesColWidth: _servicesColWidth,
                          expensesColWidth: _expensesColWidth,
                          profitColWidth: _profitColWidth,
                          commissionColWidth: _commissionColWidth,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;
  final bool alignStart;
  final bool active;
  final bool ascending;
  final VoidCallback onTap;

  const _HeaderCell({
    required this.label,
    required this.width,
    this.alignStart = false,
    required this.active,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: _EmployeeRankingTableState._rowHeight,
        color: active ? AppColors.primary.withOpacity(0.06) : AppColors.pageBackground,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: alignStart ? Alignment.centerLeft : Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignStart ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              active
                  ? (ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 13,
              color: active ? AppColors.primary : AppColors.textSecondary.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameCell extends StatelessWidget {
  final EmployeeRankingItem item;
  final bool zebra;

  const _NameCell({required this.item, required this.zebra});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _EmployeeRankingTableState._nameColWidth,
      height: _EmployeeRankingTableState._rowHeight,
      color: zebra ? AppColors.pageBackground : AppColors.cardBackground,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          item.hasPhoto
              ? CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  backgroundImage: NetworkImage(item.photo!),
                )
              : InitialsAvatar(name: item.fullName, radius: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final EmployeeRankingItem item;
  final String currencySymbol;
  final bool zebra;
  final double branchColWidth;
  final double revenueColWidth;
  final double servicesColWidth;
  final double expensesColWidth;
  final double profitColWidth;
  final double commissionColWidth;

  const _DataRow({
    required this.item,
    required this.currencySymbol,
    required this.zebra,
    required this.branchColWidth,
    required this.revenueColWidth,
    required this.servicesColWidth,
    required this.expensesColWidth,
    required this.profitColWidth,
    required this.commissionColWidth,
  });

  @override
  Widget build(BuildContext context) {
    final rowColor = zebra ? AppColors.pageBackground : AppColors.cardBackground;

    return Row(
      children: [
        _cell(item.branchName, branchColWidth, rowColor, alignStart: true),
        _cell(
          CurrencyUtils.format(item.revenue, symbol: currencySymbol),
          revenueColWidth,
          rowColor,
          bold: true,
        ),
        _cell('${item.servicesServed}', servicesColWidth, rowColor),
        _cell(
          CurrencyUtils.format(item.expenses, symbol: currencySymbol),
          expensesColWidth,
          rowColor,
        ),
        _cell(
          CurrencyUtils.format(item.profit, symbol: currencySymbol),
          profitColWidth,
          rowColor,
          bold: true,
          color: AppColors.success,
        ),
        _cell(
          CurrencyUtils.format(item.commission, symbol: currencySymbol),
          commissionColWidth,
          rowColor,
        ),
      ],
    );
  }

  Widget _cell(
    String text,
    double width,
    Color background, {
    bool alignStart = false,
    bool bold = false,
    Color? color,
  }) {
    return Container(
      width: width,
      height: _EmployeeRankingTableState._rowHeight,
      color: background,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: alignStart ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignStart ? TextAlign.left : TextAlign.center,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? AppColors.textPrimary,
          fontSize: 12.5,
        ),
      ),
    );
  }
}
