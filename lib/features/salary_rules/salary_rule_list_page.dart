import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/salary_rules_api.dart';
import '../../core/services/DataModels/salary_rule_list_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/salary_rule_list_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_salary_rule_page.dart';
import 'salary_rule_detail_page.dart';
import 'widgets/salary_rule_filter_sheet.dart';

/// Salary Rule List screen — the entry point into Salary Rules
/// Management. Structure mirrors `ExpenseListPage`/`ServiceListPage`
/// exactly: search bar with a filter-button trailing, FAB to add,
/// pull-to-refresh, shimmer/empty/error states, and a card-per-item
/// list.
class SalaryRuleListPage extends StatefulWidget {
  const SalaryRuleListPage({super.key});

  @override
  State<SalaryRuleListPage> createState() => _SalaryRuleListPageState();
}

class _SalaryRuleListPageState extends State<SalaryRuleListPage>
    with ConnectivityAwareRefresh<SalaryRuleListPage> {
  final TextEditingController _searchController = TextEditingController();
  final SalaryRulesApi _api = SalaryRulesApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  List<SalaryRuleListItem> _rules = [];

  SalaryRuleFilter _filter = const SalaryRuleFilter();

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  @override
  Future<void> onReconnected() => _loadRules(silent: true);

  Future<void> _loadRules({bool silent = false}) async {
    setState(() {
      if (!silent && _rules.isEmpty) _loading = true;
      _error = null;
    });

    final response = await _api.fetchSalaryRuleList();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess) {
      setState(() {
        _rules = response.data ?? [];
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        if (_rules.isEmpty) {
          _error = response.error ??
              "We couldn't load salary rules right now. Please try again.";
          _isOffline = response.isConnectivityError;
        }
      });
    }
  }

  Future<void> _openCreateRule() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditSalaryRulePage()),
    );
    if (created == true) _loadRules(silent: true);
  }

  Future<void> _openRuleDetail(SalaryRuleListItem rule) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SalaryRuleDetailPage(ruleId: rule.id)),
    );
    if (changed == true) _loadRules(silent: true);
  }

  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();
    final options = _filterOptions();
    final result = await SalaryRuleFilterSheet.show(
      context,
      current: _filter,
      salaryTypes: options.$1,
      statuses: options.$2,
    );
    if (result != null) setState(() => _filter = result);
  }

  (List<String>, List<String>) _filterOptions() {
    final salaryTypes = <String>{};
    final statuses = <String>{};
    for (final r in _rules) {
      if (r.salaryType.isNotEmpty) salaryTypes.add(r.salaryType);
      if (r.status.isNotEmpty) statuses.add(r.status);
    }
    final sorted = (Set<String> s) => s.toList()..sort();
    return (sorted(salaryTypes), sorted(statuses));
  }

  List<SalaryRuleListItem> _applyFilters(List<SalaryRuleListItem> data) {
    final query = _searchController.text.trim().toLowerCase();
    return data.where((rule) {
      final matchesQuery = query.isEmpty || rule.name.toLowerCase().contains(query);
      final matchesType = _filter.salaryType == null || rule.salaryType == _filter.salaryType;
      final matchesStatus = _filter.status == null || rule.status == _filter.status;
      return matchesQuery && matchesType && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRules = _applyFilters(_rules);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Salary Rules", style: AppTextStyles.h2.copyWith(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openCreateRule,
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
                Expanded(child: _body(filteredRules)),
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
      hintText: "Search salary rules",
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

  Widget _body(List<SalaryRuleListItem> data) {
    if (_loading) return const SalaryRuleListShimmer();

    if (_error != null) {
      return NetworkStateView(isOffline: _isOffline, message: _error, onRetry: _loadRules);
    }

    if (data.isEmpty) {
      final hasActiveSearchOrFilter =
          _searchController.text.trim().isNotEmpty || !_filter.isEmpty;
      return Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: AnimatedEmptyState(
            icon: Icons.rule_folder_outlined,
            title: _rules.isEmpty ? "No Salary Rules Found" : "No Matches Found",
            message: _rules.isEmpty
                ? "Add a salary rule to start assigning it to staff."
                : hasActiveSearchOrFilter
                    ? "Try a different search term or adjust your filters."
                    : "Try a different search term.",
            height: MediaQuery.of(context).size.height * 0.45,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadRules(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        padding: const EdgeInsets.only(bottom: 80),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.verticalMedium),
        itemBuilder: (context, index) {
          final rule = data[index];
          return _SalaryRuleCard(rule: rule, onTap: () => _openRuleDetail(rule));
        },
      ),
    );
  }
}

/// Salary Rule list tile — same card shell as
/// `ExpenseListPage._ExpenseCard`.
class _SalaryRuleCard extends StatelessWidget {
  final SalaryRuleListItem rule;
  final VoidCallback onTap;

  const _SalaryRuleCard({required this.rule, required this.onTap});

  String get _subtitle {
    switch (rule.salaryType) {
      case 'Fixed Salary':
        return '₹${rule.fixedSalary?.toStringAsFixed(0) ?? '0'} fixed';
      case 'Service Commission':
        return 'Commission set per service';
      case 'Hybrid':
        return '₹${rule.fixedSalary?.toStringAsFixed(0) ?? '0'} + per-service commission';
      default:
        return rule.salaryType;
    }
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
                  child: const Icon(Icons.rule_folder_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.name,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        rule.salaryType,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      StatusBadge(status: rule.status),
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
