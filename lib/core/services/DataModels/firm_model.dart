/// ================= FIRM =================
///
/// Previously defined inside `dashboard_models.dart`. Moved out to its
/// own file because it's actually a Firms-feature model (used by
/// [FirmsApi.fetchFirms] and the Firms list screen) that the old
/// dashboard code happened to also read from — it has nothing to do
/// with the dashboard itself.
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
