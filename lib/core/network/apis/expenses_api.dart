import '../../services/DataModels/expense_detail_model.dart';
import '../../services/DataModels/expense_list_model.dart';
import '../api_call_helper.dart';
import '../api_response.dart';
import '../dio_client.dart';

/// Expenses (Types) Management API — list/detail/create/update/delete.
/// Follows the exact same [callApi]/[DioClient] pattern as
/// `ServicesApi`/`StaffApi`, so nothing new is introduced
/// architecturally.
///
/// Expenses is a configuration screen (Name, Description, Branch
/// Assignment only) — no file upload is involved, so unlike
/// `ServicesApi`/`StaffApi` this sends a plain JSON payload directly
/// rather than needing a `FormData` branch.
///
/// [DioClient] only exposes `get`/`post` (no `put`/`delete`), so
/// create, update, and delete all go through POST, matching every
/// other mutation endpoint in the app.
class ExpensesApi {
  final DioClient _client = DioClient();

  /// GET /expenses/list
  Future<ApiResponse<List<ExpenseListItem>>> fetchExpenseList() {
    return callApi<List<ExpenseListItem>>(
      mockAsset: 'assets/mocks/expense_list_response.json',
      liveCall: () => _client.get('/expenses/list'),
      parse: (data) => (data['expenses'] as List)
          .map((e) => ExpenseListItem.fromJson(e))
          .toList(),
      fallbackErrorMessage: "We couldn't load expenses right now.",
    );
  }

  /// GET /expenses/{expenseId}/details
  Future<ApiResponse<ExpenseDetailResponse>> fetchExpenseDetail(int expenseId) {
    return callApi<ExpenseDetailResponse>(
      mockAsset: 'assets/mocks/expense_detail_response.json',
      liveCall: () => _client.get('/expenses/$expenseId/details'),
      parse: (data) => ExpenseDetailResponse.fromJson(data),
      fallbackErrorMessage: "We couldn't load this expense's details.",
    );
  }

  /// POST /expenses — create a new expense type.
  Future<ApiResponse<bool>> createExpense(Map<String, dynamic> payload) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/expense_save_response.json',
      liveCall: () => _client.post('/expenses', data: payload),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to add expense',
    );
  }

  /// POST /expenses/{expenseId} — update an existing expense type.
  Future<ApiResponse<bool>> updateExpense(int expenseId, Map<String, dynamic> payload) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/expense_save_response.json',
      liveCall: () => _client.post('/expenses/$expenseId', data: payload),
      parse: (data) => (data['saved'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to update expense',
    );
  }

  /// POST /expenses/{expenseId}/delete
  Future<ApiResponse<bool>> deleteExpense(int expenseId) {
    return callApi<bool>(
      mockAsset: 'assets/mocks/expense_delete_response.json',
      liveCall: () => _client.post('/expenses/$expenseId/delete'),
      parse: (data) => (data['deleted'] as bool?) ?? true,
      fallbackErrorMessage: 'Failed to delete expense',
    );
  }
}
