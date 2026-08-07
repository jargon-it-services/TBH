import '../../services/DataModels/salary_rule_detail_model.dart';
import '../../services/DataModels/salary_rule_list_model.dart';
import '../../services/DataModels/salary_rule_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Salary Rules API — catalog (for the Staff form's picker) + full
/// Salary Rules Management (list/detail/create/update/delete).
///
/// The catalog method (`fetchSalaryRules`) previously existed alone,
/// added only so the Staff form could auto-fetch its Salary Rule
/// picker. The management endpoints are added here rather than in a
/// separate API class so every Salary-Rule-related network call still
/// lives in one place, same as `ServicesApi` owns both the Branch
/// picker's catalog and full Service Management. Uses the shared
/// [callApi] helper exactly like every other API class, so nothing new
/// is introduced architecturally.
///
/// [DioClient] only exposes `get`/`post` (no `put`/`delete`), so
/// create, update, and delete all go through POST, matching every
/// other mutation endpoint in the app.
class SalaryRulesApi {
  final DioClient _client = DioClient();

  // ==========================================================
  // API_038 - Fetch Salary Rules Catalog
  // Endpoint: GET /salary-rules
  // Backend Doc Ref: API_038
  // ==========================================================
  /// GET /salary-rules — the list a staff member's Salary Rule is
  /// picked from. Left untouched: still returns the lightweight
  /// [SalaryRuleModel] shape the Staff Create/Edit form relies on.
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

  // ==========================================================
  // API_039 - Fetch Salary Rule List
  // Endpoint: GET /salary-rules/list
  // Backend Doc Ref: API_039
  // ==========================================================
  /// GET /salary-rules/list — the full Salary Rule List screen's data.
  Future<ApiResponse<List<SalaryRuleListItem>>> fetchSalaryRuleList() {
    return callApi<List<SalaryRuleListItem>>(
      mockAsset: 'assets/mocks/salary_rule_list_response.json',
      liveCall: () => _client.get('/salary-rules/list'),
      parse: (data) => (data['salary_rules'] as List)
          .map((e) => SalaryRuleListItem.fromJson(e))
          .toList(),
      fallbackErrorMessage: "We couldn't load salary rules right now.",
    );
  }

  // ==========================================================
  // API_040 - Fetch Salary Rule Detail
  // Endpoint: GET /salary-rules/{ruleId}/details
  // Backend Doc Ref: API_040
  // ==========================================================
  /// GET /salary-rules/{ruleId}/details
  Future<ApiResponse<SalaryRuleDetailResponse>> fetchSalaryRuleDetail(int ruleId) {
    return callApi<SalaryRuleDetailResponse>(
      mockAsset: 'assets/mocks/salary_rule_detail_response.json',
      liveCall: () => _client.get('/salary-rules/$ruleId/details'),
      parse: (data) => SalaryRuleDetailResponse.fromJson(data),
      fallbackErrorMessage: "We couldn't load this salary rule's details.",
    );
  }

  // ==========================================================
  // API_041 - Create Salary Rule
  // Endpoint: POST /salary-rules
  // Backend Doc Ref: API_041
  // ==========================================================
  /// POST /salary-rules — create a new salary rule.
  Future<ApiResponse<bool>> createSalaryRule(Map<String, dynamic> payload) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/salary_rule_save_response.json',
      liveCall: () => _client.post('/salary-rules', data: payload),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to create salary rule',
    );
  }

  // ==========================================================
  // API_042 - Update Salary Rule
  // Endpoint: POST /salary-rules/{ruleId}
  // Backend Doc Ref: API_042
  // ==========================================================
  /// POST /salary-rules/{ruleId} — update an existing salary rule.
  Future<ApiResponse<bool>> updateSalaryRule(int ruleId, Map<String, dynamic> payload) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/salary_rule_save_response.json',
      liveCall: () => _client.post('/salary-rules/$ruleId', data: payload),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to update salary rule',
    );
  }

  // ==========================================================
  // API_043 - Delete Salary Rule
  // Endpoint: POST /salary-rules/{ruleId}/delete
  // Backend Doc Ref: API_043
  // ==========================================================
  /// POST /salary-rules/{ruleId}/delete
  Future<ApiResponse<bool>> deleteSalaryRule(int ruleId) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/salary_rule_delete_response.json',
      liveCall: () => _client.post('/salary-rules/$ruleId/delete'),
      parse: (data) => (data['deleted'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to delete salary rule',
    );
  }
}
