import 'dashboard_models.dart';

class OverviewTrendModel {
  final String period;
  final int limit;
  final bool hasMoreData;
  final String range;
  final List<TrendPoint> points;
  final String? nextCursor;
  final String? prevCursor;

  OverviewTrendModel({
    required this.period,
    required this.limit,
    required this.hasMoreData,
    required this.range,
    required this.points,
    this.nextCursor,
    this.prevCursor,
  });

  factory OverviewTrendModel.fromJson(Map<String, dynamic> json) {
    return OverviewTrendModel(
      period: json['period'] ?? '',
      limit: json['limit'] ?? 12,
      hasMoreData: json['hasMoreData'] ?? false,
      range: json['range'] ?? '',
      points: (json['points'] as List? ?? [])
          .map((e) => TrendPoint.fromJson(e))
          .toList(),
      nextCursor: json['nextCursor'],
      prevCursor: json['prevCursor'],
    );
  }
}
