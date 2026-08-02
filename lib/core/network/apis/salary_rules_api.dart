import '../../services/DataModels/salary_rule_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Salary Rules API.
///
/// Only the read side needed to populate the Staff form's Salary Rule
/// picker exists here — same scope-limiting choice the pre-existing
/// `ServicesApi.fetchServices()` catalog method made for the Branch
/// form's service picker. Follows the exact same [callApi] pattern as
/// every other API class, so nothing new is introduced architecturally.
class SalaryRulesApi {
  final DioClient _client = DioClient();

  /// GET /salary-rules — the list a staff member's Salary Rule is
  /// picked from.
  Future<ApiResponse<List<SalaryRuleModel>>> fetchSalaryRules() {
    return callApi<List<SalaryRuleModel>>(
      mockAsset: 'assets/mocks/salary_rules_response.json',
      liveCall: () => _client.get('/salary-rules'),
      parse: (data) => (data['salary_rules'] as List)
          .map((e) => SalaryRuleModel.fromJson(e))
          .toList(),
      fallbackErrorMessage: "We couldn't load salary rules right now.",
    );
  }
}
