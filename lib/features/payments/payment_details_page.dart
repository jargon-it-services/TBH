import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_response.dart';
import '../../core/network/apis/payment_history_api.dart';
import '../../core/services/DataModels/payment_details_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/card_wrapper.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/network_state_view.dart';
import '../../core/widgets/shimmers/transaction_details_shimmer.dart';
import '../../core/widgets/status_badge.dart';

/// Transaction Details screen for a single payment.
///
/// Receives only [transactionId] (never the full list-row object --
/// see `PaymentHistoryPage._paymentCard`) and always loads its own
/// fresh copy from `GET /api/v1/payments/{id}`, the same
/// independent-fetch contract `TransactionDetailsPage` already follows
/// for the (separate) service-transaction feature.
class PaymentDetailsPage extends StatefulWidget {
  final String transactionId;

  const PaymentDetailsPage({super.key, required this.transactionId});

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  final PaymentHistoryApi _api = PaymentHistoryApi();

  bool _isLoading = true;
  String? _error;
  bool _isOffline = false;

  PaymentDetails? payment;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final ApiResponse<PaymentDetailsResponse> response = await _api
        .fetchPaymentDetails(paymentId: widget.transactionId);

    if (!mounted) return;

    if (response.isSuccess && response.data != null) {
      payment = response.data!.payment;
      _isOffline = false;
    } else {
      _error = response.error ?? "Failed to load transaction details";
      _isOffline = response.isConnectivityError;
    }

