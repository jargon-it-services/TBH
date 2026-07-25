// dashboard_header_model.dart
//
// Models backing the role-aware Dashboard sticky header
// ([StickyOrgHeader] + [DashboardStickyHeader]).

/// ================= SCOPE ENTITY =================
///
/// A single switchable "scope" the header's dropdown can point at.
/// On the wire this is the same shape whether it represents an
/// Organization/Account (Super Admin) or a Branch (Account Admin and
/// the assigned-branch roles below it) — id, name, and an optional
/// short code — so one model serves both instead of near-duplicate
/// `OrganizationModel` / `BranchModel` classes.
class BranchModel {
  final String id;
  final String name;
  final String? code;

  const BranchModel({
    required this.id,
    required this.name,
    this.code,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (code != null) 'code': code,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is BranchModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Sentinel value representing "All Organizations" / "All Branches"
/// selected in the switcher — see [StickyOrgHeader._branchLabel].
class AllBranches extends BranchModel {
  const AllBranches() : super(id: '__all__', name: 'All');
}

/// ================= DASHBOARD HEADER RESPONSE =================
///
/// Everything [DashboardStickyHeader] needs to render, already scoped
/// server-side to the logged-in user's role (the backend reads the
/// role off the auth token, same as every other protected endpoint —
/// see [DioClient]). Only the fields relevant to the caller's role are
/// expected to be non-empty:
///   - Super Admin    -> [organizations] populated, [branches] empty,
///                        [assignedBranch] null.
///   - Account Admin  -> [branches] populated, [organizations] empty,
///                        [assignedBranch] null.
///   - Branch Admin / Manager / Employee -> [assignedBranch] set,
///                        both lists empty.
/// Nothing in [DashboardStickyHeader] hardcodes which of these is
/// used for a given role beyond that mapping — see
/// `_DashboardStickyHeaderState._resolveViewModel`.
class DashboardHeaderModel {
  final String orgName;
  final String accountCode;

  /// Human-readable role label, e.g. "Super Admin". Falls back to
  /// [UserRole.displayName] at the call site when the backend omits
  /// it, so this is optional here.
  final String roleLabel;

  final int notificationCount;
  final String profileInitials;

  /// Super Admin only: the list of Organizations/Accounts they can
  /// switch between.
  final List<BranchModel> organizations;

  /// Account Admin only: the list of Branches under their account.
  final List<BranchModel> branches;

  /// Branch Admin / Manager / Employee only: their single assigned
  /// branch.
  final BranchModel? assignedBranch;

  /// Optional "currently selected" ids so a returning user sees the
  /// same scope they last had, instead of the picker always resetting
  /// to the "All ..." aggregate. Null/unmatched safely falls back to
  /// the aggregate view.
  final String? selectedOrganizationId;
  final String? selectedBranchId;

  DashboardHeaderModel({
    required this.orgName,
    required this.accountCode,
    required this.roleLabel,
    required this.notificationCount,
    required this.profileInitials,
    required this.organizations,
    required this.branches,
    required this.assignedBranch,
    required this.selectedOrganizationId,
    required this.selectedBranchId,
  });

  factory DashboardHeaderModel.fromJson(Map<String, dynamic> json) {
    return DashboardHeaderModel(
      orgName: json['org_name'] ?? '',
      accountCode: json['account_code'] ?? '',
      roleLabel: json['role_label'] ?? '',
      notificationCount: json['notification_count'] ?? 0,
      profileInitials: json['profile_initials'] ?? '',
      organizations: (json['organizations'] as List? ?? [])
          .map((e) => BranchModel.fromJson(e))
          .toList(),
      branches: (json['branches'] as List? ?? [])
          .map((e) => BranchModel.fromJson(e))
          .toList(),
      assignedBranch: json['assigned_branch'] != null
          ? BranchModel.fromJson(json['assigned_branch'])
          : null,
      selectedOrganizationId: json['selected_organization_id']?.toString(),
      selectedBranchId: json['selected_branch_id']?.toString(),
    );
  }
}
