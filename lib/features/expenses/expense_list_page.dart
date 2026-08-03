import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/expenses_api.dart';
import '../../core/services/DataModels/expense_list_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/expense_list_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_expense_page.dart';
import 'expense_detail_page.dart';
import 'widgets/expense_filter_sheet.dart';

/// Expense List screen — the entry point into Expenses Management, a
/// configuration screen for expense *types* (Name, Description, and
/// which branch(es) each applies to). Structure mirrors
/// `ServiceListPage`/`StaffListPage` exactly: search bar with a
/// filter-button trailing, FAB to add, pull-to-refresh, shimmer/empty/
/// error states, and a card-per-item list.
class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key});

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage>
    with ConnectivityAwareRefresh<ExpenseListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ExpensesApi _api = ExpensesApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  List<ExpenseListItem> _expenses = [];

  ExpenseFilter _filter = const ExpenseFilter();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  Future<void> onReconnected() => _loadExpenses(silent: true);

  Future<void> _loadExpenses({bool silent = false}) async {
    setState(() {
      if (!silent && _expenses.isEmpty) _loading = true;
      _error = null;
    });

    final response = await _api.fetchExpenseList();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess) {
      setState(() {
        _expenses = response.data ?? [];
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        if (_expenses.isEmpty) {
          _error = response.error ??
              "We couldn't load expenses right now. Please try again.";
          _isOffline = response.isConnectivityError;
        }
      });
    }
  }

  Future<void> _openCreateExpense() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditExpensePage()),
    );
    if (created == true) _loadExpenses(silent: true);
  }

  Future<void> _openExpenseDetail(ExpenseListItem expense) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ExpenseDetailPage(expenseId: expense.id)),
    );
    if (changed == true) _loadExpenses(silent: true);
  }

  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();
    final options = _filterOptions();
    final result = await ExpenseFilterSheet.show(
      context,
      current: _filter,
      branchNames: options.$1,
      statuses: options.$2,
    );
    if (result != null) setState(() => _filter = result);
  }

  (List<String>, List<String>) _filterOptions() {
    final branchNames = <String>{};
    final statuses = <String>{};
    for (final e in _expenses) {
      branchNames.addAll(e.branchNames);
      if (e.status.isNotEmpty) statuses.add(e.status);
    }
    final sorted = (Set<String> s) => s.toList()..sort();
    return (sorted(branchNames), sorted(statuses));
  }

  /// "Branch" filters expenses whose scope includes the given branch —
  /// either directly assigned, or via "All Branches".
  List<ExpenseListItem> _applyFilters(List<ExpenseListItem> data) {
    final query = _searchController.text.trim().toLowerCase();
    return data.where((expense) {
      final matchesQuery = query.isEmpty || expense.name.toLowerCase().contains(query);

      final matchesBranch = _filter.branchName == null ||
          expense.allBranches ||
          expense.branchNames.contains(_filter.branchName);
      final matchesStatus = _filter.status == null || expense.status == _filter.status;

      return matchesQuery && matchesBranch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExpenses = _applyFilters(_expenses);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Expenses", style: AppTextStyles.h2.copyWith(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openCreateExpense,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              children: [
                _searchAndFilterRow(),
                const SizedBox(height: AppSpacing.verticalLarge),
                Expanded(child: _body(filteredExpenses)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchAndFilterRow() {
    return AppSearchBar(
      controller: _searchController,
      hintText: "Search expenses",
      onChanged: (_) => setState(() {}),
      trailing: _filterButton(),
    );
  }

  Widget _filterButton() {
    final active = _filter.activeCount;
    return Material(
      color: active > 0 ? AppColors.primary : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: _openFilterSheet,
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: active > 0 ? AppColors.primary : AppColors.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.tune_rounded,
                  color: active > 0 ? Colors.white : AppColors.textSecondary),
              if (active > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '$active',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(List<ExpenseListItem> data) {
    if (_loading) return const ExpenseListShimmer();

    if (_error != null) {
      return NetworkStateView(isOffline: _isOffline, message: _error, onRetry: _loadExpenses);
    }

    if (data.isEmpty) {
      final hasActiveSearchOrFilter =
          _searchController.text.trim().isNotEmpty || !_filter.isEmpty;
      return Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: AnimatedEmptyState(
            icon: Icons.receipt_long_outlined,
            title: _expenses.isEmpty ? "No Expenses Found" : "No Matches Found",
            message: _expenses.isEmpty
                ? "Add an expense type to start categorizing your costs."
                : hasActiveSearchOrFilter
                    ? "Try a different search term or adjust your filters."
                    : "Try a different search term.",
            height: MediaQuery.of(context).size.height * 0.45,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadExpenses(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        padding: const EdgeInsets.only(bottom: 80),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.verticalMedium),
        itemBuilder: (context, index) {
          final expense = data[index];
          return _ExpenseCard(expense: expense, onTap: () => _openExpenseDetail(expense));
        },
      ),
    );
  }
}

/// Expense list tile — same card shell as
/// `ServiceListPage._ServiceCard`/`StaffListPage._StaffCard`, laid out
/// for a configuration-screen item: name, description, branch scope,
/// status.
class _ExpenseCard extends StatelessWidget {
  final ExpenseListItem expense;
  final VoidCallback onTap;

  const _ExpenseCard({required this.expense, required this.onTap});

  String get _branchSummary {
    if (expense.allBranches) return 'All Branches';
    if (expense.branchNames.isEmpty) return 'No branches assigned';
    if (expense.branchNames.length == 1) return expense.branchNames.first;
    return '${expense.branchNames.length} branches';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.name,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      if (expense.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          expense.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _branchSummary,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(status: expense.status),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
