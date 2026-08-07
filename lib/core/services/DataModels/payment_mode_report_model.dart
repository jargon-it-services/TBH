// payment_mode_report_model.dart
//
// Models for `GET /reports/payment-mode` — the "Payment Mode
// Breakdown" report shown from Account > Report > Payment Mode.

import 'pnl_report_model.dart' show PnlPeriodOption, PnlBranchOption;

export 'pnl_report_model.dart' show PnlPeriodOption, PnlBranchOption;

/// ===============================
/// META (segment + branch selectors)
/// ===============================

class PaymentModeMeta {
  final String currencySymbol;
  final List<PnlPeriodOption> periods;
  final String selectedPeriod;
  final List<PnlBranchOption> branches;
  final String selectedBranchId;

  const PaymentModeMeta({
    required this.currencySymbol,
    required this.periods,
    required this.selectedPeriod,
    required this.branches,
    required this.selectedBranchId,
  });

  factory PaymentModeMeta.fromJson(Map<String, dynamic> json) {
    return PaymentModeMeta(
      currencySymbol: json['currency_symbol'] ?? '₹',
      periods: (json['periods'] as List? ?? [])
          .map((e) => PnlPeriodOption.fromJson(e))
          .toList(),
      selectedPeriod: json['selected_period'] ?? 'this_month',
      branches: (json['branches'] as List? ?? [])
          .map((e) => PnlBranchOption.fromJson(e))
          .toList(),
      selectedBranchId: (json['selected_branch_id'] ?? 'all').toString(),
    );
  }
}

/// ===============================
/// SUMMARY (Total Received + trend vs. previous period)
/// ===============================

class PaymentModeSummary {
  final double totalReceived;
  final double changePercent;
  final String comparisonLabel;

  const PaymentModeSummary({
    required this.totalReceived,
    required this.changePercent,
    required this.comparisonLabel,
  });

  factory PaymentModeSummary.fromJson(Map<String, dynamic> json) {
    return PaymentModeSummary(
      totalReceived: (json['total_received'] as num?)?.toDouble() ?? 0,
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0,
      comparisonLabel: json['comparison_label'] ?? 'vs last period',
    );
  }
}

/// ===============================
/// PAYMENT MODES (Cash / UPI / Card)
/// ===============================

class PaymentModeItem {
  final String key; // 'cash' | 'upi' | 'card'
  final String label;
  final double amount;
  final double percent;
  final int transactionCount;

  const PaymentModeItem({
    required this.key,
    required this.label,
    required this.amount,
    required this.percent,
    required this.transactionCount,
  });

  factory PaymentModeItem.fromJson(Map<String, dynamic> json) {
    return PaymentModeItem(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
      transactionCount: (json['transaction_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// ===============================
/// TOP-LEVEL REPORT DATA
/// ===============================

class PaymentModeReportData {
  final PaymentModeMeta meta;
  final PaymentModeSummary summary;
  final List<PaymentModeItem> modes;

  const PaymentModeReportData({
    required this.meta,
    required this.summary,
    required this.modes,
  });

  factory PaymentModeReportData.fromJson(Map<String, dynamic> json) {
    return PaymentModeReportData(
      meta: PaymentModeMeta.fromJson(json['meta'] ?? {}),
      summary: PaymentModeSummary.fromJson(json['summary'] ?? {}),
      modes: (json['modes'] as List? ?? [])
          .map((e) => PaymentModeItem.fromJson(e))
          .toList(),
    );
  }
}
