import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../services/DataModels/firm_detail_model.dart';
import '../../services/DataModels/firm_model.dart';
import '../api_response.dart';
import '../dio_client.dart';
import '../env.dart';

class FirmsApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_018 - Create Firm
  // Endpoint: POST /create-firm
  // Backend Doc Ref: API_018
  // ==========================================================
  Future<ApiResponse<bool>> createFirm({
    required String firmName,
    required String address,
    required String gstin,
    required String regNo,
    required String ownerName,
    required String contact,
    required String email,
    required String companyType,
    required File firmLogo,
    required File firmPhoto,
  }) async {
    try {
      final formData = FormData.fromMap({
        "firm_name": firmName,
        "address": address,
        "gstin": gstin,
        "registration_number": regNo,
        "owner_name": ownerName,
        "contact": contact,
        "email": email,
        "company_type": companyType,
        "firm_logo": await MultipartFile.fromFile(firmLogo.path),
        "firm_photo": await MultipartFile.fromFile(firmPhoto.path),
      });

      final response = await _client.post(
        '/create-firm',
        data: formData,
      );

      if (response.statusCode == 200 && response.data['status'] == true) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.failure(response.data['message']);
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }

  // ==========================================================
  // API_019 - Fetch Firms
  // Endpoint: GET /firms
  // Backend Doc Ref: API_019
  // ==========================================================
  Future<ApiResponse<List<FirmModel>>> fetchFirms() async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(seconds: 2));

        final String response =
            await rootBundle.loadString('assets/mocks/firms_response.json');

        final Map<String, dynamic> jsonData = json.decode(response);

        final List<FirmModel> firms = (jsonData['data']['firms'] as List)
            .map((e) => FirmModel.fromJson(e))
            .toList();

        return ApiResponse.success(firms);
      } else {
        final Response response = await _client.get('/firms');

        if (response.statusCode == 200 && response.data['status'] == true) {
          final List<FirmModel> firms = (response.data['data']['firms'] as List)
              .map((e) => FirmModel.fromJson(e))
              .toList();

          return ApiResponse.success(firms);
        } else {
          return ApiResponse.failure('Failed to load firms');
        }
      }
    } catch (e) {
      return ApiResponse.failure(e);
    }
  }

  // ==========================================================
  // API_020 - Fetch Firm Detail
  // Endpoint: GET /firms/{firmId}/details
  // Backend Doc Ref: API_020
  // ==========================================================
  /// =======================
  /// FIRM DETAIL API ✅
  /// =======================
  Future<ApiResponse<FirmDetailResponse>> fetchFirmDetail(
    int firmId,
  ) async {
    try {
      if (Env.isMock) {
        await Future.delayed(const Duration(seconds: 2));

        final String response = await rootBundle
            .loadString('assets/mocks/firm_details_response.json');

        final Map<String, dynamic> jsonData = json.decode(response);

        final FirmDetailResponse detail =
            FirmDetailResponse.fromJson(jsonData['data']);

        return ApiResponse.success(detail);
      } else {
        final Response response = await _client.get('/firms/$firmId/details');

        if (response.statusCode == 200 && response.data['status'] == true) {
          final FirmDetailResponse detail =
              FirmDetailResponse.fromJson(response.data['data']);

          return ApiResponse.success(detail);
        } else {
          return ApiResponse.failure('Failed to load firm details');
        }
      }
    } catch (e) {
      return ApiResponse.failure(e.toString());
    }
  }
}
