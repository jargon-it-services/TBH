import 'package:flutter/material.dart';

import '../../core/connectivity/connectivity_aware_refresh.dart';
import '../../core/models/user_role.dart';
import '../../core/network/apis/branches_api.dart';
import '../../core/network/apis/payslip_api.dart';
import '../../core/services/DataModels/branch_model.dart';
import '../../core/services/DataModels/payslip_list_model.dart';
import '../../core/services/DataModels/pnl_report_model.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/InitialsAvatar.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/app_bar_action_button.dart';
import '../../core/widgets/app_search_bar.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/multi_select_field.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/salary_rule_list_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import '../reports/widgets/report_segment_selector.dart';
import 'payslip_create_page.dart';
import 'payslip_details_page.dart';
import 'widgets/payslip_filter_sheet.dart';

/// Payslip List screen — follows the existing Transaction List UI
/// pattern throughout (see module spec §1): status segment toggle
/// (reusing `ReportSegmentSelector`, same widget Reports/PnL/Payment
/// Mode already use for their period toggle), branch selection
/// (reusing `MultiSelectField`, same widget the Service module already
/// uses for multi-branch assignment), the Transaction List's
/// Search+Filter bar shape (`AppSearchBar` + a filter button opening a
/// bottom sheet — here, Month/Year), and the Transaction Card shell for
/// each payslip.
class PayslipListPage extends StatefulWidget {
  const PayslipListPage({super.key});

  @override
  State<PayslipListPage> createState() => _PayslipListPageState();
}

