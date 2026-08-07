// revenue_expense_report_model.dart
//
// Models for `GET /reports/revenue-expense` — the "Revenue & Expense"
// report shown from Account > Report > Revenue & Expense Summary.

import 'pnl_report_model.dart' show PnlPeriodOption, PnlBranchOption;

export 'pnl_report_model.dart' show PnlPeriodOption, PnlBranchOption;

/// ===============================
/// META (segment + branch selectors)
/// ===============================

class RevenueExpenseMeta {
  final String currencySymbol;
  final List<PnlPeriodOption> periods;
  final String selectedPeriod;
  final List<PnlBranchOption> branches;
  final String selectedBranchId;

  const RevenueExpenseMeta({
    required this.currencySymbol,
    required this.periods,
    required this.selectedPeriod,
    required this.branches,
    required this.selectedBranchId,
  });

  factory RevenueExpenseMeta.fromJson(Map<String, dynamic> json) {
    return RevenueExpenseMeta(
      currencySymbol: json['currency_symbol'] ?? '₹',
      periods: (json['periods'] as List? ?? [])
          .map((e) => PnlPeriodOption.fromJson(e))
          .toList(),
      selectedPeriod: json['selected_period'] ?? 'today',
      branches: (json['branches'] as List? ?? [])
          .map((e) => PnlBranchOption.fromJson(e))
          .toList(),
      selectedBranchId: (json['selected_branch_id'] ?? 'all').toString(),
    );
  }
}

/// ===============================
/// SUMMARY (Revenue / Expenses / Net Profit cards)
/// ===============================

class RevenueExpenseSummary {
  final double revenue;
  final double revenueChangePercent;
  final double expenses;
  final double expensesChangePercent;
  final double netProfit;
  final double netProfitChangePercent;
  final String comparisonLabel;

  const RevenueExpenseSummary({
    required this.revenue,
    required this.revenueChangePercent,
    required this.expenses,
    required this.expensesChangePercent,
    required this.netProfit,
    required this.netProfitChangePercent,
    required this.comparisonLabel,
  });

  factory RevenueExpenseSummary.fromJson(Map<String, dynamic> json) {
    return RevenueExpenseSummary(
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      revenueChangePercent:
          (json['revenue_change_percent'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      expensesChangePercent:
          (json['expenses_change_percent'] as num?)?.toDouble() ?? 0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0,
      netProfitChangePercent:
          (json['net_profit_change_percent'] as num?)?.toDouble() ?? 0,
      comparisonLabel: json['comparison_label'] ?? 'vs last period',
    );
  }
}

/// ===============================
/// REVENUE TREND (single-line chart)
/// ===============================

class RevenueTrendPoint {
  final String label;
  final double value;

  const RevenueTrendPoint({required this.label, required this.value});

  factory RevenueTrendPoint.fromJson(Map<String, dynamic> json) {
    return RevenueTrendPoint(
      label: json['label'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenueTrend {
  final String title;
  final List<RevenueTrendPoint> points;

  const RevenueTrend({required this.title, required this.points});

  static RevenueTrend fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) return const RevenueTrend(title: 'Revenue Trend', points: []);
    final pointsJson = json['points'] as List? ?? [];
    return RevenueTrend(
      title: json['title'] ?? 'Revenue Trend',
      points: pointsJson.map((e) => RevenueTrendPoint.fromJson(e)).toList(),
    );
  }
}

/// ===============================
/// EXPENSE BREAKDOWN (donut + legend)
/// ===============================

class ExpenseBreakdownItem {
  final String label;
  final double percent;
  final double amount;

  const ExpenseBreakdownItem({
    required this.label,
    required this.percent,
    required this.amount,
  });

  factory ExpenseBreakdownItem.fromJson(Map<String, dynamic> json) {
    return ExpenseBreakdownItem(
      label: json['label'] ?? '',
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ExpenseBreakdown {
  final String title;
  final List<ExpenseBreakdownItem> items;

  const ExpenseBreakdown({required this.title, required this.items});

  static ExpenseBreakdown fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) return const ExpenseBreakdown(title: 'Expense Breakdown', items: []);
    final itemsJson = json['items'] as List? ?? [];
    return ExpenseBreakdown(
      title: json['title'] ?? 'Expense Breakdown',
      items: itemsJson.map((e) => ExpenseBreakdownItem.fromJson(e)).toList(),
    );
  }
}

/// ===============================
/// TOP SERVICES BY REVENUE
/// ===============================

class TopServiceItem {
  final String label;
  final double amount;
  final double percent;

  const TopServiceItem({
    required this.label,
    required this.amount,
    required this.percent,
  });

  factory TopServiceItem.fromJson(Map<String, dynamic> json) {
    return TopServiceItem(
      label: json['label'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TopServicesSection {
  final String title;
  final List<TopServiceItem> items;

  const TopServicesSection({required this.title, required this.items});

  static TopServicesSection fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) return const TopServicesSection(title: 'Top Services by Revenue', items: []);
    final itemsJson = json['items'] as List? ?? [];
    return TopServicesSection(
      title: json['title'] ?? 'Top Services by Revenue',
      items: itemsJson.map((e) => TopServiceItem.fromJson(e)).toList(),
    );
  }
}

/// ===============================
/// EXPORT (Export PDF / Export Excel)
/// ===============================

class RevenueExpenseExportLinks {
  final String? pdfUrl;
  final String? excelUrl;

  const RevenueExpenseExportLinks({this.pdfUrl, this.excelUrl});

  static RevenueExpenseExportLinks fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) return const RevenueExpenseExportLinks();
    return RevenueExpenseExportLinks(
      pdfUrl: json['pdf_url'] as String?,
      excelUrl: json['excel_url'] as String?,
    );
  }
}

/// ===============================
/// TOP-LEVEL REPORT DATA
/// ===============================

class RevenueExpenseReportData {
  final RevenueExpenseMeta meta;
  final RevenueExpenseSummary summary;
  final RevenueTrend trend;
  final ExpenseBreakdown expenseBreakdown;
  final TopServicesSection topServices;
  final RevenueExpenseExportLinks export;

  const RevenueExpenseReportData({
    required this.meta,
    required this.summary,
    required this.trend,
    required this.expenseBreakdown,
    required this.topServices,
    required this.export,
  });

  factory RevenueExpenseReportData.fromJson(Map<String, dynamic> json) {
    return RevenueExpenseReportData(
      meta: RevenueExpenseMeta.fromJson(json['meta'] ?? {}),
      summary: RevenueExpenseSummary.fromJson(json['summary'] ?? {}),
      trend: RevenueTrend.fromJsonOrEmpty(json['trend'] as Map<String, dynamic>?),
      expenseBreakdown: ExpenseBreakdown.fromJsonOrEmpty(
        json['expense_breakdown'] as Map<String, dynamic>?,
      ),
      topServices: TopServicesSection.fromJsonOrEmpty(
        json['top_services'] as Map<String, dynamic>?,
      ),
      export: RevenueExpenseExportLinks.fromJsonOrEmpty(
        json['export'] as Map<String, dynamic>?,
      ),
    );
  }
}
