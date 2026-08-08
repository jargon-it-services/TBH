import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/transaction_api.dart';
import '../../core/services/DataModels/transaction_list_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/payment_mode_chip.dart';
import '../../core/widgets/shimmers/transaction_list_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/transaction_type_chip.dart';
import 'transaction_details_page.dart';
import 'transaction_entry_page.dart';
import 'widgets/transaction_filter_sheet.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with ConnectivityAwareRefresh<TransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TransactionApi _api = TransactionApi();

  /// ---------------- FILTER OPTIONS (derived from loaded data) ----------------
  List<String> statuses = [];
  List<String> paymentModes = [];
  List<String> types = [];

  TransactionFilter _filter = const TransactionFilter();

  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];
  bool isLoading = true;
  String? _error;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  Future<void> onReconnected() => _fetchTransactions(silent: true);

  bool get isFilterApplied => !_filter.isEmpty;

  bool get _isSearchOrFilterActive =>
      _searchController.text.trim().isNotEmpty || isFilterApplied;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ---------------- API ----------------
  Future<void> _fetchTransactions({bool silent = false}) async {
    if (!mounted) return;

    setState(() {
      // Same reasoning as BranchListPage: only take over the screen with
      // the shimmer when there's nothing else to show yet. A silent
      // reload (pull-to-refresh has its own spinner; a reconnect retry
      // should be invisible if it succeeds) never flips this.
      if (!silent && allTransactions.isEmpty) isLoading = true;
      _error = null;
    });

    final response = await _api.fetchTransactions();

    if (!mounted) return; // 🔥 IMPORTANT

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess && response.data != null) {
      allTransactions = response.data!.data.transactions;
      _isOffline = false;

      // Prefer the filter option lists the API already returns; fall
      // back to deriving them from the loaded transactions (e.g. an
      // older backend response that doesn't send `filters`) so the
      // filter sheet never ends up empty while data is on screen.
      final apiFilters = response.data!.data.filters;
      statuses = apiFilters.statuses.isNotEmpty
          ? apiFilters.statuses
          : _distinctValues((t) => t.status);
      paymentModes = apiFilters.paymentModes.isNotEmpty
          ? apiFilters.paymentModes
          : _distinctValues((t) => t.paymentMode);
      types = apiFilters.types.isNotEmpty
          ? apiFilters.types
          : _distinctValues((t) => t.type);

      _applyFilters();
    } else if (allTransactions.isEmpty) {
      // State preservation: only surface a blocking error state when
      // there's nothing already on screen to preserve. If a refresh
      // fails while transactions are already showing, leave them be —
      // the app-wide ConnectivityBanner already signals "you're
      // offline" without needing a second, screen-level indicator.
      _error = response.error ?? "We couldn't load transactions right now.";
      _isOffline = response.isConnectivityError;
    }

    setState(() => isLoading = false);
  }

  List<String> _distinctValues(String Function(TransactionModel) pick) {
    final values = <String>{};
    for (final t in allTransactions) {
      final v = pick(t);
      if (v.isNotEmpty) values.add(v);
    }
    return values.toList()..sort();
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Transactions",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.large),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: _searchWithFilter(),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                child: _transactionsList(),
              ),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 0.0),
        child: FloatingActionButton(
          onPressed: _openNewTransaction,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  /// New Transaction never navigates back here automatically on save —
  /// it resets in place so staff can process the next transaction
  /// immediately (see `TransactionEntryPage`'s class doc). This list
  /// only needs a silent refresh for whenever the user does eventually
  /// come back (back button/bottom nav).
  Future<void> _openNewTransaction() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionEntryPage()),
    );
    _fetchTransactions(silent: true);
  }

  /// ---------------- SEARCH + FILTER ----------------
  /// Same shape as `SalaryRuleListPage`: `AppSearchBar` with a trailing
  /// filter button that opens a bottom sheet, badge showing the active
  /// filter count.
  Widget _searchWithFilter() {
    return AppSearchBar(
      controller: _searchController,
      hintText: "Search transactions",
      onChanged: (_) => _applyFilters(),
      trailing: _filterButton(),
    );
  }

  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();
    final result = await TransactionFilterSheet.show(
      context,
      current: _filter,
      statuses: statuses,
      paymentModes: paymentModes,
      types: types,
    );
    if (result != null) {
      setState(() => _filter = result);
      _applyFilters();
    }
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

  /// ---------------- LIST ----------------
  Widget _transactionsList() {
    if (isLoading) return const TransactionListShimmer();

    if (_error != null) {
      return NetworkStateView(
        isOffline: _isOffline,
        message: _error,
        onRetry: _fetchTransactions,
      );
    }

    if (filteredTransactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchTransactions(silent: true),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AnimatedEmptyState(
              icon: _isSearchOrFilterActive
                  ? Icons.search_off
                  : Icons.receipt_long_outlined,
              title: _isSearchOrFilterActive
                  ? "No Matches Found"
                  : "No Transactions Found",
              message: _isSearchOrFilterActive
                  ? "Try a different search term or adjust your filters."
                  : "New transactions will show up here.",
              height: MediaQuery.of(context).size.height * 0.45,
            ),
          ],
        ),
      );
    }

    final sections = _groupedSections;

    return RefreshIndicator(
      onRefresh: () => _fetchTransactions(silent: true),
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _sectionedItemCount(sections),
        itemBuilder: (context, index) =>
            _buildSectionedItem(context, sections, index),
      ),
    );
  }

  /// ---------------- GROUPING: Today / Yesterday / Earlier ----------------
  /// Same grouping as `NotificationListPage._groupedSections`.
  List<MapEntry<String, List<TransactionModel>>> get _groupedSections {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final List<TransactionModel> todayItems = [];
    final List<TransactionModel> yesterdayItems = [];
    final List<TransactionModel> earlierItems = [];

    for (final t in filteredTransactions) {
      final created = t.createdAt.toLocal();
      final createdDate = DateTime(created.year, created.month, created.day);
      if (createdDate == today) {
        todayItems.add(t);
      } else if (createdDate == yesterday) {
        yesterdayItems.add(t);
      } else {
        earlierItems.add(t);
      }
    }

    return [
      if (todayItems.isNotEmpty) MapEntry('Today', todayItems),
      if (yesterdayItems.isNotEmpty) MapEntry('Yesterday', yesterdayItems),
      if (earlierItems.isNotEmpty) MapEntry('Earlier', earlierItems),
    ];
  }

  int _sectionedItemCount(List<MapEntry<String, List<TransactionModel>>> sections) {
    var count = 0;
    for (final section in sections) {
      count += 1 + section.value.length; // header + items
    }
    return count;
  }

  Widget _buildSectionedItem(
    BuildContext context,
    List<MapEntry<String, List<TransactionModel>>> sections,
    int flatIndex,
  ) {
    var remaining = flatIndex;
    for (final section in sections) {
      if (remaining == 0) {
        return _sectionHeader(section.key);
      }
      remaining -= 1;
      if (remaining < section.value.length) {
        final item = section.value[remaining];
        final isLastInSection = remaining == section.value.length - 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: isLastInSection
                ? AppSpacing.verticalLarge
                : AppSpacing.verticalMedium,
          ),
          child: _transactionCard(item),
        );
      }
      remaining -= section.value.length;
    }
    // Unreachable given _sectionedItemCount, but keeps the method
    // total and null-safe rather than throwing on a stray index.
    return const SizedBox.shrink();
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalSmall),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// ---------------- CARD ----------------
  Widget _transactionCard(TransactionModel item) {
    final isExpense = item.type == "expense";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailsPage(transactionId: item.id),
            ),
          );
        },
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
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      (isExpense ? AppColors.secondary : AppColors.primary)
                          .withOpacity(0.15),
                  child: Icon(
                    isExpense ? Icons.payments_outlined : Icons.content_cut,
                    color: isExpense ? AppColors.secondary : AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(child: _transactionInfo(item)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${item.amount}",
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _transactionInfo(TransactionModel item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          item.branch,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          item.staff,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat("dd MMM yyyy, hh:mm a").format(item.createdAt.toLocal()),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            StatusBadge(status: item.status),
            const SizedBox(width: AppSpacing.horizontalSmall),
            PaymentModeChip(mode: item.paymentMode),
            const SizedBox(width: AppSpacing.horizontalSmall),
            TransactionTypeChip(type: item.type),
          ],
        ),
      ],
    );
  }

  /// ---------------- FILTER LOGIC ----------------
  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    filteredTransactions = allTransactions.where((t) {
      if (_filter.status != null && t.status != _filter.status) return false;
      if (_filter.paymentMode != null && t.paymentMode != _filter.paymentMode) {
        return false;
      }
      if (_filter.type != null && t.type != _filter.type) return false;
      if (query.isNotEmpty && !t.title.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    setState(() {});
  }
}
