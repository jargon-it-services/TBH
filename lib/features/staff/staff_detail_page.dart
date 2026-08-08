import 'package:flutter/material.dart';

import '../../core/network/apis/staff_api.dart';
import '../../core/services/DataModels/staff_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/InitialsAvatar.dart';
import '../../core/widgets/app_bar_action_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/staff_detail_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_staff_page.dart';

/// Staff Details screen — read view for one staff member, reached by
/// tapping a card on [StaffListPage]. Structure mirrors
/// `ServiceDetailPage`: a headline block, a stack of [InfoCard]
/// sections, an Edit action, and a Mark Active/Inactive status-toggle
/// action (in place of a
/// destructive delete) behind a confirmation dialog.
class StaffDetailPage extends StatefulWidget {
  final int staffId;

  const StaffDetailPage({super.key, required this.staffId});

  @override
  State<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends State<StaffDetailPage> {
  final StaffApi _api = StaffApi();

  bool _loading = true;
  bool _isOffline = false;
  String? _error;
  StaffDetailResponse? _staff;
  bool _markingInactive = false;

  /// Set to true the moment an edit or status change actually changes
  /// anything, so the list screen behind us knows to refresh — same
  /// pop(true)/pop(false) contract `ServiceDetailPage` uses.
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

    final response = await _api.fetchStaffDetail(widget.staffId);
    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _staff = response.data;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.error ?? "We couldn't load this staff member's details.";
        _isOffline = response.isConnectivityError;
      });
    }
  }

  Future<void> _openEdit() async {
    if (_staff == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditStaffPage(existing: _staff)),
    );
    if (updated == true) {
      _didChange = true;
      _loadDetail();
    }
  }

  /// Toggles this staff member's status between Active and Inactive
  /// without a full Edit round-trip — confirms, then calls the same
  /// `updateStaff` API Edit Staff uses, sending only the changed field.
  Future<void> _confirmAndToggleStatus() async {
    if (_staff == null || _markingInactive) return;

    final goingInactive = _staff!.isActive;
    final targetStatus = goingInactive ? 'Inactive' : 'Active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        title: Text('Mark this staff member $targetStatus?', style: AppTextStyles.h3),
        content: Text(
          goingInactive
              ? '"${_staff!.fullName}" will be marked Inactive and may lose '
                  'scheduling/app access until reactivated.'
              : '"${_staff!.fullName}" will be marked Active and will regain '
                  'scheduling/app access.',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Mark $targetStatus',
              style: TextStyle(color: goingInactive ? AppColors.error : AppColors.success),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _markingInactive = true);
    final response = await _api.updateStaff(widget.staffId, {'status': targetStatus});
    if (!mounted) return;
    setState(() => _markingInactive = false);

    if (response.isSuccess) {
      AppSnackbar.success(context, 'Staff member marked $targetStatus');
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
          title: Text('Staff Details', style: AppTextStyles.h2.copyWith(color: Colors.white)),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _didChange),
          ),
          actions: [
            if (_staff != null)
              AppBarActionButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit Staff',
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
        child: StaffDetailShimmer(),
      );
    }

    if (_error != null || _staff == null) {
      return NetworkStateView(isOffline: _isOffline, message: _error, onRetry: _loadDetail);
    }

    final staff = _staff!;
    return RefreshIndicator(
      onRefresh: _loadDetail,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _headline(staff),
          const SizedBox(height: AppSpacing.verticalLarge),
          InfoCard(
            title: 'Personal Information',
            titleIcon: Icons.badge_outlined,
            rows: [
              InfoRowData(icon: Icons.phone_outlined, label: 'Mobile Number', value: staff.mobile),
              InfoRowData(icon: Icons.email_outlined, label: 'Email Address', value: staff.email),
              InfoRowData(icon: Icons.wc_outlined, label: 'Gender', value: staff.gender),
              InfoRowData(
                icon: Icons.credit_card_outlined,
                label: 'Aadhaar Number',
                value: staff.aadhaarNumber.isEmpty ? 'Not provided' : staff.aadhaarNumber,
              ),
              InfoRowData(
                icon: Icons.image_outlined,
                label: 'Aadhaar Card',
                value: staff.hasAadhaarCard ? 'Uploaded' : 'Not uploaded',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          InfoCard(
            title: 'Employment Details',
            titleIcon: Icons.work_outline,
            rows: [
              InfoRowData(icon: Icons.tag_outlined, label: 'Employee Code', value: staff.employeeCode),
              InfoRowData(icon: Icons.event_outlined, label: 'Joining Date', value: staff.joiningDate),
              InfoRowData(icon: Icons.badge_outlined, label: 'Designation', value: staff.designation),
              InfoRowData(icon: Icons.content_cut_outlined, label: 'Specialist', value: staff.specialist),
              InfoRowData(
                icon: Icons.store_mall_directory_outlined,
                label: 'Branch',
                value: staff.branchName,
              ),
              InfoRowData(
                icon: Icons.rule_folder_outlined,
                label: 'Salary Rule',
                value: staff.salaryRuleName,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          InfoCard(
            title: 'Application Access',
            titleIcon: Icons.lock_outline,
            rows: staff.allowAppLogin
                ? [
                    InfoRowData(icon: Icons.check_circle_outline, label: 'App Login', value: 'Enabled'),
                    InfoRowData(icon: Icons.admin_panel_settings_outlined, label: 'App Role', value: staff.appRole),
                    InfoRowData(icon: Icons.alternate_email, label: 'Username', value: staff.username),
                  ]
                : [InfoRowData(icon: Icons.cancel_outlined, label: 'App Login', value: 'Disabled')],
          ),
          const SizedBox(height: AppSpacing.verticalLarge),
          _statusToggleButton(staff),
          const SizedBox(height: AppSpacing.verticalMedium),
        ],
      ),
    );
  }

  Widget _statusToggleButton(StaffDetailResponse staff) {
    final goingInactive = staff.isActive;
    final color = goingInactive ? AppColors.error : AppColors.success;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _markingInactive ? null : _confirmAndToggleStatus,
        icon: _markingInactive
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Icon(
                goingInactive ? Icons.block_outlined : Icons.check_circle_outline,
                color: color,
              ),
        label: Text(
          _markingInactive ? 'Updating…' : (goingInactive ? 'Mark Inactive' : 'Mark Active'),
          style: TextStyle(color: color),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
        ),
      ),
    );
  }

  Widget _headline(StaffDetailResponse staff) {
    return CardWrapper(
      child: Row(
        children: [
          staff.hasPhoto
              ? CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  backgroundImage: NetworkImage(staff.photo!),
                )
              : InitialsAvatar(name: staff.fullName, radius: 30),
          const SizedBox(width: AppSpacing.horizontalMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.fullName, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _pill(staff.designation),
                    StatusBadge(status: staff.status),
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
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
