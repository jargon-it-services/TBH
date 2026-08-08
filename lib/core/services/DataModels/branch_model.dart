/// ================= BRANCH (LIST ITEM) =================
///
/// Lightweight shape returned by `GET /branches` — just enough to
/// render the Branch List screen (card/list tile + search). Full
/// details (working hours, weekly off, services, etc.) live in
/// [BranchDetailResponse], fetched separately per-branch.
class BranchModel {
  final int id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String mobile;
  final String branchType;
  final String status;

  /// Branch logo URL, when the branch has one uploaded. Null/empty
  /// means "no logo" — callers fall back to the existing icon-based
  /// avatar rather than treating this as an error.
  final String? logo;

  bool get isActive => status.toLowerCase() == 'active';
  bool get hasLogo => logo != null && logo!.trim().isNotEmpty;

  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.mobile,
    required this.branchType,
    required this.status,
    this.logo,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      mobile: json['mobile'] ?? '',
      branchType: json['branch_type'] ?? '',
      status: json['status'] ?? '',
      logo: json['logo'] as String?,
    );
  }
}
