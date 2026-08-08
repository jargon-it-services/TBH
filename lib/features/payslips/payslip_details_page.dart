import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/user_role.dart';
import '../../core/network/apis/payslip_api.dart';
import '../../core/services/DataModels/payslip_detail_model.dart';
import '../../core/session/session_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/InitialsAvatar.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/shimmers/transaction_details_shimmer.dart';
import '../../core/widgets/status_badge.dart';

/// Payslip Details screen (module spec §5/§6). Layout follows the
/// attached reference design: employee header, Earnings, Deductions,
/// Net Salary, then the Generated/Approved/Rejected/Paid By audit trail
/// (§5.1), then status- and role-based actions (§6). Structurally
/// mirrors `TransactionDetailsPage` — same shimmer/error handling,
/// `CardWrapper`/`InfoCard` building blocks, and inline
/// `showDialog`-based confirmation before every state-changing action.
class PayslipDetailsPage extends StatefulWidget {
  final int payslipId;

  const PayslipDetailsPage({super.key, required this.payslipId});

  @override
  State<PayslipDetailsPage> createState() => _PayslipDetailsPageState();
}

class _PayslipDetailsPageState extends State<PayslipDetailsPage> {
  final PayslipApi _api = PayslipApi();

  bool _isLoading = true;
  String? _error;
  bool _acting = false;

  /// True once any status-changing action has succeeded, so the list
  /// screen behind this one knows to refresh (same `Navigator.pop(...,
  /// true)` convention `SalaryRuleDetailPage`/`TransactionDetailsPage`
  /// already use).
  bool _changed = false;

  PayslipDetailResponse? payslip;

  UserRole get _role => SessionManager.instance.role;
  bool get _canManage =>
      _role == UserRole.accountAdmin || _role == UserRole.branchAdmin;

  @override
  void initState() {
    super.initState();
    _loadPayslip();
  }

