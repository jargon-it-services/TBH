/// ================= SERVICE (LIST ITEM) =================
///
/// Lightweight shape returned by `GET /services/list` — just enough to
/// render the Service List screen (card/list tile + search/filter).
/// Full details (pricing/profit breakdown, home service, branch
/// assignment, etc.) live in [ServiceDetailResponse], fetched
/// separately per-service. Mirrors how [BranchModel] /
/// `BranchDetailResponse` are split for the Branches feature.
///
/// Distinct from the pre-existing, even-lighter `ServiceModel`
/// (`core/services/DataModels/service_model.dart`), which only backs
/// the Branch Create/Edit form's service picker (id/name/active) and is
/// left untouched here so that usage keeps working unchanged.
class ServiceListItem {
  final int id;
  final String name;
  final String category;
  final String applicableGender;
  final int durationMinutes;
  final double customerPrice;
  final String status;
  final String type;

  /// Service photo URL, when uploaded. Null/empty means "no photo" —
  /// callers fall back to a category icon avatar, same fallback
  /// pattern [BranchModel.hasLogo] uses for branch logos.
  final String? photo;

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasPhoto => photo != null && photo!.trim().isNotEmpty;

  ServiceListItem({
    required this.id,
    required this.name,
    required this.category,
    required this.applicableGender,
    required this.durationMinutes,
    required this.customerPrice,
    required this.status,
    this.type = 'Service',
    this.photo,
  });

  factory ServiceListItem.fromJson(Map<String, dynamic> json) {
    return ServiceListItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      applicableGender: json['applicable_gender'] ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      customerPrice: (json['customer_price'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? '',
      type: json['type'] ?? 'Service',
      photo: json['photo'] as String?,
    );
  }
}
