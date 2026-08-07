import 'package:dio/dio.dart';

import '../api_exceptions.dart';
import '../network_info.dart';

/// countriesnow.space — free, public, no API key required.
/// Docs: https://countriesnow.space/api/v0.1/countries/states
///
/// Kept separate from DioClient on purpose: DioClient is scoped to our
/// own backend (baseUrl + auth interceptor + token refresh), which would
/// be wrong for a public third-party API like this one. Connectivity is
/// still checked up front the same way DioClient does it, so a user with
/// no signal gets an immediate "No internet connection" instead of
/// waiting out the full request timeout.
class LocationApi {
  final NetworkInfo _networkInfo = NetworkInfo();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://countriesnow.space/api/v0.1',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<void> _ensureConnected() async {
    if (!await _networkInfo.isConnected) {
      throw ApiException("No internet connection");
    }
  }

  // ==========================================================
  // API_073 - Fetch Indian States (3rd-Party)
  // Endpoint: POST https://countriesnow.space/api/v0.1/countries/states
  // Backend Doc Ref: API_073
  // ==========================================================
  Future<List<String>> fetchIndianStates() async {
    await _ensureConnected();
    try {
      final response = await _dio.post(
        '/countries/states',
        data: {'country': 'India'},
      );

      if (response.data['error'] == false) {
        final states = (response.data['data']['states'] as List)
            .map((e) => e['name'] as String)
            .toList();
        states.sort();
        return states;
      }
      throw ApiException('Could not load states');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ==========================================================
  // API_074 - Fetch Cities For State (3rd-Party)
  // Endpoint: POST https://countriesnow.space/api/v0.1/countries/state/cities
  // Backend Doc Ref: API_074
  // ==========================================================
  Future<List<String>> fetchCitiesForState(String state) async {
    await _ensureConnected();
    try {
      final response = await _dio.post(
        'https://countriesnow.space/api/v0.1/countries/state/cities',
        data: {'country': 'India', 'state': state},
      );

      if (response.data['error'] == false) {
        final cities =
            (response.data['data'] as List).map((e) => e.toString()).toList();
        cities.sort();
        return cities;
      }
      throw ApiException('Could not load cities');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
