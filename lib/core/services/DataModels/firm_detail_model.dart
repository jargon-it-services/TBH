class FirmDetailResponse {
  final Meta meta;
  final OverviewTrend overviewTrend;
  final List<InsightItem> firms;
  final List<InsightItem> staff;
  final List<InsightItem> services;

  FirmDetailResponse({
    required this.meta,
    required this.overviewTrend,
    required this.firms,
    required this.staff,
    required this.services,
  });

  factory FirmDetailResponse.fromJson(Map<String, dynamic> json) {
    return FirmDetailResponse(
      meta: Meta.fromJson(json['meta']),
      overviewTrend: OverviewTrend.fromJson(json['overviewTrend']),
      firms:
          (json['firms'] as List).map((e) => InsightItem.fromJson(e)).toList(),
      staff:
          (json['staff'] as List).map((e) => InsightItem.fromJson(e)).toList(),
      services: (json['services'] as List)
          .map((e) => InsightItem.fromJson(e))
          .toList(),
    );
  }
}

class Meta {
  final String currency;
  final List<String> periods;
  final FirmInfo firmInfo;

  Meta({required this.currency, required this.periods, required this.firmInfo});

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      currency: json['currency'],
      periods: List<String>.from(json['periods']),
      firmInfo: FirmInfo.fromJson(json['firmInfo']),
    );
  }
}

class FirmInfo {
  final int id;
  final String name;
  final String description;
  final double revenue;
  final int transactions;
  final double percent;
  final String gstin;
  final String regNo;
  final String email;
  final String contact;

  FirmInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.revenue,
    required this.transactions,
    required this.percent,
    required this.gstin,
    required this.regNo,
    required this.email,
    required this.contact,
  });

  factory FirmInfo.fromJson(Map<String, dynamic> json) {
    return FirmInfo(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      revenue: (json['revenue'] as num).toDouble(),
      transactions: json['transactions'],
      percent: (json['percent'] as num).toDouble(),
      gstin: json['gstin'] ?? "-",
      regNo: json['regNo'] ?? "-",
      email: json['email'] ?? "-",
      contact: json['contact'] ?? "-",
    );
  }
}

class OverviewTrend {
  final String period;
  final int limit;
  final bool hasMoreData;
  final String range;
  final String? prevCursor;
  final String? nextCursor;
  final List<RevenueTrendData> points;

  OverviewTrend({
    required this.period,
    required this.limit,
    required this.hasMoreData,
    required this.range,
    this.prevCursor,
    this.nextCursor,
    required this.points,
  });

  factory OverviewTrend.fromJson(Map<String, dynamic> json) {
    return OverviewTrend(
      period: json['period'],
      limit: json['limit'],
      hasMoreData: json['hasMoreData'],
      range: json['range'],
      prevCursor: json['prevCursor'],
      nextCursor: json['nextCursor'],
      points: (json['points'] as List)
          .map((e) => RevenueTrendData.fromJson(e))
          .toList(),
    );
  }
}

class RevenueTrendData {
  final String label;
  final double value;

  RevenueTrendData({required this.label, required this.value});

  factory RevenueTrendData.fromJson(Map<String, dynamic> json) {
    return RevenueTrendData(
      label: json['label'],
      value: (json['value'] as num).toDouble(),
    );
  }
}

class InsightItem {
  final int id;
  final String name;
  final int? firmId;
  final String? firmName;
  final double revenue;
  final int transactions;
  final double percent;

  InsightItem({
    required this.id,
    required this.name,
    this.firmId,
    this.firmName,
    required this.revenue,
    required this.transactions,
    required this.percent,
  });

  factory InsightItem.fromJson(Map<String, dynamic> json) {
    return InsightItem(
      id: json['id'],
      name: json['name'],
      firmId: json['firmId'],
      firmName: json['firmName'],
      revenue: (json['revenue'] as num).toDouble(),
      transactions: json['transactions'],
      percent: (json['percent'] as num).toDouble(),
    );
  }
}
