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
  final FirmInfo firm;
  final StaffInfo staff;
  final String? remark;

  TransactionDetails({
    required this.id,
    required this.status,
    required this.paymentMode,
    required this.type,
    required this.category,
    required this.priceBreakdown,
    required this.dateTime,
    required this.firm,
    required this.staff,
    this.remark,
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
      firm: FirmInfo.fromJson(json['firm']),
      staff: StaffInfo.fromJson(json['staff']),
      remark: json['remark'],
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

/* ================= FIRM ================= */

class FirmInfo {
  final String id;
  final String name;
  final String location;

  FirmInfo({
    required this.id,
    required this.name,
    required this.location,
  });

  factory FirmInfo.fromJson(Map<String, dynamic> json) {
    return FirmInfo(
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
