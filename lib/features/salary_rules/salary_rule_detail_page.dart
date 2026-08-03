import 'package:flutter/material.dart';

import '../../core/network/apis/salary_rules_api.dart';
import '../../core/services/DataModels/salary_rule_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/salary_rule_detail_shimmer.dart';
import '../../core/widgets/status_badge.dart';
import 'add_edit_salary_rule_page.dart';

/// Salary Rule Details screen — read view for one salary rule, reached
/// by tapping a card on [SalaryRuleListPage]. Structure mirrors
/// `ExpenseDetailPage`/`ServiceDetailPage`: a headline block, a stack
/// of [InfoCard] sections, an Edit action, and a Mark Active/Inactive
/// status-toggle action.
class SalaryRuleDetailPage extends StatefulWidget {
  final int ruleId;

  const SalaryRuleDetailPage({super.key, required this.ruleId});

  @override
  State<SalaryRuleDetailPage> createState() => _SalaryRuleDetailPageState();
}

class _SalaryRuleDetailPageState extends State<SalaryRuleDetailPage> {
  final SalaryRulesApi _api = SalaryRulesApi();

  bool _loading = true;
  bool _isOffline = false;
  String? _error;
  SalaryRuleDetailResponse? _rule;
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

    final response = await _api.fetchSalaryRuleDetail(widget.ruleId);
    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _rule = response.data;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.error ?? "We couldn't load this salary rule's details.";
        _isOffline = response.isConnectivityError;
      });
    }
  }

  Future<void> _openEdit() async {
    if (_rule == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditSalaryRulePage(existing: _rule)),
    );
    if (updated == true) {
      _didChange = true;
      _loadDetail();
    }
  }

  Future<void> _confirmAndToggleStatus() async {
    if (_rule == null || _markingInactive) return;

    final goingInactive = _rule!.isActive;
    final targetStatus = goingInactive ? 'Inactive' : 'Active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        title: Text('Mark this salary rule $targetStatus?', style: AppTextStyles.h3),
        content: Text(
          goingInactive
              ? '"${_rule!.name}" will be marked Inactive and won\'t be assignable to '
                  'staff until reactivated.'
              : '"${_rule!.name}" will be marked Active and assignable to staff again.',
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
    final response = await _api.updateSalaryRule(widget.ruleId, {'status': targetStatus});
    if (!mounted) return;
    setState(() => _markingInactive = false);

    if (response.isSuccess) {
      AppSnackbar.success(context, 'Salary rule marked $targetStatus');
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
          title: Text('Salary Rule Details', style: AppTextStyles.h2.copyWith(color: Colors.white)),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _didChange),
          ),
          actions: [
            if (_rule != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit Salary Rule',
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
        child: SalaryRuleDetailShimmer(),
      );
    }

    if (_error != null || _rule == null) {
      return NetworkStateView(isOffline: _isOffline, message: _error, onRetry: _loadDetail);
    }

    final rule = _rule!;

    return RefreshIndicator(
      onRefresh: _loadDetail,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          _headline(rule),
          const SizedBox(height: AppSpacing.verticalLarge),
          InfoCard(
            title: 'Basic Information',
            titleIcon: Icons.info_outline,
            rows: [
              InfoRowData(
                icon: Icons.notes_outlined,
                label: 'Description',
                value: rule.description.isEmpty ? 'Not provided' : rule.description,
              ),
              InfoRowData(
                icon: Icons.rule_folder_outlined,
                label: 'Salary Type',
                value: rule.salaryType,
              ),
            ],
          ),
          // Salary Configuration (Fixed Salary) only shows for Fixed
          // Salary / Hybrid — Service Commission has nothing to
          // configure here, since commission is already configured
          // per-Service in the Service module.
          if (rule.showSalaryConfiguration) ...[
            const SizedBox(height: AppSpacing.verticalMedium),
            InfoCard(
              title: 'Salary Configuration',
              titleIcon: Icons.payments_outlined,
              isAccordion: true,
              initiallyExpanded: true,
              rows: [
                InfoRowData(
                  icon: Icons.currency_rupee,
                  label: 'Fixed Salary',
                  value: '₹${(rule.fixedSalary ?? 0).toStringAsFixed(2)}',
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.verticalMedium),
          InfoCard(
            title: 'Bonus',
            titleIcon: Icons.card_giftcard_outlined,
            rows: [
              InfoRowData(
                icon: Icons.flag_outlined,
                label: 'Monthly Target',
                value: rule.monthlyTarget == null
                    ? 'Not set'
                    : '₹${rule.monthlyTarget!.toStringAsFixed(2)}',
              ),
              InfoRowData(
                icon: Icons.card_giftcard_outlined,
                label: 'Bonus',
                value: rule.targetBonus == null
                    ? 'Not set'
                    : '₹${rule.targetBonus!.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          InfoCard(
            title: 'Advance Recovery',
            titleIcon: Icons.savings_outlined,
            rows: rule.allowAdvanceRecovery
                ? [
                    InfoRowData(icon: Icons.check_circle_outline, label: 'Allowed', value: 'Yes'),
                    InfoRowData(
                      icon: Icons.savings_outlined,
                      label: 'Maximum Recovery Per Month',
                      value: rule.maxRecoveryPerMonth == null
                          ? 'Not set'
                          : '₹${rule.maxRecoveryPerMonth!.toStringAsFixed(2)}',
                    ),
                  ]
                : [InfoRowData(icon: Icons.cancel_outlined, label: 'Allowed', value: 'No')],
          ),
          const SizedBox(height: AppSpacing.verticalLarge),
          _statusToggleButton(rule),
          const SizedBox(height: AppSpacing.verticalMedium),
        ],
      ),
    );
  }

  Widget _statusToggleButton(SalaryRuleDetailResponse rule) {
    final goingInactive = rule.isActive;
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

  Widget _headline(SalaryRuleDetailResponse rule) {
    return CardWrapper(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: const Icon(Icons.rule_folder_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.horizontalMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.name, style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _pill(rule.salaryType),
                    StatusBadge(status: rule.status),
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
