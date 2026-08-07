import 'package:dio/dio.dart';

import '../network_info.dart';

/// Result of a pincode lookup — carries the City/State the API found
/// so the caller can show a confirmation dialog before applying them,
/// plus a distinct `isOffline` flag so the UI doesn't wrongly tell the
/// user their postal code is invalid when it's actually a connectivity
/// problem.
class PincodeLookupResult {
  final bool isValid;
  final bool isOffline;
  final String? city;
  final String? state;

  PincodeLookupResult({
    required this.isValid,
    this.isOffline = false,
    this.city,
    this.state,
  });
}

/// api.postalpincode.in — free, public, no API key required, India only.
/// Docs: https://api.postalpincode.in
class PincodeApi {
  final NetworkInfo _networkInfo = NetworkInfo();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.postalpincode.in',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // ==========================================================
  // API_075 - Verify Pincode (3rd-Party)
  // Endpoint: GET https://api.postalpincode.in/pincode/{pincode}
  // Backend Doc Ref: API_075
  // ==========================================================
  Future<PincodeLookupResult> verify(String pincode) async {
    if (!await _networkInfo.isConnected) {
      return PincodeLookupResult(isValid: false, isOffline: true);
    }

    try {
      final response = await _dio.get('/pincode/$pincode');
      final List data = response.data as List;
      if (data.isEmpty) return PincodeLookupResult(isValid: false);

      final entry = data.first;
      if (entry['Status'] != 'Success' || entry['PostOffice'] == null) {
        return PincodeLookupResult(isValid: false);
      }

      final postOffices = entry['PostOffice'] as List;
      if (postOffices.isEmpty) return PincodeLookupResult(isValid: false);

      final first = postOffices.first;
      return PincodeLookupResult(
        isValid: true,
        city: first['District'] as String?,
        state: first['State'] as String?,
      );
    } catch (_) {
      return PincodeLookupResult(isValid: false);
    }
  }
}
