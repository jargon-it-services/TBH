import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../services/DataModels/notification_model.dart';
import '../api_response.dart';
import '../dio_client.dart';
import '../env.dart';

/// API service for the Notification Module.
///
/// Deliberately the same plain, single-purpose shape as every other
/// `*_api.dart` file (`PaymentHistoryApi`, `TransactionApi`, ...): a
/// `DioClient` singleton, an `Env.isMock` branch per method loading a
/// local JSON fixture, and a live branch calling the real endpoint per
/// `02_API_Contracts.md`. No new networking pattern is introduced.
///
/// Base path: `/api/v1/notifications`.
class NotificationApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_067 - Fetch Notifications
  // Endpoint: GET /api/v1/notifications
  // Backend Doc Ref: API_067
  // ==========================================================
  /// `GET /api/v1/notifications` -- returns the full, unpaginated list.
  /// Per the contract there is no server-side search/filtering yet, so
  /// this is the only call `NotificationListPage` makes to populate
  /// itself; search and the All/Unread/Read chips are both applied
  /// locally against the list this returns.
  Future<ApiResponse<NotificationListResponse>> fetchNotifications() async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(milliseconds: 900));

        final String response = await rootBundle
            .loadString('assets/mocks/notifications_response.json');

        final Map<String, dynamic> jsonData = json.decode(response);

        return ApiResponse.success(
          NotificationListResponse.fromJson(jsonData),
        );
      } else {
        final Response response = await _client.get('/api/v1/notifications');

        if (response.statusCode == 200 && response.data?['status'] == true) {
          return ApiResponse.success(
            NotificationListResponse.fromJson(response.data),
          );
        }
        return ApiResponse.failure(
          response.data?['message'] ?? 'Failed to load notifications',
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }

  // ==========================================================
  // API_068 - Fetch Notification By Id
  // Endpoint: GET /api/v1/notifications/{id}
  // Backend Doc Ref: API_068
  // ==========================================================
  /// `GET /api/v1/notifications/{id}` -- optional per the contract
  /// ("use only if notification detail is not fully included in the
  /// list response"). `NotificationNavigator` calls this specifically
  /// when a push/deep-link payload arrives with only
  /// `{id, display_mode, destination}` (see `04_OneSignal_Integration.md`'s
  /// payload) and `display_mode` is `notification_detail`, since that
  /// screen needs the full title/message/actions the slim push
  /// payload doesn't carry.
  Future<ApiResponse<NotificationModel>> fetchNotificationById(
    int notificationId,
  ) async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(milliseconds: 400));

        final String response = await rootBundle
            .loadString('assets/mocks/notifications_response.json');
        final Map<String, dynamic> jsonData = json.decode(response);
        final list = NotificationListResponse.fromJson(jsonData);

        final match = list.notifications.where((n) => n.id == notificationId);
        if (match.isEmpty) {
          return ApiResponse.failure('Notification not found');
        }
        return ApiResponse.success(match.first);
      } else {
        final Response response =
            await _client.get('/api/v1/notifications/$notificationId');

        if (response.statusCode == 200 && response.data?['status'] == true) {
          final data = response.data['data'];
          final notificationJson =
              data is Map<String, dynamic> && data.containsKey('notification')
                  ? data['notification']
                  : data;
          return ApiResponse.success(
            NotificationModel.fromJson(notificationJson),
          );
        }
        return ApiResponse.failure(
          response.data?['message'] ?? 'Failed to load notification',
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }

  // ==========================================================
  // API_069 - Mark Notification Read
  // Endpoint: POST /api/v1/notifications/read
  // Backend Doc Ref: API_069
  // ==========================================================
  /// `POST /api/v1/notifications/read` -- marks a single notification
  /// read. Callers apply the local optimistic update themselves (see
  /// `NotificationNavigator`/`NotificationListPage`) and treat this as
  /// fire-and-forget-ish best effort; a failure here is logged/ignored
  /// rather than surfaced, per the "Never crash / gracefully handle
  /// failed mark-as-read API" requirement.
  Future<ApiResponse<bool>> markRead(int notificationId) async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(milliseconds: 300));
        return ApiResponse.success(true);
      } else {
        final Response response = await _client.post(
          '/api/v1/notifications/read',
          data: {'notification_id': notificationId},
        );
        if (response.statusCode == 200 && response.data?['status'] == true) {
          return ApiResponse.success(true);
        }
        return ApiResponse.failure(
          response.data?['message'] ?? 'Failed to mark notification read',
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }

  // ==========================================================
  // API_070 - Mark All Notifications Read
  // Endpoint: POST /api/v1/notifications/read-all
  // Backend Doc Ref: API_070
  // ==========================================================
  /// `POST /api/v1/notifications/read-all`.
  Future<ApiResponse<bool>> markAllRead() async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        return ApiResponse.success(true);
      } else {
        final Response response = await _client.post(
          '/api/v1/notifications/read-all',
          data: {},
        );
        if (response.statusCode == 200 && response.data?['status'] == true) {
          return ApiResponse.success(true);
        }
        return ApiResponse.failure(
          response.data?['message'] ?? 'Failed to mark all notifications read',
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }

  // ==========================================================
  // API_071 - Delete Notification
  // Endpoint: DELETE /api/v1/notifications/{id}
  // Backend Doc Ref: API_071
  // ==========================================================
  /// `DELETE /api/v1/notifications/{id}`.
  Future<ApiResponse<bool>> deleteNotification(int notificationId) async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(milliseconds: 400));
        return ApiResponse.success(true);
      } else {
        final Response response = await _client.delete(
          '/api/v1/notifications/$notificationId',
        );
        if (response.statusCode == 200 && response.data?['status'] == true) {
          return ApiResponse.success(true);
        }
        return ApiResponse.failure(
          response.data?['message'] ?? 'Failed to delete notification',
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }

  // ==========================================================
  // API_072 - Delete All Read Notifications
  // Endpoint: DELETE /api/v1/notifications/read
  // Backend Doc Ref: API_072
  // ==========================================================
  /// `DELETE /api/v1/notifications/read` -- "Delete All Read" overflow
  /// action.
  Future<ApiResponse<bool>> deleteAllRead() async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        return ApiResponse.success(true);
      } else {
        final Response response = await _client.delete(
          '/api/v1/notifications/read',
        );
        if (response.statusCode == 200 && response.data?['status'] == true) {
          return ApiResponse.success(true);
        }
        return ApiResponse.failure(
          response.data?['message'] ?? 'Failed to delete read notifications',
        );
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }
}
