import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/network/apis/services_api.dart';
import '../../core/services/DataModels/service_list_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/service_list_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_service_page.dart';
import 'service_detail_page.dart';
import 'widgets/service_filter_sheet.dart';

/// Service List screen — the entry point into Service Management.
/// Structure mirrors `BranchListPage` exactly: search bar with a
/// filter-button trailing, FAB to add, pull-to-refresh, shimmer/empty/
/// error states, and a card-per-item list.
class ServiceListPage extends StatefulWidget {
  const ServiceListPage({super.key});

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage>
    with ConnectivityAwareRefresh<ServiceListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ServicesApi _api = ServicesApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  List<ServiceListItem> _services = [];

  ServiceFilter _filter = const ServiceFilter();

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  Future<void> onReconnected() => _loadServices(silent: true);

  Future<void> _loadServices({bool silent = false}) async {
    setState(() {
      // Same rule BranchListPage uses: only take over the whole screen
      // with the loading shimmer when there's nothing else to show yet.
      if (!silent && _services.isEmpty) _loading = true;
      _error = null;
    });

    final response = await _api.fetchServiceList();
    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !response.isSuccess && response.isConnectivityError;

    if (response.isSuccess) {
      setState(() {
        _services = response.data ?? [];
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        // State preservation: a failed reload with services already on
        // screen must not clear them.
        if (_services.isEmpty) {
          _error = response.error ??
              "We couldn't load services right now. Please try again.";
          _isOffline = response.isConnectivityError;
        }
      });
    }
  }

  Future<void> _openCreateService() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditServicePage()),
    );
    if (created == true) _loadServices(silent: true);
  }

  Future<void> _openServiceDetail(ServiceListItem service) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceDetailPage(serviceId: service.id),
      ),
    );
    if (changed == true) _loadServices(silent: true);
  }

  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();
    final options = _filterOptions();
    final result = await ServiceFilterSheet.show(
      context,
      current: _filter,
      categories: options.$1,
      genders: options.$2,
      statuses: options.$3,
    );
    if (result != null) setState(() => _filter = result);
  }

  /// Distinct, non-empty values actually present in the loaded
  /// services, sorted for a stable/predictable sheet — mirrors
  /// `BranchListPage._filterOptions`.
  (List<String>, List<String>, List<String>) _filterOptions() {
    final categories = <String>{};
    final genders = <String>{};
    final statuses = <String>{};
    for (final s in _services) {
      if (s.category.isNotEmpty) categories.add(s.category);
      if (s.applicableGender.isNotEmpty) genders.add(s.applicableGender);
      if (s.status.isNotEmpty) statuses.add(s.status);
    }
    final sorted = (Set<String> s) => s.toList()..sort();
    return (sorted(categories), sorted(genders), sorted(statuses));
  }

  List<ServiceListItem> _applyFilters(List<ServiceListItem> data) {
    final query = _searchController.text.trim().toLowerCase();
    return data.where((service) {
      final matchesQuery = query.isEmpty ||
          service.name.toLowerCase().contains(query) ||
          service.category.toLowerCase().contains(query);

      final matchesCategory =
          _filter.category == null || service.category == _filter.category;
      final matchesGender = _filter.applicableGender == null ||
          service.applicableGender == _filter.applicableGender;
      final matchesStatus =
          _filter.status == null || service.status == _filter.status;

      return matchesQuery && matchesCategory && matchesGender && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices = _applyFilters(_services);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Services",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openCreateService,
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
                Expanded(child: _body(filteredServices)),
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
      hintText: "Search services",
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
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
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

  Widget _body(List<ServiceListItem> data) {
    if (_loading) {
      return const ServiceListShimmer();
    }

    if (_error != null) {
      return NetworkStateView(
        isOffline: _isOffline,
        message: _error,
        onRetry: _loadServices,
      );
    }

    if (data.isEmpty) {
      final hasActiveSearchOrFilter =
          _searchController.text.trim().isNotEmpty || !_filter.isEmpty;
      return Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: AnimatedEmptyState(
            icon: Icons.design_services_outlined,
            title: _services.isEmpty ? "No Services Found" : "No Matches Found",
            message: _services.isEmpty
                ? "Add a service to start offering it to customers."
                : hasActiveSearchOrFilter
                    ? "Try a different search term or adjust your filters."
                    : "Try a different search term.",
            height: MediaQuery.of(context).size.height * 0.45,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadServices(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        padding: const EdgeInsets.only(bottom: 80), // space for FAB
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSpacing.verticalMedium),
        itemBuilder: (context, index) {
          final service = data[index];
          return _ServiceCard(
            service: service,
            onTap: () => _openServiceDetail(service),
          );
        },
      ),
    );
  }
}

/// Service list tile — same card shell (Material/Ink, radius, border,
/// shadow, avatar leading) as `BranchListPage._BranchCard`, laid out
/// for a service's own fields (name, category/gender tags, duration,
/// price, status) rather than a branch's address.
class _ServiceCard extends StatelessWidget {
  final ServiceListItem service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  static const Map<String, IconData> _categoryIcons = {
    'hair': Icons.content_cut,
    'facial': Icons.face_retouching_natural,
    'nail': Icons.back_hand_outlined,
    'spa': Icons.spa_outlined,
    'makeup': Icons.brush_outlined,
  };

  IconData get _categoryIcon =>
      _categoryIcons[service.category.toLowerCase()] ??
      Icons.design_services_outlined;

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
                      Text(service.name,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${service.category} • ${service.durationMinutes} min',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${service.customerPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _tag(service.applicableGender, Icons.wc_outlined),
                          const SizedBox(width: 8),
                          StatusBadge(status: service.status),
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

  /// Shows the service photo when available; otherwise falls back to a
  /// category icon avatar — same fallback pattern as
  /// `BranchListPage._logoAvatar`.
  Widget _photoAvatar() {
    if (service.hasPhoto) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        backgroundImage: NetworkImage(service.photo!),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: Icon(_categoryIcon, color: AppColors.primary),
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