  Future<void> _loadPayslip() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await _api.fetchPayslipDetails(widget.payslipId);
    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      payslip = response.data;
    } else {
      _error = response.error ?? "Failed to load payslip";
    }
    setState(() => _isLoading = false);
  }

  // ---------------- ACTIONS ----------------

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pageBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        title: Text(title, style: AppTextStyles.h3),
        content: Text(message, style: AppTextStyles.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _runAction(
    Future<dynamic> Function() call,
    String successMessage,
  ) async {
    if (_acting) return;
    setState(() => _acting = true);
    final response = await call();
    if (!mounted) return;
    setState(() => _acting = false);

    if (response.isSuccess == true) {
      AppSnackbar.success(context, successMessage);
      _changed = true;
      _loadPayslip();
    } else {
      AppSnackbar.error(context, response.error ?? 'Something went wrong. Please try again.');
    }
  }

  Future<void> _approve() async {
    final confirmed = await _confirm(
      title: 'Approve Payslip?',
      message: 'Are you sure you want to approve this payslip?',
      confirmLabel: 'Confirm',
      confirmColor: AppColors.success,
    );
    if (confirmed != true) return;
    _runAction(() => _api.approvePayslip(widget.payslipId), 'Payslip approved');
  }

  Future<void> _reject() async {
    final confirmed = await _confirm(
      title: 'Reject Payslip?',
      message: 'Are you sure you want to reject this payslip?',
      confirmLabel: 'Confirm',
      confirmColor: AppColors.error,
    );
    if (confirmed != true) return;
    _runAction(() => _api.rejectPayslip(widget.payslipId), 'Payslip rejected');
  }

  Future<void> _markPaid() async {
    final confirmed = await _confirm(
      title: 'Mark as Paid?',
      message: 'Are you sure you want to mark this payslip as Paid?',
      confirmLabel: 'Confirm',
      confirmColor: AppColors.success,
    );
    if (confirmed != true) return;
    _runAction(() => _api.markPayslipPaid(widget.payslipId), 'Payslip marked as paid');
  }

  Future<void> _download() async {
    final url = payslip?.downloadUrl;
    if (url == null || url.trim().isEmpty) {
      AppSnackbar.info(context, 'Download link is not available yet.');
      return;
    }
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
          title: Text('Payslip Details', style: AppTextStyles.h2.copyWith(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const TransactionDetailsShimmer()
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Text(_error ?? 'Something went wrong', style: AppTextStyles.body));
  }

  Widget _buildContent() {
    final p = payslip;
    if (p == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        children: [
          _headerCard(p),
          const SizedBox(height: AppSpacing.verticalLarge),
          _earningsCard(p),
          const SizedBox(height: AppSpacing.verticalLarge),
          _deductionsCard(p),
          const SizedBox(height: AppSpacing.verticalLarge),
          _netSalaryCard(p),
          const SizedBox(height: AppSpacing.verticalLarge),
          _statusByCard(p),
          const SizedBox(height: AppSpacing.verticalLarge),
          _statusActions(p),
        ],
      ),
    );
  }

  Widget _headerCard(PayslipDetailResponse p) {
    return CardWrapper(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          p.photo != null && p.photo!.trim().isNotEmpty
              ? CircleAvatar(radius: 28, backgroundImage: NetworkImage(p.photo!))
              : InitialsAvatar(name: p.employeeName, radius: 28),
          const SizedBox(width: AppSpacing.horizontalMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.employeeName, style: AppTextStyles.h3),
                const SizedBox(height: 2),
                Text(p.designation, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(p.monthYearLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge(status: p.status),
        ],
      ),
    );
  }

  Widget _earningsCard(PayslipDetailResponse p) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: AppColors.primary),
              SizedBox(width: AppSpacing.iconText),
              Text('Earnings', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          for (final line in p.earnings) _amountRow(line.label, line.amount),
          const Divider(height: AppSpacing.verticalLarge),
          _amountRow('Total Earnings', p.totalEarnings, isBold: true, valueColor: AppColors.success),
        ],
      ),
    );
  }

  Widget _deductionsCard(PayslipDetailResponse p) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_down_rounded, color: AppColors.primary),
              SizedBox(width: AppSpacing.iconText),
              Text('Deductions', style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          for (final line in p.deductions) _amountRow(line.label, line.amount),
          const Divider(height: AppSpacing.verticalLarge),
          _amountRow('Total Deductions', p.totalDeductions, isBold: true, valueColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _netSalaryCard(PayslipDetailResponse p) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        children: [
          const Text('Net Salary', style: AppTextStyles.label),
          const Spacer(),
          Text(
            '₹${p.netSalary.toStringAsFixed(0)}',
            style: AppTextStyles.h2.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  /// Generated/Approved/Rejected/Paid By (§5.1) — only rows with an
  /// actual value are shown, so a payslip that's still `Generated`
  /// never shows an empty "Approved By: —" line.
  Widget _statusByCard(PayslipDetailResponse p) {
    final rows = <InfoRowData>[
      if (p.generatedBy != null && p.generatedBy!.trim().isNotEmpty)
        InfoRowData(icon: Icons.playlist_add_check_circle_outlined, label: 'Generated By', value: p.generatedBy!),
      if (p.approvedBy != null && p.approvedBy!.trim().isNotEmpty)
        InfoRowData(icon: Icons.check_circle_outline, label: 'Approved By', value: p.approvedBy!),
      if (p.rejectedBy != null && p.rejectedBy!.trim().isNotEmpty)
        InfoRowData(icon: Icons.cancel_outlined, label: 'Rejected By', value: p.rejectedBy!),
      if (p.paidBy != null && p.paidBy!.trim().isNotEmpty)
        InfoRowData(icon: Icons.payments_outlined, label: 'Paid By', value: p.paidBy!),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return InfoCard(
      title: 'Payslip Information',
      titleIcon: Icons.info_outline,
      rows: rows,
    );
  }

  Widget _statusActions(PayslipDetailResponse p) {
    // Rejected — view-only, no actions (§6).
    if (p.isRejected) return const SizedBox.shrink();

    // Paid — Download, available to all roles (§6).
    if (p.isPaid) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _download,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Download'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
          ),
        ),
      );
    }

    // Everything below is role-gated to Account Admin / Branch Admin.
    if (!_canManage) return const SizedBox.shrink();

    // Approved — Paid only.
    if (p.isApproved) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _acting ? null : _markPaid,
          icon: _acting
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle_outline, color: Colors.white),
          label: Text(_acting ? 'Marking as Paid…' : 'Mark as Paid',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
          ),
        ),
      );
    }

    // Generated — Approve + Reject.
    if (p.isGenerated) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _acting ? null : _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: AppSpacing.horizontalMedium),
          Expanded(
            child: ElevatedButton(
              onPressed: _acting ? null : _approve,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
              child: const Text('Approve', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _amountRow(String label, num value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: AppTextStyles.body.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
