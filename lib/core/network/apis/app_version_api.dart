import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Response payload for the backend-driven version check.
///
/// `minimumBuild`/`latestBuild`/`storeUrl` are only meaningful when
/// [maintenance] is false — the backend contract mirrors the shape
/// described in the version-management spec this was built against.
class AppVersionResult {
  final bool maintenance;
  final String? message;
  final int? minimumBuild;
  final int? latestBuild;
  final String? storeUrl;

  AppVersionResult({
    required this.maintenance,
    this.message,
    this.minimumBuild,
    this.latestBuild,
    this.storeUrl,
  });

  factory AppVersionResult.fromJson(Map<String, dynamic> json) {
    return AppVersionResult(
      maintenance: json['maintenance'] == true,
      message: json['message'],
      minimumBuild: (json['minimum_build'] as num?)?.toInt(),
      latestBuild: (json['latest_build'] as num?)?.toInt(),
      storeUrl: json['store_url'],
    );
  }
}

/// App Version API — uses the shared [callApi] helper (mock/live
/// branching + ApiResponse<T> wrapping) so the rest of the app doesn't
/// need a new pattern. Same structure as LoginApi/RefreshTokenApi.
///
/// BACKEND CONTRACT:
///
///   GET /app/version
///   200 response:  { "status": true, "data": {
///                      "maintenance": false,
///                      "minimum_build": 120,
///                      "latest_build": 125,
///                      "store_url": "https://...",
///                      "message": "Please update the application."
///                    } }
///
/// Wrapped in the same `{status, data}` envelope every other endpoint
/// in this app uses (see login_response.json, refresh_token_response.json,
/// etc.) rather than a bare object, so this doesn't need a special-cased
/// parsing path in `callApi`.
///
/// To exercise each gate locally in mock mode (Env.isMock == true), edit
/// assets/mocks/app_version_response.json:
///   - Maintenance:      data.maintenance = true
///   - Force update:     data.minimum_build higher than the app's real
///                       build number (see AppBuildInfo)
///   - Optional update:  data.minimum_build low, data.latest_build
///                       higher than the app's real build number
///   - Up to date:       default — both set to 1, so any real build
///                       number satisfies the check
class AppVersionApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_009 - Check App Version
  // Endpoint: GET /app/version
  // Backend Doc Ref: API_009
  // ==========================================================
  Future<ApiResponse<AppVersionResult>> checkVersion() {
    return callApi<AppVersionResult>(
      mockAsset: 'assets/mocks/app_version_response.json',
      mockDelay: const Duration(milliseconds: 500),
      liveCall: () => _client.get('/app/version'),
      parse: AppVersionResult.fromJson,
      fallbackErrorMessage: 'Could not check app version',
    );
  }
}
