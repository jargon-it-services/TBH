// branch_performance_report_model.dart
//
// Models for `GET /reports/branch-performance` — the "Branch
// Performance Breakdown" report shown from Account > Report > Branch
// Performance Breakdown. Shape mirrors the other report models
// (`pnl_report_model.dart`, `revenue_expense_report_model.dart`): a
// `meta` block driving the segment toggle, plus a handful of
// self-contained named sections.
//
// Unlike the other three reports, this screen has no branch selector
// (comparing branches *is* the report, so filtering down to one
// branch would defeat the purpose) — `meta` therefore carries only
// `periods`, not `branches`.

import 'pnl_report_model.dart' show PnlPeriodOption;

export 'pnl_report_model.dart' show PnlPeriodOption;

/// ===============================
/// META (segment selector only — no branch selector)
/// ===============================

class BranchPerformanceMeta {
  final String currencySymbol;
  final List<PnlPeriodOption> periods;
  final String selectedPeriod;

  const BranchPerformanceMeta({
    required this.currencySymbol,
    required this.periods,
    required this.selectedPeriod,
  });

  factory BranchPerformanceMeta.fromJson(Map<String, dynamic> json) {
    return BranchPerformanceMeta(
      currencySymbol: json['currency_symbol'] ?? '₹',
      periods: (json['periods'] as List? ?? [])
          .map((e) => PnlPeriodOption.fromJson(e))
          .toList(),
      selectedPeriod: json['selected_period'] ?? 'this_month',
    );
  }
}

/// ===============================
/// OVERVIEW (Revenue / Profit / Growth — "All Branches Overview")
/// ===============================

class BranchOverviewSummary {
  final String title;
  final double revenue;
  final double profit;
  final double growthPercent;
  final String comparisonLabel;

  const BranchOverviewSummary({
    required this.title,
    required this.revenue,
    required this.profit,
    required this.growthPercent,
    required this.comparisonLabel,
  });

  static BranchOverviewSummary fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) {
      return const BranchOverviewSummary(
        title: 'All Branches Overview',
        revenue: 0,
        profit: 0,
        growthPercent: 0,
        comparisonLabel: 'vs last period',
      );
    }
    return BranchOverviewSummary(
      title: json['title'] ?? 'All Branches Overview',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
      growthPercent: (json['growth_percent'] as num?)?.toDouble() ?? 0,
      comparisonLabel: json['comparison_label'] ?? 'vs last period',
    );
  }
}

/// ===============================
/// BRANCH PERFORMANCE (per-branch Revenue / Expenses / Profit)
/// ===============================
///
/// Powers both the "Branch Performance" card (one row per branch, 3
/// proportional bars) *and* the Revenue/Profit/Expense comparison bar
/// charts below it — those three charts just re-render this same
/// list of items with a different value picked off each one, rather
/// than the API sending three separate near-identical lists.

class BranchPerformanceItem {
  final String id;
  final String name;
  final double revenue;
  final double expenses;
  final double profit;

  const BranchPerformanceItem({
    required this.id,
    required this.name,
    required this.revenue,
    required this.expenses,
    required this.profit,
  });

  factory BranchPerformanceItem.fromJson(Map<String, dynamic> json) {
    return BranchPerformanceItem(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BranchPerformanceSection {
  final String title;
  final List<BranchPerformanceItem> items;

  const BranchPerformanceSection({required this.title, required this.items});

  static BranchPerformanceSection fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) {
      return const BranchPerformanceSection(title: 'Branch Performance', items: []);
    }
    final itemsJson = json['items'] as List? ?? [];
    return BranchPerformanceSection(
      title: json['title'] ?? 'Branch Performance',
      items: itemsJson.map((e) => BranchPerformanceItem.fromJson(e)).toList(),
    );
  }
}

/// ===============================
/// TOP EMPLOYEE COMPARISON (ranked across all branches)
/// ===============================

class TopEmployeeComparisonItem {
  final int rank;
  final String employeeName;
  final String branchName;
  final double revenue;

  const TopEmployeeComparisonItem({
    required this.rank,
    required this.employeeName,
    required this.branchName,
    required this.revenue,
  });

  factory TopEmployeeComparisonItem.fromJson(Map<String, dynamic> json) {
    return TopEmployeeComparisonItem(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      employeeName: json['employee_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TopEmployeeComparisonSection {
  final String title;
  final List<TopEmployeeComparisonItem> items;

  const TopEmployeeComparisonSection({required this.title, required this.items});

  static TopEmployeeComparisonSection fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) {
      return const TopEmployeeComparisonSection(title: 'Top Employee Comparison', items: []);
    }
    final itemsJson = json['items'] as List? ?? [];
    return TopEmployeeComparisonSection(
      title: json['title'] ?? 'Top Employee Comparison',
      items: itemsJson.map((e) => TopEmployeeComparisonItem.fromJson(e)).toList(),
    );
  }
}

/// ===============================
/// EXPORT (Export PDF / Export Excel)
/// ===============================

class BranchPerformanceExportLinks {
  final String? pdfUrl;
  final String? excelUrl;

  const BranchPerformanceExportLinks({this.pdfUrl, this.excelUrl});

  static BranchPerformanceExportLinks fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) return const BranchPerformanceExportLinks();
    return BranchPerformanceExportLinks(
      pdfUrl: json['pdf_url'] as String?,
      excelUrl: json['excel_url'] as String?,
    );
  }
}

/// ===============================
/// TOP-LEVEL REPORT DATA
/// ===============================

class BranchPerformanceReportData {
  final BranchPerformanceMeta meta;
  final BranchOverviewSummary overview;
  final BranchPerformanceSection branchPerformance;
  final TopEmployeeComparisonSection topEmployees;
  final BranchPerformanceExportLinks export;

  const BranchPerformanceReportData({
    required this.meta,
    required this.overview,
    required this.branchPerformance,
    required this.topEmployees,
    required this.export,
  });

  factory BranchPerformanceReportData.fromJson(Map<String, dynamic> json) {
    return BranchPerformanceReportData(
      meta: BranchPerformanceMeta.fromJson(json['meta'] ?? {}),
      overview: BranchOverviewSummary.fromJsonOrEmpty(
        json['overview'] as Map<String, dynamic>?,
      ),
      branchPerformance: BranchPerformanceSection.fromJsonOrEmpty(
        json['branch_performance'] as Map<String, dynamic>?,
      ),
      topEmployees: TopEmployeeComparisonSection.fromJsonOrEmpty(
        json['top_employees'] as Map<String, dynamic>?,
      ),
      export: BranchPerformanceExportLinks.fromJsonOrEmpty(
        json['export'] as Map<String, dynamic>?,
      ),
    );
  }
}
