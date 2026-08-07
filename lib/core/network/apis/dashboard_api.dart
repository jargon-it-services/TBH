import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../services/DataModels/dashboard_models.dart';
import '../../services/DataModels/overview_trend_model.dart';
import '../api_response.dart';
import '../dio_client.dart';
import '../env.dart';

class DashboardApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_015 - Fetch Admin Dashboard
  // Endpoint: GET /dashboard
  // Backend Doc Ref: API_015
  // ==========================================================
  Future<ApiResponse<DashboardResponse>> fetchAdminDashboard() async {
    try {
      if (Env.isMock) {
        // simulate network delay
        await Future.delayed(const Duration(seconds: 2));

        // load local JSON
        final String response = await rootBundle
            .loadString('assets/mocks/dashboard_admin_response.json');

        final Map<String, dynamic> jsonData = json.decode(response);

        final dashboard = DashboardResponse.fromJson(jsonData);

        return ApiResponse.success(dashboard);
      } else {
        final Response response = await _client.get('/dashboard');

        return ApiResponse.success(
          DashboardResponse.fromJson(response.data),
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }

  // ==========================================================
  // API_016 - Fetch Revenue Trend
  // Endpoint: GET /dashboard/revenue-trend
  // Backend Doc Ref: API_016
  // ==========================================================
  /// Fetch revenue trend (cursor based pagination)
  Future<ApiResponse<OverviewTrendModel>> fetchRevenueTrend({
    required String period,
    required bool isNext, // only for mock selection
    String? cursor,
  }) async {
    try {
      if (Env.isMock) {
        // simulate network delay
        await Future.delayed(const Duration(seconds: 2));

        // load local JSON
        final String response = await rootBundle.loadString(
          isNext
              ? 'assets/mocks/trend_next.json'
              : 'assets/mocks/trend_prev.json',
        );

        final Map<String, dynamic> jsonData = json.decode(response);

        // ✅ parse ONLY overviewTrend
        final OverviewTrendModel trend =
            OverviewTrendModel.fromJson(jsonData['data']['overviewTrend']);

        return ApiResponse.success(trend);
      } else {
        final response = await _client.get(
          '/dashboard/revenue-trend',
          queryParameters: {
            'period': period.toLowerCase(),
            if (cursor != null) 'cursor': cursor,
          },
        );

        if (response.statusCode == 200 && response.data['status'] == true) {
          return ApiResponse.success(
            OverviewTrendModel.fromJson(
              response.data['data']['overviewTrend'],
            ),
          );
        } else {
          return ApiResponse.failure('Failed to load revenue trend');
        }
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
