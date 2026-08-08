class TransactionsResponse {
  final bool success;
  final String message;
  final TransactionsData data;

  TransactionsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TransactionsResponse.fromJson(Map<String, dynamic> json) {
    return TransactionsResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: TransactionsData.fromJson(json['data'] ?? {}),
    );
  }
}

class TransactionsData {
  final TransactionsMeta meta;
  final TransactionFilters filters;
  final List<TransactionModel> transactions;

  TransactionsData({
    required this.meta,
    required this.filters,
    required this.transactions,
  });

  factory TransactionsData.fromJson(Map<String, dynamic> json) {
    return TransactionsData(
      meta: TransactionsMeta.fromJson(json['meta'] ?? {}),
      filters: TransactionFilters.fromJson(json['filters'] ?? {}),
      transactions: (json['transactions'] as List? ?? [])
          .map((e) => TransactionModel.fromJson(e))
          .toList(),
    );
  }
}

/// `data.meta` — currently just the plan-driven `feature_lock` list
/// gating creation/editing of transactions app-wide (see
/// [TransactionsX.isFeatureLocked] below and `TransactionsPage`'s FAB).
class TransactionsMeta {
  final List<String> featureLock;

  TransactionsMeta({required this.featureLock});

  factory TransactionsMeta.fromJson(Map<String, dynamic> json) {
    return TransactionsMeta(
      featureLock:
          (json['feature_lock'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}

class TransactionFilters {
  final List<String> branches;
  final List<String> services;
  final List<String> staff;
  final List<String> statuses;
  final List<String> types;
  final List<String> paymentModes;
  final List<String> periods;
  final String currency;

  TransactionFilters({
    required this.branches,
    required this.services,
    required this.staff,
    required this.statuses,
    required this.types,
    required this.paymentModes,
    required this.periods,
    required this.currency,
  });

  factory TransactionFilters.fromJson(Map<String, dynamic> json) {
    return TransactionFilters(
      branches: List<String>.from(json['branches'] ?? []),
      services: List<String>.from(json['services'] ?? []),
      staff: List<String>.from(json['staff'] ?? []),
      statuses: List<String>.from(json['statuses'] ?? []),
      types: List<String>.from(json['types'] ?? []),
      paymentModes: List<String>.from(json['paymentMode'] ?? []),
      periods: List<String>.from(json['periods'] ?? []),
      currency: json['currency'] ?? 'INR',
    );
  }
}

class TransactionModel {
  final String id;
  final String title;
  final String branch;
  final int branchId;
  final String service;
  final int serviceId;
  final String staff;
  final int staffId;
  final String status;
  final String type;
  final double amount;
  final String paymentMode;
  final String customerName;
  final int customerId;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.title,
    required this.branch,
    required this.branchId,
    required this.service,
    required this.serviceId,
    required this.staff,
    required this.staffId,
    required this.status,
    required this.type,
    required this.amount,
    required this.paymentMode,
    required this.customerName,
    required this.customerId,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      branch: json['branch'] ?? '',
      branchId: json['branchId'] ?? 0,
      service: json['service'] ?? '',
      serviceId: json['serviceId'] ?? 0,
      staff: json['staff'] ?? '',
      staffId: json['staffId'] ?? 0,
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['paymentMode'] ?? '',
      customerName: json['customerName'] ?? '',
      customerId: json['customerId'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/* Optional helpers for UI logic */
extension TransactionX on TransactionModel {
  bool get isPaid => status == 'paid';
  bool get isExpense => type == 'expense';
}

extension TransactionsMetaX on TransactionsMeta {
  bool isFeatureLocked(String featureKey) => featureLock.contains(featureKey);
}
