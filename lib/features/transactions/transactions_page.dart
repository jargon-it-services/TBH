import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/transaction_api.dart';
import '../../core/services/DataModels/transaction_list_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/payment_mode_chip.dart';
import '../../core/widgets/shimmers/transaction_list_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/transaction_type_chip.dart';
import 'transaction_details_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with ConnectivityAwareRefresh<TransactionsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TransactionApi _api = TransactionApi();

  /// ---------------- FILTER STATE ----------------
  final List<String> firms = [];
  final List<String> services = [];
  final List<String> staff = [];
  final List<String> statuses = ["paid", "pending", "cancelled"];
  final List<String> types = ["service", "expense"];

  Set<String> selectedFirms = {};
  Set<String> selectedStatus = {};
  Set<String> selectedTypes = {};
  Set<String> selectedServices = {};
  Set<String> selectedStaff = {};
  String selectedPeriod = "all";

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

  bool get isFilterApplied =>
      selectedFirms.isNotEmpty ||
      selectedStatus.isNotEmpty ||
      selectedTypes.isNotEmpty ||
      selectedServices.isNotEmpty ||
      selectedStaff.isNotEmpty ||
      selectedPeriod != "all";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ---------------- API ----------------
  Future<void> _fetchTransactions({bool silent = false}) async {
    if (!mounted) return;

    setState(() {
      // Same reasoning as FirmListPage: only take over the screen with
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
      filteredTransactions = List.from(allTransactions);
      _isOffline = false;

      firms.clear();
      services.clear();
      staff.clear();
      for (var t in allTransactions) {
        if (t.firm.isNotEmpty && !firms.contains(t.firm)) {
          firms.add(t.firm);
        }
        if (t.service.isNotEmpty && !services.contains(t.service)) {
          services.add(t.service);
        }
        if (t.staff.isNotEmpty && !staff.contains(t.staff)) {
          staff.add(t.staff);
        }
      }
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
          onPressed: () {},
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  /// ---------------- SEARCH + FILTER ----------------
  Widget _searchWithFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.page,
        vertical: 6,
      ),
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
      child: Row(
        children: [
          /// Search
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              style: AppTextStyles.body,
              decoration: InputDecoration(
                hintText: "Search transactions",
                hintStyle: AppTextStyles.bodySmall,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(width: 12),

          /// Filter button
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isFilterApplied
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFilterApplied ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: 18,
                    color: isFilterApplied
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Filters",
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isFilterApplied
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (isFilterApplied) ...[
                    const SizedBox(width: 6),
                    Container(
                      height: 6,
                      width: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  "No transactions found",
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchTransactions(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredTransactions.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.verticalMedium),
        itemBuilder: (_, i) => _transactionCard(filteredTransactions[i]),
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
          item.firm,
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
    filteredTransactions = allTransactions.where((t) {
      if (selectedFirms.isNotEmpty && !selectedFirms.contains(t.firm))
        return false;
      if (selectedStatus.isNotEmpty && !selectedStatus.contains(t.status))
        return false;
      if (selectedTypes.isNotEmpty && !selectedTypes.contains(t.type))
        return false;
      if (selectedServices.isNotEmpty && !selectedServices.contains(t.service))
        return false;
      if (selectedStaff.isNotEmpty && !selectedStaff.contains(t.staff))
        return false;
      if (_searchController.text.isNotEmpty &&
          !t.title.toLowerCase().contains(_searchController.text.toLowerCase()))
        return false;
      return true;
    }).toList();

    setState(() {});
  }
}
