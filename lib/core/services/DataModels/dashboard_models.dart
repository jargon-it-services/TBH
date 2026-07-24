// dashboard_models.dart

/// ===============================
/// DASHBOARD RESPONSE
/// ===============================

class DashboardResponse {
  final bool status;
  final DashboardData data;

  DashboardResponse({
    required this.status,
    required this.data,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      status: json['status'] ?? false,
      data: DashboardData.fromJson(json['data'] ?? {}),
    );
  }
}

/// ===============================
/// DASHBOARD DATA
/// ===============================

class DashboardData {
  final DashboardMeta meta;
  final OverviewTrend? overviewTrend;
  final List<FirmModel> firms;
  final List<StaffModel> staff;
  final List<ServiceModel> services;

  DashboardData({
    required this.meta,
    required this.overviewTrend,
    required this.firms,
    required this.staff,
    required this.services,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      meta: DashboardMeta.fromJson(json['meta'] ?? {}),
      overviewTrend: json['overviewTrend'] != null
          ? OverviewTrend.fromJson(json['overviewTrend'])
          : null,
      firms: (json['firms'] as List? ?? [])
          .map((e) => FirmModel.fromJson(e))
          .toList(),
      staff: (json['staff'] as List? ?? [])
          .map((e) => StaffModel.fromJson(e))
          .toList(),
      services: (json['services'] as List? ?? [])
          .map((e) => ServiceModel.fromJson(e))
          .toList(),
    );
  }
}

/// ===============================
/// META + COUNTS
/// ===============================

class DashboardMeta {
  final String currency;
  final List<String> periods;
  final DashboardCounts counts;

  DashboardMeta({
    required this.currency,
    required this.periods,
    required this.counts,
  });

  factory DashboardMeta.fromJson(Map<String, dynamic> json) {
    return DashboardMeta(
      currency: json['currency'] ?? '',
      periods: (json['periods'] as List? ?? []).cast<String>(),
      counts: DashboardCounts.fromJson(json['counts'] ?? {}),
    );
  }
}

class DashboardCounts {
  final int totalFirms;
  final int totalServices;
  final int totalStaff;

  DashboardCounts({
    required this.totalFirms,
    required this.totalServices,
    required this.totalStaff,
  });

  factory DashboardCounts.fromJson(Map<String, dynamic> json) {
    return DashboardCounts(
      totalFirms: json['totalFirms'] ?? 0,
      totalServices: json['totalServices'] ?? 0,
      totalStaff: json['totalStaff'] ?? 0,
    );
  }
}

/// ================= TREND MODELS =================

class OverviewTrend {
  final String period;
  final int limit;
  final bool hasMoreData;
  final String range;
  final List<TrendPoint> points;
  final String? nextCursor;
  final String? prevCursor;

  OverviewTrend(
      {required this.period,
      required this.limit,
      required this.hasMoreData,
      required this.range,
      required this.points,
      required this.nextCursor,
      required this.prevCursor});

  factory OverviewTrend.fromJson(Map<String, dynamic> json) {
    return OverviewTrend(
        period: json['period'] ?? '',
        limit: json['limit'] ?? 0,
        hasMoreData: json['hasMoreData'] ?? false,
        range: json['range'] ?? '',
        points: (json['points'] as List? ?? [])
            .map((e) => TrendPoint.fromJson(e))
            .toList(),
        nextCursor: json['nextCursor'],
        prevCursor: json['prevCursor']);
  }
}

class TrendPoint {
  final String key;
  final String label;
  final double value;

  TrendPoint({
    required this.key,
    required this.label,
    required this.value,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    final num rawValue = json['value'] ?? 0;

    return TrendPoint(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      value: rawValue.isFinite ? rawValue.toDouble() : 0,
    );
  }
}

/// ================= FIRM =================

class FirmModel {
  final int id;
  final String name;
  final String description;
  final double revenue;
  final int transactions;
  final double percent;

  bool get positive => percent >= 0;

  FirmModel({
    required this.id,
    required this.name,
    required this.description,
    required this.revenue,
    required this.transactions,
    required this.percent,
  });

  factory FirmModel.fromJson(Map<String, dynamic> json) {
    return FirmModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      transactions: json['transactions'] ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// ================= STAFF =================

class StaffModel {
  final int id;
  final String name;
  final int firmId;
  final String firmName;
  final double revenue;
  final int transactions;
  final double percent;

  bool get positive => percent >= 0;

  StaffModel({
    required this.id,
    required this.name,
    required this.firmId,
    required this.firmName,
    required this.revenue,
    required this.transactions,
    required this.percent,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      firmId: json['firmId'] ?? 0,
      firmName: json['firmName'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      transactions: json['transactions'] ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// ================= Services =================

class ServiceModel {
  final int id;
  final String name;
  final int firmId;
  final String firmName;
  final double revenue;
  final int transactions;
  final double percent;

  bool get positive => percent >= 0;

  ServiceModel({
    required this.id,
    required this.name,
    required this.firmId,
    required this.firmName,
    required this.revenue,
    required this.transactions,
    required this.percent,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      firmId: json['firmId'] ?? 0,
      firmName: json['firmName'] ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      transactions: json['transactions'] ?? 0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
    );
  }
}
