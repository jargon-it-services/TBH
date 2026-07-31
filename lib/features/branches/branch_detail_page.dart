import 'package:flutter/material.dart';

import '../../core/network/apis/branches_api.dart';
import '../../core/services/DataModels/branch_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/InitialsAvatar.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/branch_detail_shimmer.dart';
import '../../core/widgets/static_map_preview.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_branch_page.dart';

/// Branch Details screen — visual hierarchy mirrors
/// `TransactionDetailsPage` (a colored "headline" status card up top,
/// then a stack of `InfoCard`/`CardWrapper` sections below) rather than
/// its previous plain header + info-card list, per the Branch module
/// spec.
class BranchDetailPage extends StatefulWidget {
  final int branchId;

  const BranchDetailPage({super.key, required this.branchId});

  @override
  State<BranchDetailPage> createState() => _BranchDetailPageState();
}

class _BranchDetailPageState extends State<BranchDetailPage> {
  final BranchesApi _api = BranchesApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;
  BranchDetailResponse? _data;

  // Tracks whether anything changed (an edit was saved) so the list
  // screen knows to silently refresh when this page is popped.
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await _api.fetchBranchDetail(widget.branchId);
    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      setState(() {
        _data = response.data!;
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.error ?? "Failed to load branch details";
        _isOffline = response.isConnectivityError;
      });
    }
  }

  Future<void> _openEdit() async {
    if (_data == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditBranchPage(existing: _data),
      ),
    );
    if (updated == true) {
      _didChange = true;
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _didChange);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'Branch Details',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _didChange),
          ),
          actions: [
            if (_data != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: _openEdit,
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const BranchDetailShimmer();

    if (_error != null) {
      return NetworkStateView(
        isOffline: _isOffline,
        message: _error,
        onRetry: _loadData,
      );
    }

    final branch = _data!;

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headlineCard(branch),
            const SizedBox(height: AppSpacing.verticalLarge),
            InfoCard(
              title: "Contact Information",
              titleIcon: Icons.contact_page_outlined,
              isAccordion: true,
              initiallyExpanded: true,
              rows: [
                InfoRowData(
                  icon: Icons.phone_iphone_outlined,
                  label: "Mobile",
                  value: branch.mobile.isEmpty ? '-' : branch.mobile,
                ),
                InfoRowData(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: branch.email.isEmpty ? '-' : branch.email,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            _locationCard(branch),
            const SizedBox(height: AppSpacing.verticalLarge),
            InfoCard(
              title: "Working Hours",
              titleIcon: Icons.schedule_outlined,
              isAccordion: true,
              initiallyExpanded: true,
              rows: [
                InfoRowData(
                  icon: Icons.login_outlined,
                  label: "Opening Time",
                  value: branch.openingTime.isEmpty ? '-' : branch.openingTime,
                ),
                InfoRowData(
                  icon: Icons.logout_outlined,
                  label: "Closing Time",
                  value: branch.closingTime.isEmpty ? '-' : branch.closingTime,
                ),
                InfoRowData(
                  icon: Icons.event_busy_outlined,
                  label: "Weekly Off",
                  value: branch.weeklyOffDisplay,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.verticalLarge),
            _servicesCard(branch),
            const SizedBox(height: AppSpacing.verticalLarge),
            _staffCard(branch),
          ],
        ),
      ),
    );
  }

  /// Colored "headline" card — same visual role as
  /// `TransactionDetailsPage._buildStatusCard` (a tinted-primary
  /// container up top carrying the record's status front and center)
  /// but built around the branch's name/logo/type instead of a payment
  /// status.
  Widget _headlineCard(BranchDetailResponse branch) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _logoAvatar(branch),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(branch.name, style: AppTextStyles.h3),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (branch.branchType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          branch.branchType,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    StatusBadge(status: branch.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the uploaded branch logo when available; otherwise keeps the
  /// existing store icon avatar unchanged.
  Widget _logoAvatar(BranchDetailResponse branch) {
    if (branch.hasLogo) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        backgroundImage: NetworkImage(branch.logo!),
      );
    }
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: const Icon(Icons.store_mall_directory_outlined,
          color: AppColors.primary, size: 26),
    );
  }

  Widget _locationCard(BranchDetailResponse branch) {
    final hasCoordinates = branch.latitude != null && branch.longitude != null;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.primary),
              SizedBox(width: AppSpacing.iconText),
              Text("Location", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          Text(
            branch.fullAddress.isEmpty ? '-' : branch.fullAddress,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (hasCoordinates) ...[
            StaticMapPreview(
              latitude: branch.latitude!,
              longitude: branch.longitude!,
            ),
            const SizedBox(height: AppSpacing.verticalSmall),
            Text(
              "${branch.latitude!.toStringAsFixed(5)}, ${branch.longitude!.toStringAsFixed(5)}",
              style: AppTextStyles.caption,
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(AppSpacing.verticalMedium),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Location not set for this branch yet.",
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _servicesCard(BranchDetailResponse branch) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.design_services_outlined,
                  color: AppColors.primary),
              const SizedBox(width: AppSpacing.iconText),
              Text("Services", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (branch.services.isEmpty)
            Text(
              "No services assigned to this branch yet.",
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: branch.services
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Text(
                        s.name,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  /// Assigned Staff / Employees — same "Assigned Staff" concept the
  /// spec asks to mirror from a Service Details-style screen. This app
  /// has no dedicated Employees API of its own (see
  /// `BranchEmployeeItem`'s doc comment), so this renders whatever the
  /// branch details response includes, display-only — there is
  /// deliberately no add/remove affordance here, matching Edit Branch
  /// not being allowed to manage employees either.
  Widget _staffCard(BranchDetailResponse branch) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_outlined, color: AppColors.primary),
              SizedBox(width: AppSpacing.iconText),
              Text("Assigned Staff", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (branch.employees.isEmpty)
            Text(
              "No staff assigned to this branch yet.",
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            )
          else
            ...branch.employees.map(
              (e) => Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSpacing.verticalSmall),
                child: Row(
                  children: [
                    e.photo != null && e.photo!.isNotEmpty
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(e.photo!),
                          )
                        : InitialsAvatar(name: e.name, radius: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name,
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            e.role.isEmpty ? '-' : e.role,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