class _PayslipListPageState extends State<PayslipListPage>
    with ConnectivityAwareRefresh<PayslipListPage> {
  static const List<PnlPeriodOption> _statusSegments = [
    PnlPeriodOption(key: 'all', label: 'All'),
    PnlPeriodOption(key: 'generated', label: 'Generated'),
    PnlPeriodOption(key: 'approved', label: 'Approved'),
    PnlPeriodOption(key: 'rejected', label: 'Rejected'),
    PnlPeriodOption(key: 'paid', label: 'Paid'),
  ];

  final TextEditingController _searchController = TextEditingController();
  final PayslipApi _api = PayslipApi();
  final BranchesApi _branchesApi = BranchesApi();

  bool _loading = true;
  String? _error;
  bool _isOffline = false;

  List<PayslipListItem> _payslips = [];
  List<BranchModel> _branches = [];

  String _statusKey = 'all';
  Set<int> _selectedBranchIds = {};
  PayslipFilter _filter = const PayslipFilter();

  bool _selectionMode = false;
  final Set<int> _selectedIds = {};
  bool _bulkActing = false;

  UserRole get _role => SessionManager.instance.role;
  bool get _canManage =>
      _role == UserRole.accountAdmin || _role == UserRole.branchAdmin;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Future<void> onReconnected() => _loadAll(silent: true);

  Future<void> _loadAll({bool silent = false}) async {
    setState(() {
      if (!silent && _payslips.isEmpty) _loading = true;
      _error = null;
    });

    // Fetched sequentially (rather than Future.wait) since the two
    // calls return differently-typed ApiResponse<T>s — keeps the
    // generic types exact instead of leaning on LUB inference.
    final payslipResponse = await _api.fetchPayslipList();
    final branchResponse = await _branchesApi.fetchBranches();

    if (!mounted) return;

    lastLoadFailedDueToConnectivity =
        !payslipResponse.isSuccess && payslipResponse.isConnectivityError;

    if (branchResponse.isSuccess && branchResponse.data != null) {
      _branches = branchResponse.data!;
    }

    if (payslipResponse.isSuccess) {
      setState(() {
        _payslips = payslipResponse.data ?? [];
        _loading = false;
        _isOffline = false;
      });
    } else {
      setState(() {
        _loading = false;
        if (_payslips.isEmpty) {
          _error = payslipResponse.error ??
              "We couldn't load payslips right now. Please try again.";
          _isOffline = payslipResponse.isConnectivityError;
        }
      });
    }
  }

  bool get _isSearchOrFilterActive =>
      _searchController.text.trim().isNotEmpty ||
      _selectedBranchIds.isNotEmpty ||
      !_filter.isEmpty;

  List<PayslipListItem> get _filteredPayslips {
    final query = _searchController.text.trim().toLowerCase();
    return _payslips.where((p) {
      if (_statusKey != 'all' && p.status.toLowerCase() != _statusKey) {
        return false;
      }
      if (_selectedBranchIds.isNotEmpty &&
          !_selectedBranchIds.contains(p.branchId)) {
        return false;
      }
      if (_filter.month != null && p.month != _filter.month) return false;
      if (_filter.year != null && p.year != _filter.year) return false;
      if (query.isNotEmpty && !p.employeeName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ---------------- SELECTION MODE ----------------

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelected(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// Statuses of the currently-selected payslips (looked up from
  /// [_payslips], not the possibly-narrower filtered/visible list, so
  /// a selection made before a filter change is still evaluated
  /// correctly).
  List<String> get _selectedStatuses {
    return _payslips
        .where((p) => _selectedIds.contains(p.id))
        .map((p) => p.status.toLowerCase())
        .toList();
  }

  bool get _allSelectedGenerated =>
      _selectedIds.isNotEmpty && _selectedStatuses.every((s) => s == 'generated');

  bool get _allSelectedApproved =>
      _selectedIds.isNotEmpty && _selectedStatuses.every((s) => s == 'approved');

  /// Approve/Reject only make sense when every selected payslip is
  /// still Generated; Mark Paid only when every selected payslip is
  /// already Approved. Any other combination (mixed statuses, or a
  /// status that isn't actionable at all, e.g. Paid/Rejected) leaves
  /// all three bulk actions disabled rather than guessing which ones
  /// might partially apply.
  bool get _canBulkApproveOrReject => _allSelectedGenerated;
  bool get _canBulkMarkPaid => _allSelectedApproved;

  Future<void> _confirmAndRunBulk({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required Future<dynamic> Function(List<int> ids) action,
    required String successMessage,
  }) async {
    if (_selectedIds.isEmpty || _bulkActing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        title: Text(title, style: AppTextStyles.h3),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _bulkActing = true);
    final response = await action(_selectedIds.toList());
    if (!mounted) return;
    setState(() => _bulkActing = false);

    if (response.isSuccess == true) {
      AppSnackbar.success(context, successMessage);
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
      _loadAll(silent: true);
    } else {
      AppSnackbar.error(
        context,
        response.error ?? 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _bulkApprove() {
    if (!_canBulkApproveOrReject) {
      AppSnackbar.warning(context, 'Select only Generated payslips to Approve.');
      return Future.value();
    }
    return _confirmAndRunBulk(
      title: 'Approve Payslips?',
      message:
          'Are you sure you want to approve the ${_selectedIds.length} selected payslip(s)?',
      confirmLabel: 'Approve',
      confirmColor: AppColors.success,
      action: _api.bulkApprovePayslips,
      successMessage: 'Selected payslips approved',
    );
  }

  Future<void> _bulkReject() {
    if (!_canBulkApproveOrReject) {
      AppSnackbar.warning(context, 'Select only Generated payslips to Reject.');
      return Future.value();
    }
    return _confirmAndRunBulk(
      title: 'Reject Payslips?',
      message:
          'Are you sure you want to reject the ${_selectedIds.length} selected payslip(s)?',
      confirmLabel: 'Reject',
      confirmColor: AppColors.error,
      action: _api.bulkRejectPayslips,
      successMessage: 'Selected payslips rejected',
    );
  }

  Future<void> _bulkMarkPaid() {
    if (!_canBulkMarkPaid) {
      AppSnackbar.warning(context, 'Select only Approved payslips to Mark Paid.');
      return Future.value();
    }
    return _confirmAndRunBulk(
      title: 'Mark as Paid?',
      message:
          'Are you sure you want to mark the ${_selectedIds.length} selected payslip(s) as Paid?',
      confirmLabel: 'Mark as Paid',
      confirmColor: AppColors.success,
      action: _api.bulkMarkPayslipsPaid,
      successMessage: 'Selected payslips marked as paid',
    );
  }

  // ---------------- NAVIGATION ----------------

  Future<void> _openCreatePayslip() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PayslipCreatePage()),
    );
    if (created == true) _loadAll(silent: true);
  }

  Future<void> _openDetails(PayslipListItem item) async {
    if (_selectionMode) {
      _toggleSelected(item.id);
      return;
    }
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PayslipDetailsPage(payslipId: item.id)),
    );
    if (changed == true) _loadAll(silent: true);
  }

  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();
    final result = await PayslipFilterSheet.show(
      context,
      current: _filter,
      payslips: _payslips,
    );
    if (result != null) setState(() => _filter = result);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPayslips;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Text(
          _selectionMode
              ? '${_selectedIds.length} Selected'
              : 'Payslips',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.large)),
        ),
        actions: [
          if (_canManage)
            AppBarActionButton(
              tooltip: _selectionMode ? 'Cancel selection' : 'Select payslips',
              icon: _selectionMode ? Icons.close : Icons.checklist_rtl_rounded,
              onPressed: _toggleSelectionMode,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page, AppSpacing.page, AppSpacing.page, 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReportSegmentSelector(
                    periods: _statusSegments,
                    selectedKey: _statusKey,
                    onChanged: (key) => setState(() => _statusKey = key),
                  ),
                  const SizedBox(height: AppSpacing.verticalSmall),
                  MultiSelectField(
                    label: 'Branch',
                    icon: Icons.storefront_outlined,
                    options: _branches
                        .map((b) => MultiSelectOption(id: b.id, label: b.name))
                        .toList(),
                    selectedIds: _selectedBranchIds,
                    onChanged: (ids) {
                      setState(() => _selectedBranchIds = ids);
                    },
                    emptyHint: 'All branches',
                    sheetTitle: 'Select Branch(es)',
                  ),
                  const SizedBox(height: AppSpacing.verticalMedium),
                  AppSearchBar(
                    controller: _searchController,
                    hintText: 'Search employee',
                    onChanged: (_) => setState(() {}),
                    trailing: _filterButton(),
                  ),
                  const SizedBox(height: AppSpacing.verticalMedium),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: _body(filtered),
              ),
            ),
            if (_selectionMode) _bulkActionBar(),
            if (!_selectionMode) const SizedBox(height: AppSpacing.verticalSmall),
          ],
        ),
      ),
      floatingActionButton: (_canManage && !_selectionMode)
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: _openCreatePayslip,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
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

  Widget _bulkActionBar() {
    final hasSelection = _selectedIds.isNotEmpty;
    final canApproveOrReject = _canBulkApproveOrReject;
    final canMarkPaid = _canBulkMarkPaid;
    // Selection exists but doesn't satisfy either rule (empty selection
    // isn't "invalid" — nothing to hint about yet).
    final showMixedHint = hasSelection && !canApproveOrReject && !canMarkPaid;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page, AppSpacing.verticalSmall, AppSpacing.page, AppSpacing.verticalSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: _bulkActing
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showMixedHint)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.verticalSmall),
                    child: Text(
                      'Select payslips that are all Generated (to Approve/Reject) or all Approved (to Mark Paid).',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: canApproveOrReject ? _bulkReject : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.horizontalSmall),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: canApproveOrReject ? _bulkApprove : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.horizontalSmall),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canMarkPaid ? _bulkMarkPaid : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                        ),
                        child: const Text('Mark Paid', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _body(List<PayslipListItem> data) {
    if (_loading) return const SalaryRuleListShimmer();

    if (_error != null) {
      return NetworkStateView(isOffline: _isOffline, message: _error, onRetry: _loadAll);
    }

    if (data.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: AnimatedEmptyState(
            icon: Icons.receipt_long_outlined,
            title: _payslips.isEmpty ? 'No Payslips Found' : 'No Matches Found',
            message: _payslips.isEmpty
                ? (_canManage
                    ? 'Generate a payslip to get started.'
                    : 'Payslips will show up here once generated.')
                : _isSearchOrFilterActive
                    ? 'Try a different search term or adjust your filters.'
                    : 'Try a different search term.',
            height: MediaQuery.of(context).size.height * 0.4,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadAll(silent: true),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: data.length,
        padding: const EdgeInsets.only(bottom: 80),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.verticalMedium),
        itemBuilder: (context, index) => _payslipCard(data[index]),
      ),
    );
  }

  /// Same card shell as `TransactionsPage._transactionCard`.
  Widget _payslipCard(PayslipListItem item) {
    final isSelected = _selectedIds.contains(item.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: () => _openDetails(item),
        onLongPress: _canManage
            ? () {
                if (!_selectionMode) setState(() => _selectionMode = true);
                _toggleSelected(item.id);
              }
            : null,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Row(
              children: [
                if (_selectionMode) ...[
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.horizontalSmall),
                ],
                item.hasPhoto
                    ? CircleAvatar(radius: 24, backgroundImage: NetworkImage(item.photo!))
                    : InitialsAvatar(name: item.employeeName, radius: 24),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.employeeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          StatusBadge(status: item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.designation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${item.amount.toStringAsFixed(0)}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(item.monthYearLabel, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                if (!_selectionMode)
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
