import 'package:flutter/material.dart';

import '../../core/network/api_response.dart';
import '../../core/network/apis/transaction_api.dart';
import '../../core/services/DataModels/transaction_details_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/payment_mode_chip.dart';
import '../../core/widgets/shimmers/transaction_details_shimmer.dart';
import '../../core/widgets/status_badge.dart';

class TransactionDetailsPage extends StatefulWidget {
  final String transactionId;

  const TransactionDetailsPage({super.key, required this.transactionId});

  @override
  State<TransactionDetailsPage> createState() => _TransactionDetailsPageState();
}

class _TransactionDetailsPageState extends State<TransactionDetailsPage> {
  final TransactionApi _api = TransactionApi();

  bool _isLoading = false;
  String? _error;

  TransactionDetails? transaction;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ApiResponse<TransactionDetailsResponse> response = await _api
          .fetchTransactionDetails(transactionId: widget.transactionId);

      if (response.isSuccess && response.data != null) {
        transaction = response.data!.transaction;
      } else {
        _error = response.error ?? "Failed to load transaction";
      }
    } catch (e) {
      _error = "Failed to load transaction";
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Transaction Details",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const TransactionDetailsShimmer()
            : _error != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  // ================= CONTENT =================

  Widget _buildContent() {
    if (transaction == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        children: [
          _buildStatusCard(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _buildPriceBreakdown(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _transactionInfoCard(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _firmInfoCard(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _buildNotesCard(),
        ],
      ),
    );
  }

  // ================= STATUS =================

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Row(
        children: [
          const Text("Payment Status", style: AppTextStyles.label),
          const Spacer(),
          StatusBadge(status: transaction!.status),
          const SizedBox(width: AppSpacing.horizontalSmall),
          PaymentModeChip(mode: transaction!.paymentMode),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == "paid"
        ? AppColors.success
        : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.h1.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _paymentModeChip(String mode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        mode.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ================= PRICE BREAKDOWN =================

  Widget _buildPriceBreakdown() {
    final breakdown = transaction!.priceBreakdown;
    final services = breakdown.services;
    final summary = breakdown.summary;
    final coupon = breakdown.coupon;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.currency_rupee, color: AppColors.primary),
              SizedBox(width: AppSpacing.iconText),
              Text("Price Breakdown", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (services.isNotEmpty)
            ...services.map(
              (s) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppSpacing.verticalSmall,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${s.title} x${s.quantity}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _amountText(s.netAmount),
                  ],
                ),
              ),
            ),
          if (services.isNotEmpty)
            const Divider(height: AppSpacing.verticalLarge),
          _amountRow("Subtotal", summary.subtotal),
          if (summary.taxAmount > 0) _amountRow("Tax", summary.taxAmount),
          if (coupon != null && summary.couponDiscount > 0)
            _amountRow(
              "Coupon (${coupon.code})",
              -summary.couponDiscount,
              valueColor: AppColors.success,
            ),
          const Divider(height: AppSpacing.verticalLarge),
          _amountRow(
            "Total Amount",
            summary.total,
            isBold: true,
            valueColor: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  // ================= INFO =================

  Widget _transactionInfoCard() {
    return InfoCard(
      title: "Transaction Information",
      titleIcon: Icons.multiple_stop,
      isAccordion: true, // Makes it expandable
      initiallyExpanded: false, // Open by default
      rows: [
        InfoRowData(
          icon: Icons.tag,
          label: "Transaction ID",
          value: transaction!.id,
        ),
        InfoRowData(
          icon: Icons.type_specimen,
          label: "Type",
          value: transaction!.type,
        ),
        InfoRowData(
          icon: Icons.category,
          label: "Category",
          value: transaction!.category,
        ),
        InfoRowData(
          icon: Icons.calendar_today,
          label: "Date & Time",
          value: transaction!.dateTime.display,
        ),
      ],
    );
  }

  Widget _firmInfoCard() {
    return InfoCard(
      title: "Firm Information",
      titleIcon: Icons.storefront_outlined,
      isAccordion: true, // Makes it expandable
      initiallyExpanded: false, // Open by default
      rows: [
        InfoRowData(
          icon: Icons.store,
          label: "Firm",
          value: transaction!.firm.name,
        ),
        InfoRowData(
          icon: Icons.person,
          label: "Staff Name",
          value: transaction!.staff.name,
        ),
      ],
    );
  }

  Widget _buildNotesCard() {
    final remark = transaction!.remark;
    if (remark == null || remark.isEmpty) return const SizedBox();

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, color: AppColors.primary),
              SizedBox(width: AppSpacing.iconText),
              Text("Remark", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          Text(remark, style: AppTextStyles.body),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _amountRow(
    String label,
    num value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.body),
        const Spacer(),
        _amountText(value, isBold: isBold, color: valueColor),
      ],
    );
  }

  Widget _amountText(num value, {bool isBold = false, Color? color}) {
    return SizedBox(
      width: 110,
      child: Text(
        _formatAmount(value),
        textAlign: TextAlign.end,
        style: AppTextStyles.body.copyWith(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    );
  }

  String _formatAmount(num value) {
    final isNegative = value < 0;
    final amount = value.abs().toStringAsFixed(2);
    return "${isNegative ? '-' : ''}₹$amount";
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: AppSpacing.verticalSmall),
    child: Divider(color: AppColors.divider),
  );

  Widget _buildError() {
    return Center(
      child: Text(_error ?? "Something went wrong", style: AppTextStyles.body),
    );
  }
}
