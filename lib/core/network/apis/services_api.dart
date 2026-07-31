import '../../services/DataModels/service_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Services catalog API.
///
/// `lib/features/services/` exists as an empty placeholder feature
/// folder and no Services API previously existed anywhere in
/// `core/network/apis/` — this is a net-new addition, added only
/// because the Branch Create/Edit form must auto-fetch the services
/// list rather than let the user type them in manually. It follows the
/// exact same [callApi] pattern as every other API class here, so nothing
/// new is introduced architecturally.
class ServicesApi {
  final DioClient _client = DioClient();

  /// GET /services — the master catalog a branch's services are picked
  /// from.
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
}
