/// ================= SERVICE BRANCH (ASSIGNMENT) =================
///
/// A branch this service is offered at, as attached to the service
/// itself — distinct from `BranchModel` (the full branch record).
/// Only carries what the Service Details screen needs to display,
/// mirroring `BranchServiceItem`'s role on the Branch Details screen.
class ServiceBranchItem {
  final int id;
  final String name;

  ServiceBranchItem({required this.id, required this.name});

  factory ServiceBranchItem.fromJson(Map<String, dynamic> json) {
    return ServiceBranchItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// ================= SERVICE DETAIL =================
///
/// Full service record — backs both the Service Details screen and the
/// Edit Service form (pre-filling every field). Mirrors the
/// `BranchDetailResponse` split: [ServiceListItem] is the trimmed
/// list-item shape, this is the complete one, fetched per-service via
/// `ServicesApi.fetchServiceDetail`.
class ServiceDetailResponse {
  // ------------- Basic Information -------------
  final int id;
  final String name;
  final String description;
  final String? photo;
  final String category;
  final int durationMinutes;
  final String applicableGender;

  /// Always "Service" — read-only per the Service module spec, but
  /// still carried on the model (rather than hardcoded in the UI) so a
  /// future service "type" from the backend is picked up automatically.
  final String type;
  final String status;

  // ------------- Pricing -------------
  final double customerPrice;
  final double materialCost;

  /// "Fixed Amount" or "Percentage" — decides how [commissionValue] is
  /// interpreted when computing [staffCommissionAmount]/[profit].
  final String commissionType;
  final double commissionValue;
  final double otherCost;

  // ------------- Home Service -------------
  final bool homeServiceAvailable;
  final double? homeVisitCharges;
  final double? serviceRadiusKm;
  final double? extraChargePerKm;

  // ------------- Branch Assignment -------------
  final bool allBranches;
  final List<ServiceBranchItem> branches;

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasPhoto => photo != null && photo!.trim().isNotEmpty;

  /// The staff commission amount in currency, resolved from
  /// [commissionType]/[commissionValue] per the spec:
  /// `Customer Price × Commission %` when Percentage, otherwise the
  /// fixed [commissionValue] as-is.
  double get staffCommissionAmount {
    if (commissionType == 'Percentage') {
      return customerPrice * (commissionValue / 100);
    }
    return commissionValue;
  }

  /// `Profit = Customer Price - Material Cost - Staff Commission -
  /// Other Cost`, with Staff Commission already resolved for either
  /// Commission Type via [staffCommissionAmount] — matches the spec's
  /// Fixed Amount and Percentage formulas.
  double get profit =>
      customerPrice - materialCost - staffCommissionAmount - otherCost;

  ServiceDetailResponse({
    required this.id,
    required this.name,
    required this.description,
    this.photo,
    required this.category,
    required this.durationMinutes,
    required this.applicableGender,
    this.type = 'Service',
    required this.status,
    required this.customerPrice,
    required this.materialCost,
    required this.commissionType,
    required this.commissionValue,
    required this.otherCost,
    this.homeServiceAvailable = false,
    this.homeVisitCharges,
    this.serviceRadiusKm,
    this.extraChargePerKm,
    this.allBranches = true,
    this.branches = const [],
  });

  factory ServiceDetailResponse.fromJson(Map<String, dynamic> json) {
    return ServiceDetailResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      photo: json['photo'] as String?,
      category: json['category'] ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      applicableGender: json['applicable_gender'] ?? '',
      type: json['type'] ?? 'Service',
      status: json['status'] ?? '',
      customerPrice: (json['customer_price'] as num?)?.toDouble() ?? 0,
      materialCost: (json['material_cost'] as num?)?.toDouble() ?? 0,
      commissionType: json['commission_type'] ?? 'Fixed Amount',
      commissionValue: (json['commission_value'] as num?)?.toDouble() ?? 0,
      otherCost: (json['other_cost'] as num?)?.toDouble() ?? 0,
      homeServiceAvailable: json['home_service_available'] ?? false,
      homeVisitCharges: (json['home_visit_charges'] as num?)?.toDouble(),
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toDouble(),
      extraChargePerKm: (json['extra_charge_per_km'] as num?)?.toDouble(),
      allBranches: json['all_branches'] ?? true,
      branches: (json['branches'] as List? ?? [])
          .map((e) => ServiceBranchItem.fromJson(e))
          .toList(),
    );
  }
}
