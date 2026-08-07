/// ================= TRANSACTION ENTRY — BOOTSTRAP =================
///
/// `GET /transactions/bootstrap` — everything the Transaction Entry
/// screen needs in one round trip (services, expenses, staff,
/// branches, role, and the backend-remembered last payment
/// mode/transaction type) instead of five separate calls. Deliberately
/// a new model rather than reusing [TransactionModel]/[TransactionDetails]
/// — those describe a *saved* transaction for display; this describes
/// the *master data* used to build one.
class TransactionBootstrapData {
  final List<BootstrapService> services;
  final List<BootstrapLookupItem> expenses;
  final List<BootstrapLookupItem> staff;
  final List<BootstrapLookupItem> branches;

  /// e.g. "employee" | "manager" | "branch_admin" | "account_admin" —
  /// drives every role-based rule in the spec (Branch/Staff
  /// auto-fill vs. selectable). The app never hardcodes role names
  /// beyond matching against these exact backend-provided strings.
  final String userRole;
  final int loggedInUserId;
  final int loggedInBranchId;

  /// Backend-remembered preferences — the *source of truth* for "last
  /// used" values. There's no local storage mechanism for this: the
  /// screen simply seeds its in-memory Payment Mode/Transaction Type
  /// state from these on open, exactly like every other bootstrap
  /// field, per the spec's "no new storage mechanism" instruction.
  final String? lastPaymentMode;
  final String? lastTransactionType;

  TransactionBootstrapData({
    required this.services,
    required this.expenses,
    required this.staff,
    required this.branches,
    required this.userRole,
    required this.loggedInUserId,
    required this.loggedInBranchId,
    this.lastPaymentMode,
    this.lastTransactionType,
  });

  factory TransactionBootstrapData.fromJson(Map<String, dynamic> json) {
    return TransactionBootstrapData(
      services: (json['services'] as List? ?? [])
          .map((e) => BootstrapService.fromJson(e))
          .toList(),
      expenses: (json['expenses'] as List? ?? [])
          .map((e) => BootstrapLookupItem.fromJson(e))
          .toList(),
      staff: (json['staff'] as List? ?? [])
          .map((e) => BootstrapLookupItem.fromJson(e))
          .toList(),
      branches: (json['branches'] as List? ?? [])
          .map((e) => BootstrapLookupItem.fromJson(e))
          .toList(),
      userRole: json['user_role'] ?? '',
      loggedInUserId: (json['logged_in_user_id'] as num?)?.toInt() ?? 0,
      loggedInBranchId: (json['logged_in_branch_id'] as num?)?.toInt() ?? 0,
      lastPaymentMode: json['last_payment_mode'] as String?,
      lastTransactionType: json['last_transaction_type'] as String?,
    );
  }
}

class BootstrapService {
  final int id;
  final String name;
  final double price;
  final bool frequent;

  BootstrapService({
    required this.id,
    required this.name,
    required this.price,
    this.frequent = false,
  });

  factory BootstrapService.fromJson(Map<String, dynamic> json) {
    return BootstrapService(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      frequent: json['frequent'] ?? false,
    );
  }
}

/// Shared shape for Expense, Staff, and Branch bootstrap entries — all
/// three are just an id/name pair the form picks from.
class BootstrapLookupItem {
  final int id;
  final String name;

  BootstrapLookupItem({required this.id, required this.name});

  factory BootstrapLookupItem.fromJson(Map<String, dynamic> json) {
    return BootstrapLookupItem(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

/// ================= LOCAL CART LINE =================
///
/// A selected service in the "Selected Services" list — local-only
/// state, never sent as-is (see `TransactionEntryPage._buildPayload`
/// which flattens this to `{service_id, qty}`). `lineTotal` is always
/// derived (`price * qty`), never independently editable, per the
/// spec's "Amount is never editable" rule.
class SelectedServiceLine {
  final int serviceId;
  final String name;
  final double price;
  int qty;

  SelectedServiceLine({
    required this.serviceId,
    required this.name,
    required this.price,
    this.qty = 1,
  });

  double get lineTotal => price * qty;
}

/// ================= CREATE / UPDATE RESULT =================
///
/// Response shape shared by create (`POST /transactions`) and update
/// (`PUT /transactions/{id}`) — both return the saved transaction in
/// this same shape per the spec, just with `edit_count`/
/// `last_edited_*` populated differently.
class TransactionSaveResult {
  final String id;
  final String status;
  final double grandTotal;
  final String? customerName;
  final String? customerMobile;
  final bool canEdit;
  final DateTime? editableUntil;
  final String? lastEditedBy;
  final DateTime? lastEditedAt;
  final int editCount;

  TransactionSaveResult({
    required this.id,
    required this.status,
    required this.grandTotal,
    this.customerName,
    this.customerMobile,
    this.canEdit = false,
    this.editableUntil,
    this.lastEditedBy,
    this.lastEditedAt,
    this.editCount = 0,
  });

  factory TransactionSaveResult.fromJson(Map<String, dynamic> json) {
    return TransactionSaveResult(
      id: (json['id'] ?? '').toString(),
      status: json['status'] ?? '',
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      customerName: json['customer_name'] as String?,
      customerMobile: json['customer_mobile'] as String?,
      canEdit: json['can_edit'] ?? false,
      editableUntil: json['editable_until'] != null
          ? DateTime.tryParse(json['editable_until'])
          : null,
      lastEditedBy: json['last_edited_by'] as String?,
      lastEditedAt: json['last_edited_at'] != null
          ? DateTime.tryParse(json['last_edited_at'])
          : null,
      editCount: (json['edit_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// ================= MARK AS PAID RESULT =================
class TransactionMarkPaidResult {
  final String id;
  final String status;
  final DateTime? paidAt;

  TransactionMarkPaidResult({required this.id, required this.status, this.paidAt});

  factory TransactionMarkPaidResult.fromJson(Map<String, dynamic> json) {
    return TransactionMarkPaidResult(
      id: (json['id'] ?? '').toString(),
      status: json['status'] ?? '',
      paidAt: json['paid_at'] != null ? DateTime.tryParse(json['paid_at']) : null,
    );
  }
}
