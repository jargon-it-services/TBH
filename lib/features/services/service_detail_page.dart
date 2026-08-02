import 'package:flutter/material.dart';

import '../../core/network/apis/services_api.dart';
import '../../core/services/DataModels/service_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/InitialsAvatar.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/service_detail_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_service_page.dart';

/// Service Details screen — read view for one service, reached by
/// tapping a card on [ServiceListPage]. Structure mirrors
/// `BranchDetailPage`: a headline block, a stack of [InfoCard]
/// sections, an Edit action, and a Mark Inactive action (in place of a
/// destructive delete) behind a confirmation dialog.
class ServiceDetailPage extends StatefulWidget {
  final int serviceId;

  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  final ServicesApi _api = ServicesApi();

  bool _loading = true;
  bool _isOffline = false;
  String? _error;
  ServiceDetailResponse? _service;
  bool _markingInactive = false;

  /// Set to true the moment an edit actually changes anything, so the
  /// list screen behind us knows to refresh — same pop(true)/pop(false)
  /// contract `BranchDetailPage` uses.
  bool _didChange = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await _api.fetchServiceDetail(widget.serviceId);
    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _service = response.data;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.error ?? "We couldn't load this service's details.";
        _isOffline = response.isConnectivityError;
      });
    }
  }

  Future<void> _openEdit() async {
    if (_service == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditServicePage(existing: _service),
      ),
    );
    if (updated == true) {
      _didChange = true;
      _loadDetail();
    }
  }

  /// Marks this service Inactive without a full Edit round-trip —
  /// confirms, then calls the same `updateService` API Edit Service
  /// uses, sending only the changed field.
  Future<void> _confirmAndMarkInactive() async {
    if (_service == null || _markingInactive) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        title: const Text('Mark this service Inactive?', style: AppTextStyles.h3),
        content: Text(
          '"${_service!.name}" will be marked Inactive and will stop appearing '
          'to customers until reactivated.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Inactive', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _markingInactive = true);
    final response = await _api.updateService(widget.serviceId, {'status': 'Inactive'});
    if (!mounted) return;
    setState(() => _markingInactive = false);

    if (response.isSuccess) {
      AppSnackbar.success(context, 'Service marked Inactive');
      _didChange = true;
      _loadDetail();
    } else {
      AppSnackbar.error(context, response.error ?? 'Failed to update status. Please try again.');
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
          title: Text(
            'Service Details',
            style: AppTextStyles.h2.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _didChange),
          ),
          actions: [
            if (_service != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit Service',
                onPressed: _openEdit,
              ),
          ],
        ),
        body: SafeArea(child: _body()),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.page),
        child: ServiceDetailShimmer(),
      );
    }

    if (_error != null || _service == null) {
      return NetworkStateView(
        isOffline: _isOffline,
        message: _error,
        onRetry: _loadDetail,
      );
    }

    final service = _service!;
    return RefreshIndicator(
      onRefresh: _loadDetail,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _headline(service),
          const SizedBox(height: AppSpacing.verticalLarge),
          InfoCard(
            title: 'Basic Information',
            titleIcon: Icons.info_outline,
            rows: [
              InfoRowData(
                icon: Icons.notes_outlined,
                label: 'Description',
                value: service.description.isEmpty
                    ? 'Not provided'
                    : service.description,
              ),
              InfoRowData(
                icon: Icons.category_outlined,
                label: 'Category',
                value: service.category,
              ),
              InfoRowData(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: '${service.durationMinutes} minutes',
              ),
              InfoRowData(
                icon: Icons.wc_outlined,
                label: 'Applicable Gender',
                value: service.applicableGender,
              ),
              InfoRowData(
                icon: Icons.label_outline,
                label: 'Type',
                value: service.type,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          InfoCard(
            title: 'Pricing & Profit',
            titleIcon: Icons.payments_outlined,
            isAccordion: true,
            initiallyExpanded: true,
            rows: [
              InfoRowData(
                icon: Icons.currency_rupee,
                label: 'Customer Price',
                value: '₹${service.customerPrice.toStringAsFixed(2)}',
              ),
              InfoRowData(
                icon: Icons.inventory_2_outlined,
                label: 'Material Cost',
                value: '₹${service.materialCost.toStringAsFixed(2)}',
              ),
              InfoRowData(
                icon: Icons.percent_outlined,
                label: 'Commission Type',
                value: service.commissionType,
              ),
              InfoRowData(
                icon: Icons.percent_outlined,
                label: 'Commission Value',
                value: service.commissionType == 'Percentage'
                    ? '${service.commissionValue.toStringAsFixed(2)}%'
                    : '₹${service.commissionValue.toStringAsFixed(2)}',
              ),
              InfoRowData(
                icon: Icons.badge_outlined,
                label: 'Staff Commission (Amount)',
                value: '₹${service.staffCommissionAmount.toStringAsFixed(2)}',
              ),
              InfoRowData(
                icon: Icons.receipt_long_outlined,
                label: 'Other Cost',
                value: '₹${service.otherCost.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          _profitSummary(service),
          const SizedBox(height: AppSpacing.verticalMedium),
          InfoCard(
            title: 'Home Service',
            titleIcon: Icons.home_outlined,
            rows: service.homeServiceAvailable
                ? [
                    InfoRowData(
                      icon: Icons.check_circle_outline,
                      label: 'Available',
                      value: 'Yes',
                    ),
                    InfoRowData(
                      icon: Icons.home_outlined,
                      label: 'Home Visit Charges',
                      value:
                          '₹${(service.homeVisitCharges ?? 0).toStringAsFixed(2)}',
                    ),
                    InfoRowData(
                      icon: Icons.social_distance_outlined,
                      label: 'Service Available Within',
                      value: '${service.serviceRadiusKm ?? 0} km',
                    ),
                    InfoRowData(
                      icon: Icons.add_road_outlined,
                      label: 'Extra Charge Per KM',
                      value:
                          '₹${(service.extraChargePerKm ?? 0).toStringAsFixed(2)}',
                    ),
                  ]
                : [
                    InfoRowData(
                      icon: Icons.cancel_outlined,
                      label: 'Available',
                      value: 'No',
                    ),
                  ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          CardWrapper(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store_mall_directory_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: AppSpacing.iconText),
                    Text('Branch Assignment', style: AppTextStyles.h3),
                  ],
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
                if (service.allBranches)
                  Text('All Branches', style: AppTextStyles.body)
                else if (service.branches.isEmpty)
                  Text(
                    'No branches assigned',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: service.branches
                        .map((b) => Chip(
                              label:
                                  Text(b.name, style: AppTextStyles.bodySmall),
                              backgroundColor:
                                  AppColors.secondary.withOpacity(0.1),
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (service.isActive) _markInactiveButton(),
        ],
      ),
    );
  }

  Widget _markInactiveButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _markingInactive ? null : _confirmAndMarkInactive,
        icon: _markingInactive
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
              )
            : const Icon(Icons.block_outlined, color: AppColors.error),
        label: Text(
          _markingInactive ? 'Updating…' : 'Mark Inactive',
          style: const TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        ),
      ),
    );
  }
  /// plain [InfoRowData] row — [InfoCard]'s rows are all styled
  /// identically, but Profit is the one derived, decision-relevant
  /// figure on this screen, so it's called out the same way the
  /// Add/Edit form's live Profit preview is.
  /// Profit gets its own highlighted summary rather than sitting as a
  /// plain [InfoRowData] row — [InfoCard]'s rows are all styled
  /// identically, but Profit is the one derived, decision-relevant
  /// figure on this screen, so it's called out the same way the
  /// Add/Edit form's live Profit preview is.
  Widget _profitSummary(ServiceDetailResponse service) {
    final isNegative = service.profit < 0;
    final color = isNegative ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Profit',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          ),
          Text(
            '₹${service.profit.toStringAsFixed(2)}',
            style: AppTextStyles.h3.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _headline(ServiceDetailResponse service) {
    return CardWrapper(
      child: Row(
        children: [
          service.hasPhoto
              ? CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  backgroundImage: NetworkImage(service.photo!),
                )
              : InitialsAvatar(name: service.name, radius: 30),
          const SizedBox(width: AppSpacing.horizontalMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style:
                        AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _pill(service.category),
                    StatusBadge(status: service.status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
