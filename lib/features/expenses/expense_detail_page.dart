import 'package:flutter/material.dart';

import '../../core/network/apis/expenses_api.dart';
import '../../core/services/DataModels/expense_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_bar_action_button.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/expense_detail_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_expense_page.dart';

/// Expense Details screen — read view for one expense type, reached by
/// tapping a card on [ExpenseListPage]. Structure mirrors
/// `ServiceDetailPage`: a headline block, a stack of [InfoCard]/
/// [CardWrapper] sections, an Edit action, and a Mark Active/Inactive
/// status-toggle action.
class ExpenseDetailPage extends StatefulWidget {
  final int expenseId;

  const ExpenseDetailPage({super.key, required this.expenseId});

  @override
  State<ExpenseDetailPage> createState() => _ExpenseDetailPageState();
}

class _ExpenseDetailPageState extends State<ExpenseDetailPage> {
  final ExpensesApi _api = ExpensesApi();

  bool _loading = true;
  bool _isOffline = false;
  String? _error;
  ExpenseDetailResponse? _expense;
  bool _markingInactive = false;

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

    final response = await _api.fetchExpenseDetail(widget.expenseId);
    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _expense = response.data;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.error ?? "We couldn't load this expense's details.";
        _isOffline = response.isConnectivityError;
      });
    }
  }

  Future<void> _openEdit() async {
    if (_expense == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditExpensePage(existing: _expense)),
    );
    if (updated == true) {
      _didChange = true;
      _loadDetail();
    }
  }

  /// Toggles this expense's status between Active and Inactive without
  /// a full Edit round-trip — confirms, then calls the same
  /// `updateExpense` API Edit Expense uses, sending only the changed
  /// field.
  Future<void> _confirmAndToggleStatus() async {
    if (_expense == null || _markingInactive) return;

    final goingInactive = _expense!.isActive;
    final targetStatus = goingInactive ? 'Inactive' : 'Active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        title: Text('Mark this expense $targetStatus?', style: AppTextStyles.h3),
        content: Text(
          goingInactive
              ? '"${_expense!.name}" will be marked Inactive and unavailable for use '
                  'until reactivated.'
              : '"${_expense!.name}" will be marked Active and available for use again.',
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
    final response = await _api.updateExpense(widget.expenseId, {'status': targetStatus});
    if (!mounted) return;
    setState(() => _markingInactive = false);

    if (response.isSuccess) {
      AppSnackbar.success(context, 'Expense marked $targetStatus');
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
          title: Text('Expense Details', style: AppTextStyles.h2.copyWith(color: Colors.white)),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _didChange),
          ),
          actions: [
            if (_expense != null)
              AppBarActionButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit Expense',
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
        child: ExpenseDetailShimmer(),
      );
    }

    if (_error != null || _expense == null) {
      return NetworkStateView(isOffline: _isOffline, message: _error, onRetry: _loadDetail);
    }

    final expense = _expense!;
    return RefreshIndicator(
      onRefresh: _loadDetail,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _headline(expense),
          const SizedBox(height: AppSpacing.verticalLarge),
          InfoCard(
            title: 'Basic Information',
            titleIcon: Icons.info_outline,
            rows: [
              InfoRowData(
                icon: Icons.notes_outlined,
                label: 'Description',
                value: expense.description.isEmpty ? 'Not provided' : expense.description,
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
                    const Icon(Icons.store_mall_directory_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.iconText),
                    Text('Branch Assignment', style: AppTextStyles.h3),
                  ],
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
                if (expense.allBranches)
                  Text('All Branches', style: AppTextStyles.body)
                else if (expense.branches.isEmpty)
                  Text(
                    'No branches assigned',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: expense.branches
                        .map((b) => Chip(
                              label: Text(b.name, style: AppTextStyles.bodySmall),
                              backgroundColor: AppColors.secondary.withOpacity(0.1),
                              side: BorderSide.none,
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.verticalLarge),
          _statusToggleButton(expense),
          const SizedBox(height: AppSpacing.verticalMedium),
        ],
      ),
    );
  }

  Widget _statusToggleButton(ExpenseDetailResponse expense) {
    final goingInactive = expense.isActive;
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

  Widget _headline(ExpenseDetailResponse expense) {
    return CardWrapper(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.horizontalMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.name, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                StatusBadge(status: expense.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
