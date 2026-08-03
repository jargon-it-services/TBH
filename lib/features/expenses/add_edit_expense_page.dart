import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';

import '../../core/network/apis/branches_api.dart';
import '../../core/network/apis/expenses_api.dart';
import '../../core/services/DataModels/branch_model.dart';
import '../../core/services/DataModels/expense_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/validators/numeric_field_validators.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/multi_select_field.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../core/widgets/slide_action_button.dart';

/// Create/Edit Expense (type) form.
///
/// Expenses is a configuration screen — it defines expense *types*
/// (and which branch(es) each applies to), not individual transactions.
/// Only three fields: Name, Description, and Branch Assignment.
///
/// Pass [existing] to edit an already-loaded expense type (fields
/// pre-filled, Save calls `ExpensesApi.updateExpense`); omit it to
/// create a new one (`ExpensesApi.createExpense`). Branch Assignment
/// reuses the exact same All Branches / Selected Branches
/// [SegmentedToggle] + [MultiSelectField] pattern built for Service's
/// Branch Assignment — same widgets, same mutual-exclusivity rule
/// (can't pick both).
///
/// Status is intentionally not shown as a field here, matching the
/// current app-wide convention also used by Service/Branch/Staff: a
/// new expense type defaults to Active and Edit carries over the
/// existing status untouched — changing it is handled by the Mark
/// Active/Inactive action on Expense Details, not this form.
class AddEditExpensePage extends StatefulWidget {
  final ExpenseDetailResponse? existing;

  const AddEditExpensePage({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<AddEditExpensePage> createState() => _AddEditExpensePageState();
}

class _AddEditExpensePageState extends State<AddEditExpensePage> {
  static const List<String> _branchScopeOptions = ['All Branches', 'Selected Branches'];

  final _formKey = GlobalKey<FormState>();
  final ExpensesApi _expensesApi = ExpensesApi();
  final BranchesApi _branchesApi = BranchesApi();

  late String _name = widget.existing?.name ?? '';
  late String _description = widget.existing?.description ?? '';

  late String _branchScope =
      (widget.existing?.allBranches ?? true) ? 'All Branches' : 'Selected Branches';
  late Set<int> _selectedBranchIds =
      (widget.existing?.branches ?? []).map((b) => b.id).toSet();
  List<BranchModel> _allBranchOptions = [];
  bool _loadingBranches = true;

  // Not shown as a field in this form — see class doc comment.
  late String _status = widget.existing?.status ?? 'Active';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBranchOptions();
  }

  Future<void> _loadBranchOptions() async {
    final response = await _branchesApi.fetchBranches();
    if (!mounted) return;
    setState(() {
      _allBranchOptions = response.data ?? [];
      _loadingBranches = false;
    });
  }

  bool _validateSelections() {
    if (_branchScope == 'Selected Branches' && _selectedBranchIds.isEmpty) {
      AppSnackbar.warning(context, 'Please select: at least one branch');
      return false;
    }
    return true;
  }

  Future<void> _save(ActionSliderController controller) async {
    if (_isSaving) return;

    try {
      if (!(_formKey.currentState?.validate() ?? false)) {
        AppSnackbar.warning(context, 'Please fix the highlighted fields');
        return;
      }
      if (!_validateSelections()) return;

      if (!mounted) return;
      setState(() => _isSaving = true);

      final payload = {
        'name': _name.trim(),
        'description': _description.trim(),
        'all_branches': _branchScope == 'All Branches',
        'branch_ids': _branchScope == 'All Branches' ? [] : _selectedBranchIds.toList(),
        'status': _status,
      };

      final response = widget.isEdit
          ? await _expensesApi.updateExpense(widget.existing!.id, payload)
          : await _expensesApi.createExpense(payload);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.isSuccess) {
        AppSnackbar.success(
          context,
          widget.isEdit ? 'Expense updated successfully' : 'Expense added successfully',
        );
        Navigator.pop(context, true);
      } else {
        AppSnackbar.error(context, response.error ?? 'Something went wrong. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(context, "Something went wrong while saving. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Edit Expense' : 'Add New Expense',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sectionTitle('Basic Information'),
                AppTextField(
                  label: 'Expense Name',
                  icon: Icons.receipt_long_outlined,
                  initialValue: _name,
                  onChanged: (v) => _name = v,
                  validator: (v) => NumericFieldValidators.required(v, 'Expense Name'),
                ),
                AppTextField(
                  label: 'Description (optional)',
                  icon: Icons.notes_outlined,
                  initialValue: _description,
                  onChanged: (v) => _description = v,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Branch Assignment'),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
                  child: SegmentedToggle(
                    options: _branchScopeOptions,
                    value: _branchScope,
                    onChanged: (val) => setState(() => _branchScope = val),
                  ),
                ),
                if (_branchScope == 'Selected Branches')
                  _loadingBranches
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
                          child: MultiSelectField(
                            label: 'Selected Branches',
                            icon: Icons.store_mall_directory_outlined,
                            options: _allBranchOptions
                                .map((b) => MultiSelectOption(id: b.id, label: b.name))
                                .toList(),
                            selectedIds: _selectedBranchIds,
                            onChanged: (ids) => setState(() => _selectedBranchIds = ids),
                            emptyHint: 'Tap to select branches',
                          ),
                        ),
                const SizedBox(height: AppSpacing.verticalLarge),
                SlideActionButton(
                  label: widget.isEdit ? 'Slide to Update' : 'Slide to Save',
                  submitting: _isSaving,
                  onSlide: _save,
                ),
                const SizedBox(height: AppSpacing.verticalMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: Text(
        text,
        style: AppTextStyles.h3.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}
