import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/payment_history_api.dart';
import '../../core/services/DataModels/payment_history_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/transaction_list_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'payment_details_page.dart';

/// Payment History screen.
///
/// Follows the exact same shape as `TransactionsPage`: fetch once on
/// open (`GET /api/v1/payments/history`), keep the full response in
/// `allPayments`, and derive `filteredPayments` locally from the
/// search box + status chip -- no server-side search, pagination, or
/// filtering, and no local cache/database (a fresh fetch runs every
/// time this screen opens).
class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage>
    with ConnectivityAwareRefresh<PaymentHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final PaymentHistoryApi _api = PaymentHistoryApi();

  static const List<_StatusFilter> _statusFilters = [
    _StatusFilter(label: "All", value: null),
    _StatusFilter(label: "Success", value: "success"),
    _StatusFilter(label: "Pending", value: "pending"),
    _StatusFilter(label: "Failed", value: "failed"),
    _StatusFilter(label: "Refunded", value: "refunded"),
  ];

  String? _selectedStatus; // null == "All"

  List<PaymentSummary> allPayments = [];
  List<PaymentSummary> filteredPayments = [];
  bool isLoading = true;
  String? _error;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  @override
  Future<void> onReconnected() => _fetchPaymentHistory(silent: true);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ---------------- API ----------------
  Future<void> _fetchPaymentHistory({bool silent = false}) async {
    if (!mounted) return;

    setState(() {
      // Only take over the screen with the shimmer when there's
      // nothing else to show yet -- same reasoning as TransactionsPage.
      if (!silent && allPayments.isEmpty) isLoading = true;
      _error = null;
    });

    final response = await _api.fetchPaymentHistory();

    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess && response.data != null) {
      allPayments = response.data!.payments;
      _isOffline = false;
      _applyFilters();
    } else if (allPayments.isEmpty) {
      _error = response.error ?? "We couldn't load payment history right now.";
      _isOffline = response.isConnectivityError;
    }

    setState(() => isLoading = false);
  }

  /// ---------------- FILTER LOGIC (local only) ----------------
  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    filteredPayments = allPayments.where((p) {
      if (_selectedStatus != null && p.status != _selectedStatus) {
        return false;
      }
      if (query.isNotEmpty && !p.id.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    setState(() {});
  }

  void _onStatusSelected(String? status) {
    _selectedStatus = status;
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    _applyFilters();
  }

  bool get _isSearchOrFilterActive =>
      _searchController.text.trim().isNotEmpty || _selectedStatus != null;

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Payment History",
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.page,
                AppSpacing.page,
                0,
              ),
              child: _searchBar(),
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            _statusChips(),
            const SizedBox(height: AppSpacing.verticalMedium),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: _paymentsList(),
              ),
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
          ],
        ),
      ),
    );
  }

  /// ---------------- SEARCH ----------------
  Widget _searchBar() {
    return Container(
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
        controller: _searchController,
        // Purely local filtering -- no API call while typing, so this
        // needs no debounce (there's no existing debounce utility in
        // the codebase to reuse either; TransactionsPage's identical
        // local-search box also filters directly on every change).
        onChanged: (_) => _applyFilters(),
        style: AppTextStyles.body,
        decoration: InputDecoration(
          hintText: "Search by Transaction ID",
          hintStyle: AppTextStyles.bodySmall,
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.textSecondary,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: _clearSearch,
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  /// ---------------- STATUS CHIPS ----------------
  Widget _statusChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
        itemCount: _statusFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _statusFilters[i];
          final isSelected = _selectedStatus == filter.value;
          return _StatusChip(
            label: filter.label,
            statusValue: filter.value,
            isSelected: isSelected,
            onTap: () => _onStatusSelected(filter.value),
          );
        },
      ),
    );
  }

  /// ---------------- LIST ----------------
  Widget _paymentsList() {
    if (isLoading) return const TransactionListShimmer();

    if (_error != null) {
      return NetworkStateView(
        isOffline: _isOffline,
        message: _error,
        onRetry: _fetchPaymentHistory,
      );
    }

    if (filteredPayments.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchPaymentHistory(silent: true),
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AnimatedEmptyState(
              icon: _isSearchOrFilterActive
                  ? Icons.search_off
                  : Icons.receipt_long_outlined,
              title: _isSearchOrFilterActive
                  ? "No matching transactions"
                  : "No payment history yet",
              message: _isSearchOrFilterActive
                  ? "Try a different Transaction ID or status filter."
                  : "Your payment transactions will show up here.",
              height: 280,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPaymentHistory(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredPayments.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.verticalMedium),
        itemBuilder: (_, i) => _paymentCard(filteredPayments[i]),
      ),
    );
  }

  /// ---------------- CARD ----------------
  Widget _paymentCard(PaymentSummary item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: () {
          // Pass only the id -- Transaction Details screen loads its
          // own fresh data independently.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentDetailsPage(transactionId: item.id),
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
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: const Icon(
                    Icons.account_balance_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(child: _paymentInfo(item)),
                const SizedBox(width: AppSpacing.horizontalSmall),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.formattedAmount,
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentInfo(PaymentSummary item) {
    final metaParts = [
      if (item.dateDisplay.isNotEmpty) item.dateDisplay,
    ];
    final locationParts = [
      if (item.branch.isNotEmpty) item.branch,
      if (item.paymentType.isNotEmpty) item.paymentType,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.id,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        if (metaParts.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            metaParts.join(" • "),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall,
          ),
        ],
        if (locationParts.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            locationParts.join(" • "),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// ---------------- STATUS FILTER (chip data) ----------------
class _StatusFilter {
  final String label;
  final String? value; // null represents "All"

  const _StatusFilter({required this.label, required this.value});
}

/// A selectable, horizontally-scrollable status chip. Local to this
/// screen (no existing shared "selectable filter chip" widget exists
/// in `core/widgets` to reuse -- see `_searchWithFilter` in
/// `TransactionsPage` for the same page-local-widget precedent) but
/// reuses `StatusBadge`'s color language so selected/unselected states
/// stay visually consistent with the status badges shown elsewhere.
class _StatusChip extends StatelessWidget {
  final String label;
  final String? statusValue;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.statusValue,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color => switch (statusValue) {
        "success" => AppColors.success,
        "pending" => AppColors.warning,
        "failed" => AppColors.error,
        "refunded" => AppColors.primary,
        _ => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
