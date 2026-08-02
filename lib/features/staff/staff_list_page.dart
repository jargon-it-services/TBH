import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/staff_api.dart';
import '../../core/services/DataModels/staff_list_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/InitialsAvatar.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/staff_list_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_staff_page.dart';
import 'staff_detail_page.dart';
import 'widgets/staff_filter_sheet.dart';

/// Staff List screen — the entry point into Staff Management.
/// Structure mirrors `ServiceListPage`/`BranchListPage` exactly: search
/// bar with a filter-button trailing, FAB to add, pull-to-refresh,
/// shimmer/empty/error states, and a card-per-item list.
class StaffListPage extends StatefulWidget {
  const StaffListPage({super.key});

  @override
  State<StaffListPage> createState() => _StaffListPageState();
}

class _StaffListPageState extends State<StaffListPage>
    with ConnectivityAwareRefresh<StaffListPage> {
  final TextEditingController _searchController = TextEditingController();
  final StaffApi _api = StaffApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  List<StaffListItem> _staff = [];

  StaffFilter _filter = const StaffFilter();

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  @override
  Future<void> onReconnected() => _loadStaff(silent: true);

  Future<void> _loadStaff({bool silent = false}) async {
    setState(() {
      if (!silent && _staff.isEmpty) _loading = true;
      _error = null;
    });

    final response = await _api.fetchStaffList();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess) {
      setState(() {
        _staff = response.data ?? [];
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        if (_staff.isEmpty) {
          _error = response.error ??
              "We couldn't load staff right now. Please try again.";
          _isOffline = response.isConnectivityError;
        }
      });
    }
  }

  Future<void> _openCreateStaff() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditStaffPage()),
    );
    if (created == true) _loadStaff(silent: true);
  }

  Future<void> _openStaffDetail(StaffListItem staff) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => StaffDetailPage(staffId: staff.id)),
    );
    if (changed == true) _loadStaff(silent: true);
  }

  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();
    final options = _filterOptions();
    final result = await StaffFilterSheet.show(
      context,
      current: _filter,
      designations: options.$1,
      branchNames: options.$2,
      statuses: options.$3,
    );
    if (result != null) setState(() => _filter = result);
  }

  (List<String>, List<String>, List<String>) _filterOptions() {
    final designations = <String>{};
    final branchNames = <String>{};
    final statuses = <String>{};
    for (final s in _staff) {
      if (s.designation.isNotEmpty) designations.add(s.designation);
      if (s.branchName.isNotEmpty) branchNames.add(s.branchName);
      if (s.status.isNotEmpty) statuses.add(s.status);
    }
    final sorted = (Set<String> s) => s.toList()..sort();
    return (sorted(designations), sorted(branchNames), sorted(statuses));
  }

  List<StaffListItem> _applyFilters(List<StaffListItem> data) {
    final query = _searchController.text.trim().toLowerCase();
    return data.where((staff) {
      final matchesQuery = query.isEmpty ||
          staff.fullName.toLowerCase().contains(query) ||
          staff.employeeCode.toLowerCase().contains(query) ||
          staff.mobile.contains(query);

      final matchesDesignation =
          _filter.designation == null || staff.designation == _filter.designation;
      final matchesBranch =
          _filter.branchName == null || staff.branchName == _filter.branchName;
      final matchesStatus = _filter.status == null || staff.status == _filter.status;

      return matchesQuery && matchesDesignation && matchesBranch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStaff = _applyFilters(_staff);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Staff", style: AppTextStyles.h2.copyWith(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openCreateStaff,
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
                Expanded(child: _body(filteredStaff)),
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
      hintText: "Search staff by name, code, mobile",
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

  Widget _body(List<StaffListItem> data) {
    if (_loading) return const StaffListShimmer();

    if (_error != null) {
      return NetworkStateView(isOffline: _isOffline, message: _error, onRetry: _loadStaff);
    }

    if (data.isEmpty) {
      final hasActiveSearchOrFilter =
          _searchController.text.trim().isNotEmpty || !_filter.isEmpty;
      return Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: AnimatedEmptyState(
            icon: Icons.groups_outlined,
            title: _staff.isEmpty ? "No Staff Found" : "No Matches Found",
            message: _staff.isEmpty
                ? "Add a staff member to start building your team."
                : hasActiveSearchOrFilter
                    ? "Try a different search term or adjust your filters."
                    : "Try a different search term.",
            height: MediaQuery.of(context).size.height * 0.45,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadStaff(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        padding: const EdgeInsets.only(bottom: 80),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.verticalMedium),
        itemBuilder: (context, index) {
          final staff = data[index];
          return _StaffCard(staff: staff, onTap: () => _openStaffDetail(staff));
        },
      ),
    );
  }
}

/// Staff list tile — same card shell as `ServiceListPage._ServiceCard`,
/// laid out for a staff member's own fields (name, designation/branch
/// tags, employee code, status).
class _StaffCard extends StatelessWidget {
  final StaffListItem staff;
  final VoidCallback onTap;

  const _StaffCard({required this.staff, required this.onTap});

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
                _photoAvatar(),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.fullName,
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${staff.designation} • ${staff.branchName}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        staff.employeeCode,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _tag(staff.specialist, Icons.spa_outlined),
                          const SizedBox(width: 8),
                          StatusBadge(status: staff.status),
                        ],
                      ),
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

  Widget _photoAvatar() {
    if (staff.hasPhoto) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        backgroundImage: NetworkImage(staff.photo!),
      );
    }
    return InitialsAvatar(name: staff.fullName, radius: 24);
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
