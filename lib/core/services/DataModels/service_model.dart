/// ================= SERVICE (CATALOG) =================
///
/// One entry from the master Services catalog (`GET /services`) — used
/// to populate the Branch Create/Edit form's service picker. Per the
/// Branch module spec, services are never typed in manually; they're
/// always selected from this catalog.
class ServiceModel {
  final int id;
  final String name;
  final bool active;

  ServiceModel({
    required this.id,
    required this.name,
    this.active = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      active: json['active'] ?? true,
    );
  }
}
