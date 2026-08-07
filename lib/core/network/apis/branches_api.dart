import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../services/DataModels/branch_detail_model.dart';
import '../../services/DataModels/branch_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Branches API — list/detail/create/update.
///
/// Uses the shared [callApi] helper (mock/live branching +
/// `ApiResponse<T>` wrapping) exactly like `ProfileApi` /
/// `DashboardHeaderApi`, rather than `FirmsApi`'s older by-hand
/// try/catch shape — this is the current preferred pattern for new
/// API classes in this project.
///
/// [DioClient] only exposes `get`/`post` (no `put`), so create and
/// update both go through POST, matching how the rest of the app's
/// network layer is shaped today — update simply targets a
/// `/branches/{id}` path. This avoids introducing any change to the
/// shared networking layer for this feature.
class BranchesApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_021 - Fetch Branches
  // Endpoint: GET /branches
  // Backend Doc Ref: API_021
  // ==========================================================
  /// GET /branches
  Future<ApiResponse<List<BranchModel>>> fetchBranches() {
    return callApi<List<BranchModel>>(
      mockAsset: 'assets/mocks/branches_response.json',
      liveCall: () => _client.get('/branches'),
      parse: (data) => (data['branches'] as List)
          .map((e) => BranchModel.fromJson(e))
          .toList(),
      fallbackErrorMessage: "We couldn't load branches right now.",
    );
  }

  // ==========================================================
  // API_022 - Fetch Branch Detail
  // Endpoint: GET /branches/{branchId}/details
  // Backend Doc Ref: API_022
  // ==========================================================
  /// GET /branches/{branchId}/details
  Future<ApiResponse<BranchDetailResponse>> fetchBranchDetail(
    int branchId,
  ) {
    return callApi<BranchDetailResponse>(
      mockAsset: 'assets/mocks/branch_details_response.json',
      liveCall: () => _client.get('/branches/$branchId/details'),
      parse: (data) => BranchDetailResponse.fromJson(data),
      fallbackErrorMessage: "We couldn't load this branch's details.",
    );
  }

  // ==========================================================
  // API_023 - Create Branch
  // Endpoint: POST /branches
  // Backend Doc Ref: API_023
  // ==========================================================
  /// POST /branches — create a new branch.
  ///
  /// Previously this called `_client.post(...)` directly inside its own
  /// try/catch, bypassing [callApi] entirely. That meant it never went
  /// through the mock branch that every other API method in this app
  /// uses — with `Env.isMock` true (see `env.dart`) and no real backend
  /// behind `Env.appBaseUrl`, every save attempt made a real HTTP call
  /// to a host that doesn't exist. Dio surfaces that as a
  /// `DioException` that `ApiException.fromDioError` doesn't have a
  /// specific case for, so it falls through to its generic `default`
  /// branch: `"Unexpected error occurred"`. That is the literal source
  /// of the bug reported on Slide to Save/Update — not a validation or
  /// payload problem, but this method never being mock-aware in the
  /// first place. Routing it through [callApi] (same as
  /// `fetchBranches`/`fetchBranchDetail` above) fixes that at the root
  /// instead of masking it with a try/catch that just swallows the same
  /// failure more quietly.
  Future<ApiResponse<bool>> createBranch(
    Map<String, dynamic> payload, {
    File? logo,
  }) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/branch_save_response.json',
      liveCall: () async => _client.post(
        '/branches',
        data: await _buildRequestBody(payload, logo),
      ),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to create branch',
    );
  }

  // ==========================================================
  // API_024 - Update Branch
  // Endpoint: POST /branches/{branchId}
  // Backend Doc Ref: API_024
  // ==========================================================
  /// POST /branches/{branchId} — update an existing branch. Same root
  /// cause and same fix as [createBranch] above.
  Future<ApiResponse<bool>> updateBranch(
    int branchId,
    Map<String, dynamic> payload, {
    File? logo,
    bool removeLogo = false,
  }) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/branch_save_response.json',
      liveCall: () async => _client.post(
        '/branches/$branchId',
        data: await _buildRequestBody(payload, logo, removeLogo: removeLogo),
      ),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to update branch',
    );
  }

  /// Builds the live-call request body. Mirrors `FirmsApi.createFirm`'s
  /// `FormData.fromMap` + `MultipartFile.fromFile` approach for the
  /// logo (multipart is required to actually upload a file), but only
  /// switches to `FormData` when a logo is actually involved — a plain
  /// JSON map is sent otherwise, matching every other mutation
  /// endpoint's shape in this app. Non-string values (numbers,
  /// lists, nulls) are JSON-encoded per field so Dio's multipart
  /// encoder — which only accepts String/MultipartFile values — can
  /// carry them the same way once "photo/document + form data
  /// together" is at all needed.
  Future<dynamic> _buildRequestBody(
    Map<String, dynamic> payload,
    File? logo, {
    bool removeLogo = false,
  }) async {
    if (logo == null && !removeLogo) return payload;

    final fields = <String, dynamic>{};
    payload.forEach((key, value) {
      fields[key] = value is String ? value : jsonEncode(value);
    });
    if (removeLogo) fields['remove_logo'] = 'true';

    return FormData.fromMap({
      ...fields,
      if (logo != null) 'logo': await MultipartFile.fromFile(logo.path),
    });
  }
}
