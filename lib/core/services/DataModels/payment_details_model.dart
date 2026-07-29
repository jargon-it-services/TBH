/// Data models for `GET /api/v1/payments/{id}`.
///
/// Follows the same nested-class-per-section shape as
/// `transaction_details_model.dart`. Sections that the API contract
/// marks optional (`reference`, `billing`) are nullable here and every
/// field inside them is read defensively, so a pending/failed payment
/// that simply doesn't have UPI/gateway/invoice data yet renders a
/// screen with those sections omitted instead of crashing or showing
/// empty placeholders.
library;

/* ================= ROOT RESPONSE ================= */

class PaymentDetailsResponse {
  final PaymentDetails payment;

  PaymentDetailsResponse({required this.payment});

  factory PaymentDetailsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return PaymentDetailsResponse(
      payment: PaymentDetails.fromJson(data['payment'] ?? {}),
    );
  }
}

/* ================= PAYMENT ================= */

class PaymentDetails {
  final String id;
  final String status;
  final double amount;
  final String formattedAmount;
  final String currency;
  final DateTime? date;
  final String dateDisplay;

  final PaymentInfo info;
  final PaymentReference? reference;
  final BillingInfo? billing;
  final PaymentActions actions;

  PaymentDetails({
    required this.id,
    required this.status,
    required this.amount,
    required this.formattedAmount,
    required this.currency,
    required this.date,
    required this.dateDisplay,
    required this.info,
    required this.actions,
    this.reference,
    this.billing,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    final dateTime = json['dateTime'] ?? {};

    return PaymentDetails(
      id: json['id'] ?? '',
      status: (json['status'] ?? '').toString().toLowerCase(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      formattedAmount:
          json['formattedAmount'] ?? '₹${json['amount'] ?? 0}',
      currency: json['currency'] ?? 'INR',
      date: DateTime.tryParse(dateTime['iso'] ?? ''),
      dateDisplay: dateTime['display'] ?? '',
      info: PaymentInfo.fromJson(json['paymentInfo'] ?? {}),
      reference: json['reference'] != null
          ? PaymentReference.fromJson(json['reference'])
          : null,
      billing:
          json['billing'] != null ? BillingInfo.fromJson(json['billing']) : null,
      actions: PaymentActions.fromJson(json['actions'] ?? {}),
    );
  }
}

/* ================= PAYMENT INFORMATION ================= */

class PaymentInfo {
  final String dateTimeDisplay;
  final String branch;
  final String branchCode;
  final String paymentType;
  final String paymentMethod;
  final String amount;
  final String status;

  PaymentInfo({
    required this.dateTimeDisplay,
    required this.branch,
    required this.branchCode,
    required this.paymentType,
    required this.paymentMethod,
    required this.amount,
    required this.status,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      dateTimeDisplay: json['dateTime'] ?? '',
      branch: json['branch'] ?? '',
      branchCode: json['branchCode'] ?? '',
      paymentType: json['paymentType'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      amount: json['amount'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

/* ================= PAYMENT REFERENCE (optional) ================= */

class PaymentReference {
  final String? upiTransactionId;
  final String? transactionRefNo;
  final String? gatewayRefNo;
  final String? notes;

  PaymentReference({
    this.upiTransactionId,
    this.transactionRefNo,
    this.gatewayRefNo,
    this.notes,
  });

  factory PaymentReference.fromJson(Map<String, dynamic> json) {
    return PaymentReference(
      upiTransactionId: json['upiTransactionId'],
      transactionRefNo: json['transactionRefNo'],
      gatewayRefNo: json['gatewayRefNo'],
      notes: json['notes'],
    );
  }

  /// True only when at least one field is actually present -- lets the
  /// UI skip rendering an empty "References" card entirely rather than
  /// showing a card with nothing in it.
  bool get hasAnyValue =>
      (upiTransactionId?.isNotEmpty ?? false) ||
      (transactionRefNo?.isNotEmpty ?? false) ||
      (gatewayRefNo?.isNotEmpty ?? false) ||
      (notes?.isNotEmpty ?? false);
}

/* ================= BILLING (optional) ================= */

class BillingInfo {
  final String? accountName;
  final String? accountCode;
  final String? invoiceNo;
  final String? invoiceDate;

  BillingInfo({
    this.accountName,
    this.accountCode,
    this.invoiceNo,
    this.invoiceDate,
  });

  factory BillingInfo.fromJson(Map<String, dynamic> json) {
    return BillingInfo(
      accountName: json['accountName'],
      accountCode: json['accountCode'],
      invoiceNo: json['invoiceNo'],
      invoiceDate: json['invoiceDate'],
    );
  }

  bool get hasAnyValue =>
      (accountName?.isNotEmpty ?? false) ||
      (accountCode?.isNotEmpty ?? false) ||
      (invoiceNo?.isNotEmpty ?? false) ||
      (invoiceDate?.isNotEmpty ?? false);
}

/* ================= ACTIONS ================= */

/// Every flag defaults to `false`/`null` when absent, so an older
/// backend response (or a payment state with nothing actionable, e.g.
/// a still-pending payment) simply shows no action buttons instead of
/// showing buttons that lead nowhere.
class PaymentActions {
  final bool showDownloadReceipt;
  final String? receiptUrl;
  final bool showDownloadInvoice;
  final String? invoiceUrl;
  final bool showContactSupport;
  final String? supportUrl;

  PaymentActions({
    required this.showDownloadReceipt,
    required this.showDownloadInvoice,
    required this.showContactSupport,
    this.receiptUrl,
    this.invoiceUrl,
    this.supportUrl,
  });

  factory PaymentActions.fromJson(Map<String, dynamic> json) {
    return PaymentActions(
      showDownloadReceipt:
          (json['showDownloadReceipt'] ?? false) && json['receiptUrl'] != null,
      receiptUrl: json['receiptUrl'],
      showDownloadInvoice:
          (json['showDownloadInvoice'] ?? false) && json['invoiceUrl'] != null,
      invoiceUrl: json['invoiceUrl'],
      showContactSupport: json['showContactSupport'] ?? false,
      supportUrl: json['supportUrl'],
    );
  }

  bool get hasAny => showDownloadReceipt || showDownloadInvoice || showContactSupport;
}
