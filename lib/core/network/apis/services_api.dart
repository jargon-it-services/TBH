import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../services/DataModels/service_detail_model.dart';
import '../../services/DataModels/service_list_model.dart';
import '../../services/DataModels/service_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Services API — catalog (for the Branch picker) + full Service
/// Management (list/detail/create/update/delete).
///
/// `lib/features/services/` previously existed as an empty placeholder
/// feature folder with only the catalog method below. The management
/// endpoints are added here rather than in a separate API class so
/// every Services-related network call still lives in one place, same
/// as `BranchesApi` owns everything Branch-related. Uses the shared
/// [callApi] helper (mock/live branching + `ApiResponse<T>` wrapping)
/// exactly like `BranchesApi`, so nothing new is introduced
/// architecturally.
///
/// [DioClient] only exposes `get`/`post` (no `put`/`delete`), so
/// create, update, and delete all go through POST, matching
/// `BranchesApi.updateBranch`'s identical approach.
class ServicesApi {
  final DioClient _client = DioClient();

  /// GET /services — the master catalog a branch's services are picked
  /// from. Left untouched: still returns the lightweight [ServiceModel]
  /// shape the Branch Create/Edit form relies on.
  Future<ApiResponse<List<ServiceModel>>> fetchServices() {
    return callApi<List<ServiceModel>>(
      mockAsset: 'assets/mocks/services_response.json',
      liveCall: () => _client.get('/services'),
      parse: (data) => (data['services'] as List)
          .map((e) => ServiceModel.fromJson(e))
          .toList(),
      fallbackErrorMessage: "We couldn't load services right now.",
    );
  }

  /// GET /services/list — the full Service List screen's data (richer
  /// than the catalog above: category, pricing, status, photo, etc).
  /// Kept as a separate endpoint/parse from [fetchServices] so the
  /// Branch picker's existing behavior/shape can never be affected by
  /// Service Management changes.
  Future<ApiResponse<List<ServiceListItem>>> fetchServiceList() {
    return callApi<List<ServiceListItem>>(
      mockAsset: 'assets/mocks/service_list_response.json',
      liveCall: () => _client.get('/services/list'),
      parse: (data) => (data['services'] as List)
          .map((e) => ServiceListItem.fromJson(e))
          .toList(),
      fallbackErrorMessage: "We couldn't load services right now.",
    );
  }

  /// GET /services/{serviceId}/details
  Future<ApiResponse<ServiceDetailResponse>> fetchServiceDetail(
    int serviceId,
  ) {
    return callApi<ServiceDetailResponse>(
      mockAsset: 'assets/mocks/service_detail_response.json',
      liveCall: () => _client.get('/services/$serviceId/details'),
      parse: (data) => ServiceDetailResponse.fromJson(data),
      fallbackErrorMessage: "We couldn't load this service's details.",
    );
  }

  /// POST /services — create a new service.
  Future<ApiResponse<bool>> createService(
    Map<String, dynamic> payload, {
    File? photo,
  }) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/service_save_response.json',
      liveCall: () async => _client.post(
        '/services',
        data: await _buildRequestBody(payload, photo),
      ),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to create service',
    );
  }

  /// POST /services/{serviceId} — update an existing service.
  Future<ApiResponse<bool>> updateService(
    int serviceId,
    Map<String, dynamic> payload, {
    File? photo,
    bool removePhoto = false,
  }) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/service_save_response.json',
      liveCall: () async => _client.post(
        '/services/$serviceId',
        data: await _buildRequestBody(payload, photo, removePhoto: removePhoto),
      ),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to update service',
    );
  }

  /// POST /services/{serviceId}/delete
  Future<ApiResponse<bool>> deleteService(int serviceId) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/service_delete_response.json',
      liveCall: () => _client.post('/services/$serviceId/delete'),
      parse: (data) => (data['deleted'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to delete service',
    );
  }

  /// Builds the live-call request body. Mirrors
  /// `BranchesApi._buildRequestBody`'s `FormData.fromMap` +
  /// `MultipartFile.fromFile` approach for the photo — only switches to
  /// `FormData` when a photo is actually involved, a plain JSON map is
  /// sent otherwise, matching every other mutation endpoint's shape.
  Future<dynamic> _buildRequestBody(
    Map<String, dynamic> payload,
    File? photo, {
    bool removePhoto = false,
  }) async {
    if (photo == null && !removePhoto) return payload;

    final fields = <String, dynamic>{};
    payload.forEach((key, value) {
      fields[key] = value is String ? value : jsonEncode(value);
    });
    if (removePhoto) fields['remove_photo'] = 'true';

    return FormData.fromMap({
      ...fields,
      if (photo != null) 'photo': await MultipartFile.fromFile(photo.path),
    });
  }
}
