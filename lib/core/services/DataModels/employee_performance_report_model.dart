// employee_performance_report_model.dart
//
// Models for `GET /reports/employee-performance` — the Employee
// Performance report shown from Account > Report > Employee
// Performance Report. Shape mirrors `pnl_report_model.dart` (a `meta`
// block driving the period/branch selectors, plus a handful of
// self-contained named sections) so this feature doesn't invent a new
// response convention.

import 'pnl_report_model.dart' show PnlPeriodOption, PnlBranchOption;

export 'pnl_report_model.dart' show PnlPeriodOption, PnlBranchOption;

/// ===============================
/// META (period + branch selectors)
/// ===============================

class EmployeePerformanceMeta {
  final String currencySymbol;
  final List<PnlPeriodOption> periods;
  final String selectedPeriod;
  final List<PnlBranchOption> branches;
  final String selectedBranchId;

  const EmployeePerformanceMeta({
    required this.currencySymbol,
    required this.periods,
    required this.selectedPeriod,
    required this.branches,
    required this.selectedBranchId,
  });

  factory EmployeePerformanceMeta.fromJson(Map<String, dynamic> json) {
    return EmployeePerformanceMeta(
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
/// TOP PERFORMER
/// ===============================
///
/// The single highest-revenue employee for the selected period/branch.
/// `null` when there's no employee data yet for the current filters
/// (e.g. a brand-new branch) — callers should fall back to an empty
/// state rather than assume this is always present.
class TopPerformer {
  final String id;
  final String fullName;
  final String designation;
  final String branchName;

  /// Profile photo URL, when uploaded. Null/empty means "no photo" —
  /// callers fall back to an initials avatar, same fallback pattern
  /// used across Staff/Branch/Service (`StaffListItem.hasPhoto`).
  final String? photo;

  final double revenue;
  final int servicesServed;
  final double expenses;
  final double profit;
  final double commission;

  bool get hasPhoto => photo != null && photo!.trim().isNotEmpty;

  const TopPerformer({
    required this.id,
    required this.fullName,
    required this.designation,
    required this.branchName,
    this.photo,
    required this.revenue,
    required this.servicesServed,
    required this.expenses,
    required this.profit,
    required this.commission,
  });

  static TopPerformer? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    return TopPerformer(
      id: (json['id'] ?? '').toString(),
      fullName: json['full_name'] ?? '',
      designation: json['designation'] ?? '',
      branchName: json['branch_name'] ?? '',
      photo: json['photo'] as String?,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      servicesServed: (json['services_served'] as num?)?.toInt() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// ===============================
/// EMPLOYEE RANKING (full list — powers the sortable/searchable table)
/// ===============================

class EmployeeRankingItem {
  final String id;
  final String fullName;
  final String branchName;
  final String? photo;

  final double revenue;
  final int servicesServed;
  final double expenses;
  final double profit;
  final double commission;

  bool get hasPhoto => photo != null && photo!.trim().isNotEmpty;

  const EmployeeRankingItem({
    required this.id,
    required this.fullName,
    required this.branchName,
    this.photo,
    required this.revenue,
    required this.servicesServed,
    required this.expenses,
    required this.profit,
    required this.commission,
  });

  factory EmployeeRankingItem.fromJson(Map<String, dynamic> json) {
    return EmployeeRankingItem(
      id: (json['id'] ?? '').toString(),
      fullName: json['full_name'] ?? '',
      branchName: json['branch_name'] ?? '',
      photo: json['photo'] as String?,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      servicesServed: (json['services_served'] as num?)?.toInt() ?? 0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0,
      commission: (json['commission'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EmployeeRankingSection {
  final String title;
  final List<EmployeeRankingItem> items;

  const EmployeeRankingSection({required this.title, required this.items});

  static EmployeeRankingSection fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) {
      return const EmployeeRankingSection(title: 'Employee Ranking', items: []);
    }
    final itemsJson = json['items'] as List? ?? [];
    return EmployeeRankingSection(
      title: json['title'] ?? 'Employee Ranking',
      items: itemsJson.map((e) => EmployeeRankingItem.fromJson(e)).toList(),
    );
  }
}

/// ===============================
/// EXPORT (Export PDF / Export Excel)
/// ===============================

class EmployeePerformanceExportLinks {
  final String? pdfUrl;
  final String? excelUrl;

  const EmployeePerformanceExportLinks({this.pdfUrl, this.excelUrl});

  static EmployeePerformanceExportLinks fromJsonOrEmpty(Map<String, dynamic>? json) {
    if (json == null) return const EmployeePerformanceExportLinks();
    return EmployeePerformanceExportLinks(
      pdfUrl: json['pdf_url'] as String?,
      excelUrl: json['excel_url'] as String?,
    );
  }
}

/// ===============================
/// TOP-LEVEL REPORT DATA
/// ===============================

class EmployeePerformanceReportData {
  final EmployeePerformanceMeta meta;
  final TopPerformer? topPerformer;
  final EmployeeRankingSection ranking;
  final EmployeePerformanceExportLinks export;

  const EmployeePerformanceReportData({
    required this.meta,
    required this.topPerformer,
    required this.ranking,
    required this.export,
  });

  factory EmployeePerformanceReportData.fromJson(Map<String, dynamic> json) {
    return EmployeePerformanceReportData(
      meta: EmployeePerformanceMeta.fromJson(json['meta'] ?? {}),
      topPerformer: TopPerformer.fromJsonOrNull(
        json['top_performer'] as Map<String, dynamic>?,
      ),
      ranking: EmployeeRankingSection.fromJsonOrEmpty(
        json['ranking'] as Map<String, dynamic>?,
      ),
      export: EmployeePerformanceExportLinks.fromJsonOrEmpty(
        json['export'] as Map<String, dynamic>?,
      ),
    );
  }
}
