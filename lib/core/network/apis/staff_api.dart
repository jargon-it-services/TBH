import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../services/DataModels/staff_detail_model.dart';
import '../../services/DataModels/staff_list_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Staff Management API — list/detail/create/update/delete, plus a
/// best-effort employee-code suggestion. Follows the exact same
/// [callApi]/[DioClient] pattern as `ServicesApi`/`BranchesApi`, so
/// nothing new is introduced architecturally.
///
/// [DioClient] only exposes `get`/`post` (no `put`/`delete`), so
/// create, update, and delete all go through POST, matching every
/// other mutation endpoint in the app.
class StaffApi {
  final DioClient _client = DioClient();

  /// GET /staff/list
  Future<ApiResponse<List<StaffListItem>>> fetchStaffList() {
    return callApi<List<StaffListItem>>(
      mockAsset: 'assets/mocks/staff_list_response.json',
      liveCall: () => _client.get('/staff/list'),
      parse: (data) => (data['staff'] as List)
          .map((e) => StaffListItem.fromJson(e))
          .toList(),
      fallbackErrorMessage: "We couldn't load staff right now.",
    );
  }

  /// GET /staff/{staffId}/details
  Future<ApiResponse<StaffDetailResponse>> fetchStaffDetail(int staffId) {
    return callApi<StaffDetailResponse>(
      mockAsset: 'assets/mocks/staff_detail_response.json',
      liveCall: () => _client.get('/staff/$staffId/details'),
      parse: (data) => StaffDetailResponse.fromJson(data),
      fallbackErrorMessage: "We couldn't load this staff member's details.",
    );
  }

  /// GET /staff/next-employee-code — a backend-suggested Employee Code
  /// for a brand-new staff member. Per the spec ("Auto-generate if
  /// supported by backend. Otherwise allow manual entry."), the Add
  /// Staff form treats an empty/failed response as "not supported" and
  /// simply leaves Employee Code blank and editable — it never blocks
  /// on this call.
  Future<ApiResponse<String>> fetchNextEmployeeCode() {
    return callApi<String>(
      mockAsset: 'assets/mocks/staff_next_employee_code_response.json',
      liveCall: () => _client.get('/staff/next-employee-code'),
      parse: (data) => (data['employee_code'] as String?) ?? '',
      fallbackErrorMessage: '',
    );
  }

  /// POST /staff — create a new staff member.
  Future<ApiResponse<bool>> createStaff(
    Map<String, dynamic> payload, {
    File? photo,
    File? aadhaarCard,
  }) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/staff_save_response.json',
      liveCall: () async => _client.post(
        '/staff',
        data: await _buildRequestBody(payload, photo, aadhaarCard),
      ),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to add staff member',
    );
  }

  /// POST /staff/{staffId} — update an existing staff member.
  Future<ApiResponse<bool>> updateStaff(
    int staffId,
    Map<String, dynamic> payload, {
    File? photo,
    File? aadhaarCard,
    bool removePhoto = false,
    bool removeAadhaarCard = false,
  }) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/staff_save_response.json',
      liveCall: () async => _client.post(
        '/staff/$staffId',
        data: await _buildRequestBody(
          payload,
          photo,
          aadhaarCard,
          removePhoto: removePhoto,
          removeAadhaarCard: removeAadhaarCard,
        ),
      ),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to update staff member',
    );
  }

  /// POST /staff/{staffId}/delete
  Future<ApiResponse<bool>> deleteStaff(int staffId) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/staff_delete_response.json',
      liveCall: () => _client.post('/staff/$staffId/delete'),
      parse: (data) => (data['deleted'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to delete staff member',
    );
  }

  /// Builds the live-call request body — mirrors
  /// `ServicesApi._buildRequestBody`'s approach, extended for two
  /// optional files (Profile Photo, Aadhaar Card) instead of one.
  Future<dynamic> _buildRequestBody(
    Map<String, dynamic> payload,
    File? photo,
    File? aadhaarCard, {
    bool removePhoto = false,
    bool removeAadhaarCard = false,
  }) async {
    if (photo == null &&
        aadhaarCard == null &&
        !removePhoto &&
        !removeAadhaarCard) {
      return payload;
    }

    final fields = <String, dynamic>{};
    payload.forEach((key, value) {
      fields[key] = value is String ? value : jsonEncode(value);
    });
    if (removePhoto) fields['remove_photo'] = 'true';
    if (removeAadhaarCard) fields['remove_aadhaar_card'] = 'true';

    return FormData.fromMap({
      ...fields,
      if (photo != null) 'photo': await MultipartFile.fromFile(photo.path),
      if (aadhaarCard != null)
        'aadhaar_card': await MultipartFile.fromFile(aadhaarCard.path),
    });
  }
}
