import 'dart:convert';

import 'package:flutter/services.dart';

import '../../services/DataModels/subscription_models.dart';
import '../api_response.dart';
import '../dio_client.dart';
import '../env.dart';

/// Selects which mock fixture [SubscriptionApi.fetchSubscriptionStatus]
/// loads when [Env.isMock] is true -- one file per lifecycle state from
/// subscription-api-responses.md, the same "one JSON per scenario"
/// convention `DashboardApi.fetchRevenueTrend` already uses for its
/// next/prev cursor fixtures. Has zero effect once [Env.isMock] is
/// false -- the live branch always just calls the real endpoint for
/// whichever `orgId` it's given.
enum SubscriptionMockScenario {
  firstPurchase,
  trial,
  activeExpiringSoon,
  activeHealthy,
  expired,
  suspended,
  cancelled;

  String get _assetPath {
    switch (this) {
      case SubscriptionMockScenario.firstPurchase:
        return 'assets/mocks/subscription_status_first_purchase.json';
      case SubscriptionMockScenario.trial:
        return 'assets/mocks/subscription_status_trial.json';
      case SubscriptionMockScenario.activeExpiringSoon:
        return 'assets/mocks/subscription_status_active_expiring.json';
      case SubscriptionMockScenario.activeHealthy:
        return 'assets/mocks/subscription_status_active_healthy.json';
      case SubscriptionMockScenario.expired:
        return 'assets/mocks/subscription_status_expired.json';
      case SubscriptionMockScenario.suspended:
        return 'assets/mocks/subscription_status_suspended.json';
      case SubscriptionMockScenario.cancelled:
        return 'assets/mocks/subscription_status_cancelled.json';
    }
  }
}

class SubscriptionApi {
  final DioClient _client = DioClient();

  /// `GET /plans` -- the static-ish plan catalog, independent of any
  /// one org.
  Future<ApiResponse<PlanCatalogResponse>> fetchPlanCatalog() async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(milliseconds: 700));

        final String raw = await rootBundle.loadString(
          'assets/mocks/subscription_plans_catalog.json',
        );

        return ApiResponse.success(
          PlanCatalogResponse.fromJson(json.decode(raw)),
        );
      } else {
        final response = await _client.get('/plans');
        return ApiResponse.success(
          PlanCatalogResponse.fromJson(response.data),
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }

  /// `GET /organizations/{orgId}/subscription` -- same response shape
  /// for every lifecycle state; only field values differ (see
  /// [SubscriptionStatusResponse]). [mockScenario] only matters when
  /// [Env.isMock] is true (see [SubscriptionMockScenario]).
  Future<ApiResponse<SubscriptionStatusResponse>> fetchSubscriptionStatus({
    required String orgId,
    SubscriptionMockScenario mockScenario = SubscriptionMockScenario.trial,
  }) async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(milliseconds: 900));

        final String raw = await rootBundle.loadString(
          mockScenario._assetPath,
        );

        return ApiResponse.success(
          SubscriptionStatusResponse.fromJson(json.decode(raw)),
        );
      } else {
        final response =
            await _client.get('/organizations/$orgId/subscription');
        return ApiResponse.success(
          SubscriptionStatusResponse.fromJson(response.data),
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }

  /// Activates a free trial directly (contract §9: `isFree: true` plans
  /// skip the Razorpay flow entirely and call activation directly).
  ///
  /// The API contract doesn't define this endpoint's path yet -- only
  /// that it must exist and must be called instead of the payment flow
  /// for free plans. This follows the exact same `Env.isMock` shape as
  /// every other method here so swapping in the real path later, once
  /// confirmed, is a one-line change and not a new pattern.
  Future<ApiResponse<void>> activateFreeTrial({required String orgId}) async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(seconds: 1));
        return ApiResponse.success(null);
      } else {
        await _client.post(
          '/organizations/$orgId/subscription/activate-trial',
        );
        return ApiResponse.success(null);
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }
}
