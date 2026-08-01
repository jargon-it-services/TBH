import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/branches_api.dart';
import '../../core/services/DataModels/branch_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/branch_list_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_branch_page.dart';
import 'branch_detail_page.dart';
import 'widgets/branch_filter_sheet.dart';

class BranchListPage extends StatefulWidget {
  const BranchListPage({super.key});

  @override
  State<BranchListPage> createState() => _BranchListPageState();
}

class _BranchListPageState extends State<BranchListPage>
    with ConnectivityAwareRefresh<BranchListPage> {
  final TextEditingController _searchController = TextEditingController();
  final BranchesApi _api = BranchesApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  List<BranchModel> _branches = [];

  BranchFilter _filter = const BranchFilter();

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  @override
  Future<void> onReconnected() => _loadBranches(silent: true);

  Future<void> _loadBranches({bool silent = false}) async {
    setState(() {
      // Same rule FirmListPage uses: only take over the whole screen
      // with the loading shimmer when there's nothing else to show yet.
      if (!silent && _branches.isEmpty) _loading = true;
      _error = null;
    });

    final response = await _api.fetchBranches();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess) {
      setState(() {
        _branches = response.data ?? [];
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        // State preservation: a failed reload with branches already on
        // screen must not clear them.
        if (_branches.isEmpty) {
          _error = response.error ??
              "We couldn't load branches right now. Please try again.";
          _isOffline = response.isConnectivityError;
        }
      });
    }
  }

  Future<void> _openCreateBranch() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditBranchPage()),
    );
    if (created == true) _loadBranches(silent: true);
  }

  Future<void> _openBranchDetail(BranchModel branch) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BranchDetailPage(branchId: branch.id),
      ),
    );
    if (changed == true) _loadBranches(silent: true);
  }

  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();
    final options = _filterOptions();
    final result = await BranchFilterSheet.show(
      context,
      current: _filter,
      branchTypes: options.$1,
      statuses: options.$2,
      cities: options.$3,
      states: options.$4,
    );
    if (result != null) setState(() => _filter = result);
  }

  /// Distinct, non-empty values actually present in the loaded
  /// branches, sorted for a stable/predictable sheet — so Filter never
  /// offers an option with zero possible matches.
  (List<String>, List<String>, List<String>, List<String>) _filterOptions() {
    final types = <String>{};
    final statuses = <String>{};
    final cities = <String>{};
    final states = <String>{};
    for (final b in _branches) {
      if (b.branchType.isNotEmpty) types.add(b.branchType);
      if (b.status.isNotEmpty) statuses.add(b.status);
      if (b.city.isNotEmpty) cities.add(b.city);
      if (b.state.isNotEmpty) states.add(b.state);
    }
    final sorted = (Set<String> s) => s.toList()..sort();
    return (sorted(types), sorted(statuses), sorted(cities), sorted(states));
  }

  List<BranchModel> _applyFilters(List<BranchModel> data) {
    final query = _searchController.text.trim().toLowerCase();
    return data.where((branch) {
      final matchesQuery = query.isEmpty ||
          branch.name.toLowerCase().contains(query) ||
          branch.city.toLowerCase().contains(query) ||
          branch.state.toLowerCase().contains(query) ||
          branch.address.toLowerCase().contains(query);

      final matchesType =
          _filter.branchType == null || branch.branchType == _filter.branchType;
      final matchesStatus =
          _filter.status == null || branch.status == _filter.status;
      final matchesCity = _filter.city == null || branch.city == _filter.city;
      final matchesState =
          _filter.state == null || branch.state == _filter.state;

      return matchesQuery &&
          matchesType &&
          matchesStatus &&
          matchesCity &&
          matchesState;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBranches = _applyFilters(_branches);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Branches",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openCreateBranch,
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
              Expanded(child: _body(filteredBranches)),
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
      hintText: "Search branches",
      onChanged: (_) => setState(() {}),
      trailing: _filterButton(),
    );
  }

  Widget _filterButton() {
    final active = _filter.activeCount;
    return Material(
      color: active > 0
          ? AppColors.primary
          : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: _openFilterSheet,
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: active > 0 ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                color: active > 0 ? Colors.white : AppColors.textSecondary,
              ),
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
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(List<BranchModel> data) {
    if (_loading) {
      return const BranchListShimmer();
    }

    if (_error != null) {
      return NetworkStateView(
        isOffline: _isOffline,
        message: _error,
        onRetry: _loadBranches,
      );
    }

    if (data.isEmpty) {
      final hasActiveSearchOrFilter =
          _searchController.text.trim().isNotEmpty || !_filter.isEmpty;
      return Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: AnimatedEmptyState(
            icon: Icons.store_mall_directory_outlined,
            title: _branches.isEmpty ? "No Branches Found" : "No Matches Found",
            message: _branches.isEmpty
                ? "Add a branch to start managing its staff and services."
                : hasActiveSearchOrFilter
                    ? "Try a different search term or adjust your filters."
                    : "Try a different search term.",
            height: MediaQuery.of(context).size.height * 0.45,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBranches(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        padding: const EdgeInsets.only(bottom: 80), // space for FAB
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.verticalMedium),
        itemBuilder: (context, index) {
          final branch = data[index];
          return _BranchCard(
            branch: branch,
            onTap: () => _openBranchDetail(branch),
          );
        },
      ),
    );
  }
}

/// Branch list tile — same card shell (Material/Ink, radius, border,
/// shadow, CircleAvatar leading) as `TransactionsPage._transactionCard`,
/// laid out for a branch's own fields (name, address, type, status)
/// rather than an amount.
class _BranchCard extends StatelessWidget {
  final BranchModel branch;
  final VoidCallback onTap;

  const _BranchCard({required this.branch, required this.onTap});

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
                _logoAvatar(),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch.name,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        branch.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [branch.city, branch.state]
                            .where((p) => p.isNotEmpty)
                            .join(', '),
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _tag(branch.branchType, Icons.people_outline),
                          const SizedBox(width: 8),
                          StatusBadge(status: branch.status),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the branch logo when available; otherwise falls back to the
  /// existing store icon avatar — behavior unchanged for branches
  /// without a logo.
  Widget _logoAvatar() {
    if (branch.hasLogo) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        backgroundImage: NetworkImage(branch.logo!),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: const Icon(
        Icons.store_mall_directory_outlined,
        color: AppColors.primary,
      ),
    );
  }

  Widget _tag(String label, IconData icon) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
