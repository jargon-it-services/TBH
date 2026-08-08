/* ================= ROOT RESPONSE ================= */

class TransactionDetailsResponse {
  final TransactionDetails transaction;

  TransactionDetailsResponse({required this.transaction});

  factory TransactionDetailsResponse.fromJson(Map<String, dynamic> json) {
    return TransactionDetailsResponse(
      transaction: TransactionDetails.fromJson(json['data']['transaction']),
    );
  }
}

/* ================= TRANSACTION ================= */

class TransactionDetails {
  final String id;
  final String status;
  final String paymentMode;
  final String type;
  final String category;

  final PriceBreakdown priceBreakdown;
  final TransactionDateTime dateTime;
  final BranchInfo branch;
  final StaffInfo staff;
  final String? remark;

  /// Whether the Edit action should be shown on Transaction Details —
  /// purely a display decision. The backend independently re-validates
  /// the edit window server-side on every update request regardless of
  /// what this said when the screen was opened (see
  /// `TransactionApi.updateTransaction`'s 409 handling) — the app never
  /// hardcodes the actual window duration anywhere.
  final bool canEdit;

  /// ISO-8601 deadline this transaction stops being editable — display
  /// only (e.g. "editable for x more minutes"); the app never computes
  /// or stores a duration from this, just shows it as-is if needed.
  final DateTime? editableUntil;

  final String? lastEditedBy;
  final DateTime? lastEditedAt;
  final int editCount;

  TransactionDetails({
    required this.id,
    required this.status,
    required this.paymentMode,
    required this.type,
    required this.category,
    required this.priceBreakdown,
    required this.dateTime,
    required this.branch,
    required this.staff,
    this.remark,
    this.canEdit = false,
    this.editableUntil,
    this.lastEditedBy,
    this.lastEditedAt,
    this.editCount = 0,
  });

  factory TransactionDetails.fromJson(Map<String, dynamic> json) {
    return TransactionDetails(
      id: json['id'],
      status: json['status'],
      paymentMode: json['paymentMode'],
      type: json['type'],
      category: json['category'],
      priceBreakdown: PriceBreakdown.fromJson(json['priceBreakdown']),
      dateTime: TransactionDateTime.fromJson(json['dateTime']),
      branch: BranchInfo.fromJson(json['branch']),
      staff: StaffInfo.fromJson(json['staff']),
      remark: json['remark'],
      canEdit: json['can_edit'] ?? false,
      editableUntil: json['editable_until'] != null
          ? DateTime.tryParse(json['editable_until'])
          : null,
      lastEditedBy: json['last_edited_by'],
      lastEditedAt: json['last_edited_at'] != null
          ? DateTime.tryParse(json['last_edited_at'])
          : null,
      editCount: (json['edit_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/* ================= PRICE BREAKDOWN ================= */

class PriceBreakdown {
  final List<ServiceItem> services;
  final CouponInfo? coupon;
  final PriceSummary summary;

  PriceBreakdown({
    required this.services,
    required this.summary,
    this.coupon,
  });

  factory PriceBreakdown.fromJson(Map<String, dynamic> json) {
    return PriceBreakdown(
      services: (json['services'] as List)
          .map((e) => ServiceItem.fromJson(e))
          .toList(),
      coupon:
          json['coupon'] != null ? CouponInfo.fromJson(json['coupon']) : null,
      summary: PriceSummary.fromJson(json['summary']),
    );
  }
}

/* ================= SERVICE ITEM ================= */

class ServiceItem {
  final int id;
  final String title;
  final int quantity;

  final num baseAmount;
  final num taxPercentage;
  final num taxAmount;

  final num discountPercentage;
  final num discountAmount;

  final num grossAmount;
  final num netAmount;

  ServiceItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.baseAmount,
    required this.taxPercentage,
    required this.taxAmount,
    required this.discountPercentage,
    required this.discountAmount,
    required this.grossAmount,
    required this.netAmount,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'],
      title: json['title'],
      quantity: json['quantity'],
      baseAmount: json['baseAmount'],
      taxPercentage: json['taxPercentage'],
      taxAmount: json['taxAmount'],
      discountPercentage: json['discountPercentage'],
      discountAmount: json['discountAmount'],
      grossAmount: json['grossAmount'],
      netAmount: json['netAmount'],
    );
  }
}

/* ================= COUPON ================= */

class CouponInfo {
  final String code;
  final String type;
  final num value;
  final num discountAmount;

  CouponInfo({
    required this.code,
    required this.type,
    required this.value,
    required this.discountAmount,
  });

  factory CouponInfo.fromJson(Map<String, dynamic> json) {
    return CouponInfo(
      code: json['code'],
      type: json['type'],
      value: json['value'],
      discountAmount: json['discountAmount'],
    );
  }
}

/* ================= SUMMARY ================= */

class PriceSummary {
  final num subtotal;
  final num taxPercentage;
  final num taxAmount;
  final num couponDiscount;
  final num total;
  final String currency;

  PriceSummary({
    required this.subtotal,
    required this.taxPercentage,
    required this.taxAmount,
    required this.couponDiscount,
    required this.total,
    required this.currency,
  });

  factory PriceSummary.fromJson(Map<String, dynamic> json) {
    return PriceSummary(
      subtotal: json['subtotal'],
      taxPercentage: json['taxPercentage'],
      taxAmount: json['taxAmount'],
      couponDiscount: json['couponDiscount'],
      total: json['total'],
      currency: json['currency'],
    );
  }
}

/* ================= DATE TIME ================= */

class TransactionDateTime {
  final DateTime iso;
  final String display;

  TransactionDateTime({
    required this.iso,
    required this.display,
  });

  factory TransactionDateTime.fromJson(Map<String, dynamic> json) {
    return TransactionDateTime(
      iso: DateTime.parse(json['iso']),
      display: json['display'],
    );
  }
}

/* ================= BRANCH ================= */

class BranchInfo {
  final String id;
  final String name;
  final String location;

  BranchInfo({
    required this.id,
    required this.name,
    required this.location,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      id: json['id'],
      name: json['name'],
      location: json['location'],
    );
  }
}

/* ================= STAFF ================= */

class StaffInfo {
  final String id;
  final String name;

  StaffInfo({
    required this.id,
    required this.name,
  });

  factory StaffInfo.fromJson(Map<String, dynamic> json) {
    return StaffInfo(
      id: json['id'],
      name: json['name'],
    );
  }
}