    setState(() => _isLoading = false);
  }

  Future<void> _copyTransactionId() async {
    if (payment == null) return;
    await Clipboard.setData(ClipboardData(text: payment!.id));
    if (!mounted) return;
    AppSnackbar.success(context, "Transaction ID copied to clipboard");
  }

  Future<void> _openLink(String? url, {required String failureLabel}) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      AppSnackbar.error(context, "Couldn't open $failureLabel");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "Payment Details",
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.large),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const TransactionDetailsShimmer()
            : _error != null
            ? NetworkStateView(
                isOffline: _isOffline,
                message: _error,
                onRetry: _loadPayment,
              )
            : _buildContent(),
      ),
    );
  }

  // ================= CONTENT =================

  Widget _buildContent() {
    final p = payment;
    if (p == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadPayment,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryCard(p),
            const SizedBox(height: AppSpacing.verticalLarge),
            _paymentInfoCard(p),
            if (p.reference != null && p.reference!.hasAnyValue) ...[
              const SizedBox(height: AppSpacing.verticalLarge),
              _referenceCard(p.reference!),
            ],
            if (p.billing != null && p.billing!.hasAnyValue) ...[
              const SizedBox(height: AppSpacing.verticalLarge),
              _billingCard(p.billing!),
            ],
            if (p.actions.hasAny) ...[
              const SizedBox(height: AppSpacing.verticalLarge),
              _actions(p.actions),
            ],
          ],
        ),
      ),
    );
  }

  // ================= SUMMARY =================

  Widget _summaryCard(PaymentDetails p) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Transaction ID", style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.id,
                            style: AppTextStyles.h3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _copyTransactionId,
                          icon: const Icon(
                            Icons.copy_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          splashRadius: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: p.status),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Amount Paid", style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(
                    p.formattedAmount,
                    style: AppTextStyles.h2.copyWith(color: AppColors.success),
                  ),
                  if (p.dateDisplay.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Paid on ${p.dateDisplay}",
                      textAlign: TextAlign.end,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= PAYMENT INFORMATION =================

  Widget _paymentInfoCard(PaymentDetails p) {
    final info = p.info;
    return InfoCard(
      title: "Payment Information",
      titleIcon: Icons.receipt_long_outlined,
      rows: [
        if (info.dateTimeDisplay.isNotEmpty)
          InfoRowData(
            icon: Icons.calendar_today,
            label: "Date & Time",
            value: info.dateTimeDisplay,
          ),
        if (info.branch.isNotEmpty)
          InfoRowData(
            icon: Icons.account_balance_outlined,
            label: "Branch",
            value: info.branchCode.isNotEmpty
                ? "${info.branch} (${info.branchCode})"
                : info.branch,
          ),
        if (info.paymentType.isNotEmpty)
          InfoRowData(
            icon: Icons.sell_outlined,
            label: "Payment Type",
            value: info.paymentType,
          ),
        if (info.paymentMethod.isNotEmpty)
          InfoRowData(
            icon: Icons.credit_card_outlined,
            label: "Payment Method",
            value: info.paymentMethod,
          ),
        if (info.amount.isNotEmpty)
          InfoRowData(
            icon: Icons.currency_rupee,
            label: "Amount",
            value: info.amount,
          ),
        if (info.status.isNotEmpty)
          InfoRowData(
            icon: Icons.info_outline,
            label: "Status",
            value: info.status[0].toUpperCase() + info.status.substring(1),
          ),
      ],
    );
  }

  // ================= REFERENCE =================

  Widget _referenceCard(PaymentReference reference) {
    return InfoCard(
      title: "Payment Reference",
      titleIcon: Icons.tag,
      isAccordion: true,
      initiallyExpanded: true,
      rows: [
        if ((reference.upiTransactionId ?? '').isNotEmpty)
          InfoRowData(
            icon: Icons.qr_code_2,
            label: "UPI Transaction ID",
            value: reference.upiTransactionId!,
          ),
        if ((reference.transactionRefNo ?? '').isNotEmpty)
          InfoRowData(
            icon: Icons.confirmation_number_outlined,
            label: "Transaction Reference No.",
            value: reference.transactionRefNo!,
          ),
        if ((reference.gatewayRefNo ?? '').isNotEmpty)
          InfoRowData(
            icon: Icons.dns_outlined,
            label: "Gateway Reference No.",
            value: reference.gatewayRefNo!,
          ),
        if ((reference.notes ?? '').isNotEmpty)
          InfoRowData(
            icon: Icons.notes_outlined,
            label: "Notes",
            value: reference.notes!,
          ),
      ],
    );
  }

  // ================= BILLING =================

  Widget _billingCard(BillingInfo billing) {
    return InfoCard(
      title: "Billing Information",
      titleIcon: Icons.storefront_outlined,
      isAccordion: true,
      initiallyExpanded: true,
      rows: [
        if ((billing.accountName ?? '').isNotEmpty)
          InfoRowData(
            icon: Icons.store,
            label: "Billed To",
            value:
                billing.accountCode != null && billing.accountCode!.isNotEmpty
                ? "${billing.accountName!} (${billing.accountCode!})"
                : billing.accountName!,
          ),
        if ((billing.invoiceNo ?? '').isNotEmpty)
          InfoRowData(
            icon: Icons.description_outlined,
            label: "Invoice No.",
            value: billing.invoiceNo!,
          ),
        if ((billing.invoiceDate ?? '').isNotEmpty)
          InfoRowData(
            icon: Icons.event_outlined,
            label: "Invoice Date",
            value: billing.invoiceDate!,
          ),
      ],
    );
  }

  // ================= ACTIONS =================

  Widget _actions(PaymentActions actions) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (actions.showDownloadReceipt)
            _actionButton(
              icon: Icons.download_outlined,
              label: "Download Receipt",
              onTap: () =>
                  _openLink(actions.receiptUrl, failureLabel: "the receipt"),
              isPrimary: true,
            ),
          if (actions.showDownloadReceipt &&
              (actions.showDownloadInvoice || actions.showContactSupport))
            const SizedBox(height: AppSpacing.verticalSmall),
          if (actions.showDownloadInvoice)
            _actionButton(
              icon: Icons.receipt_outlined,
              label: "Download Invoice",
              onTap: () =>
                  _openLink(actions.invoiceUrl, failureLabel: "the invoice"),
              isPrimary: true,
            ),
          if (actions.showDownloadInvoice && actions.showContactSupport)
            const SizedBox(height: AppSpacing.verticalSmall),
          if (actions.showContactSupport)
            _actionButton(
              icon: Icons.support_agent_outlined,
              label: "Need Help? Contact Support",
              onTap: () => _openLink(
                actions.supportUrl,
                failureLabel: "the support page",
              ),
              isPrimary: false,
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: isPrimary ? Colors.white : AppColors.primary,
      ),
      label: Text(
        label,
        style: AppTextStyles.button.copyWith(
          color: isPrimary ? Colors.white : AppColors.primary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primary : Colors.transparent,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    );
  }
}
