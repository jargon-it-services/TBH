// pnl_report_model.dart
//
// Models for `GET /reports/pnl` — the Profit & Loss report shown from
// Account > Report > PnL. Shape deliberately mirrors the merged
// `/dashboard` response style used by `dashboard_models.dart` (a
// `meta` block driving the period/branch selectors, plus a handful of
// self-contained named sections) so this feature doesn't invent a new
// response convention.

/// ===============================
/// META (period + branch selectors)
/// ===============================

class PnlPeriodOption {
  final String key;
  final String label;

  const PnlPeriodOption({required this.key, required this.label});

  factory PnlPeriodOption.fromJson(Map<String, dynamic> json) {
    return PnlPeriodOption(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class PnlBranchOption {
  final String id;
  final String name;

  const PnlBranchOption({required this.id, required this.name});

  factory PnlBranchOption.fromJson(Map<String, dynamic> json) {
    return PnlBranchOption(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
    );
  }
}

class PnlMeta {
  final String currencySymbol;
  final String dateFormat;
  final List<PnlPeriodOption> periods;
  final String selectedPeriod;
  final List<PnlBranchOption> branches;
  final String selectedBranchId;

  const PnlMeta({
    required this.currencySymbol,
    required this.dateFormat,
    required this.periods,
    required this.selectedPeriod,
    required this.branches,
    required this.selectedBranchId,
  });

  factory PnlMeta.fromJson(Map<String, dynamic> json) {
    return PnlMeta(
      currencySymbol: json['currency_symbol'] ?? '₹',
      dateFormat: json['date_format'] ?? 'dd MMM yyyy',
      periods: (json['periods'] as List? ?? [])
          .map((e) => PnlPeriodOption.fromJson(e))
          .toList(),
      selectedPeriod: json['selected_period'] ?? '3m',
      branches: (json['branches'] as List? ?? [])
          .map((e) => PnlBranchOption.fromJson(e))
          .toList(),
      selectedBranchId: (json['selected_branch_id'] ?? 'all').toString(),
    );
  }
}

/// ===============================
/// SUMMARY (Revenue / Expenses / Profit cards)
/// ===============================

class PnlSummary {
  final double revenue;
  final double expenses;
  final double profit;

  const PnlSummary({
    required this.revenue,
    required this.expenses,
    required this.profit,
  });

  factory PnlSummary.fromJson(Map<String, dynamic> json) {
    return PnlSummary(
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// ================= TREND (Revenue vs Expense line chart) =================

class PnlTrendPoint {
  final String label;
  final double revenue;
  final double expense;

  const PnlTrendPoint({
    required this.label,
    required this.revenue,
    required this.expense,
  });

  factory PnlTrendPoint.fromJson(Map<String, dynamic> json) {
    return PnlTrendPoint(
      label: json['label'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      expense: (json['expense'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PnlTrend {
  final String title;
  final List<PnlTrendPoint> points;

  const PnlTrend({required this.title, required this.points});

  static PnlTrend fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) return const PnlTrend(title: 'P&L Trend', points: []);
    final pointsJson = json['points'] as List? ?? [];
    return PnlTrend(
      title: json['title'] ?? 'P&L Trend',
      points: pointsJson.map((e) => PnlTrendPoint.fromJson(e)).toList(),
    );
  }
}

/// ================= EXPENSE CATEGORIES (donut + legend) =================

class PnlCategoryItem {
  final String label;
  final double value;

  const PnlCategoryItem({required this.label, required this.value});

  factory PnlCategoryItem.fromJson(Map<String, dynamic> json) {
    return PnlCategoryItem(
      label: json['label'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PnlExpenseCategories {
  final String title;
  final List<PnlCategoryItem> items;

  const PnlExpenseCategories({required this.title, required this.items});

  static PnlExpenseCategories fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) {
      return const PnlExpenseCategories(title: 'Expense Categories', items: []);
    }
    final itemsJson = json['items'] as List? ?? [];
    return PnlExpenseCategories(
      title: json['title'] ?? 'Expense Categories',
      items: itemsJson.map((e) => PnlCategoryItem.fromJson(e)).toList(),
    );
  }
}

/// ================= MONTHLY COMPARISON (table) =================

class PnlMonthlyRow {
  final String month;
  final double revenue;
  final double expenses;
  final double profit;

  const PnlMonthlyRow({
    required this.month,
    required this.revenue,
    required this.expenses,
    required this.profit,
  });

  factory PnlMonthlyRow.fromJson(Map<String, dynamic> json) {
    return PnlMonthlyRow(
      month: json['month'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PnlMonthlyComparison {
  final String title;
  final List<PnlMonthlyRow> rows;

  const PnlMonthlyComparison({required this.title, required this.rows});

  static PnlMonthlyComparison fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) {
      return const PnlMonthlyComparison(title: 'Monthly Comparison', rows: []);
    }
    final rowsJson = json['rows'] as List? ?? [];
    return PnlMonthlyComparison(
      title: json['title'] ?? 'Monthly Comparison',
      rows: rowsJson.map((e) => PnlMonthlyRow.fromJson(e)).toList(),
    );
  }
}

/// ================= EXPORT (Export PDF / Export Excel) =================

class PnlExportLinks {
  final String? pdfUrl;
  final String? excelUrl;

  const PnlExportLinks({this.pdfUrl, this.excelUrl});

  static PnlExportLinks fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) return const PnlExportLinks();
    return PnlExportLinks(
      pdfUrl: json['pdf_url'] as String?,
      excelUrl: json['excel_url'] as String?,
    );
  }
}

/// ===============================
/// TOP-LEVEL REPORT DATA
/// ===============================

class PnlReportData {
  final PnlMeta meta;
  final PnlSummary summary;
  final PnlTrend trend;
  final PnlExpenseCategories expenseCategories;
  final PnlMonthlyComparison monthlyComparison;
  final PnlExportLinks export;

  const PnlReportData({
    required this.meta,
    required this.summary,
    required this.trend,
    required this.expenseCategories,
    required this.monthlyComparison,
    required this.export,
  });

  factory PnlReportData.fromJson(Map<String, dynamic> json) {
    return PnlReportData(
      meta: PnlMeta.fromJson(json['meta'] ?? {}),
      summary: PnlSummary.fromJson(json['summary'] ?? {}),
      trend: PnlTrend.fromJsonOrEmpty(json['trend'] as Map<String, dynamic>?),
      expenseCategories: PnlExpenseCategories.fromJsonOrEmpty(
        json['expense_categories'] as Map<String, dynamic>?,
      ),
      monthlyComparison: PnlMonthlyComparison.fromJsonOrEmpty(
        json['monthly_comparison'] as Map<String, dynamic>?,
      ),
      export: PnlExportLinks.fromJsonOrEmpty(
        json['export'] as Map<String, dynamic>?,
      ),
    );
  }
}
