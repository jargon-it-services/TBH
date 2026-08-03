import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';

import '../../core/network/apis/salary_rules_api.dart';
import '../../core/services/DataModels/salary_rule_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/validators/numeric_field_validators.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../core/widgets/slide_action_button.dart';

/// Create/Edit Salary Rule form.
///
/// Pass [existing] to edit an already-loaded rule (fields pre-filled,
/// Save calls `SalaryRulesApi.updateSalaryRule`); omit it to create a
/// new one (`SalaryRulesApi.createSalaryRule`). Structure and building
/// blocks mirror `AddEditServicePage` throughout: [AppTextField] for
/// text/number inputs, [SegmentedToggle] for Salary Type and Allow
/// Advance Recovery, and [SlideActionButton] for Save.
///
/// Salary Type still offers all three values (Fixed Salary, Service
/// Commission, Hybrid), but there's no Commission Type/Commission Value
/// configuration here at all — commission is already configured
/// per-Service (Customer Price / Commission Type / Commission Value, in
/// the Service module), so Salary Rule never duplicates it. The
/// "Salary Configuration" section (the Fixed Salary field) only shows
/// for Fixed Salary and Hybrid; Service Commission has nothing left to
/// configure here and shows nothing between Salary Type and Bonus.
///
/// Status is intentionally not shown as a field here, matching the
/// current app-wide convention also used by Service/Branch/Staff/
/// Expense: a new rule defaults to Active and Edit carries over the
/// existing status untouched — changing it is handled by the Mark
/// Active/Inactive action on Salary Rule Details, not this form.
class AddEditSalaryRulePage extends StatefulWidget {
  final SalaryRuleDetailResponse? existing;

  const AddEditSalaryRulePage({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<AddEditSalaryRulePage> createState() => _AddEditSalaryRulePageState();
}

class _AddEditSalaryRulePageState extends State<AddEditSalaryRulePage> {
  static const List<String> _salaryTypes = ['Fixed Salary', 'Service Commission', 'Hybrid'];
  static const List<String> _yesNo = ['Yes', 'No'];

  final _formKey = GlobalKey<FormState>();
  final SalaryRulesApi _api = SalaryRulesApi();

  late String _name = widget.existing?.name ?? '';
  late String _description = widget.existing?.description ?? '';
  late String _salaryType =
      widget.existing != null && widget.existing!.salaryType.isNotEmpty
          ? widget.existing!.salaryType
          : _salaryTypes.first;

  late String _fixedSalary = _numOrEmpty(widget.existing?.fixedSalary);

  late String _monthlyTarget = _numOrEmpty(widget.existing?.monthlyTarget, allowZero: true);
  late String _targetBonus = _numOrEmpty(widget.existing?.targetBonus, allowZero: true);

  late String _allowAdvanceRecovery =
      (widget.existing?.allowAdvanceRecovery ?? false) ? 'Yes' : 'No';
  late String _maxRecoveryPerMonth =
      _numOrEmpty(widget.existing?.maxRecoveryPerMonth, allowZero: true);

  // Not shown as a field in this form — see class doc comment.
  late String _status = widget.existing?.status ?? 'Active';

  bool _isSaving = false;

  /// Fixed Salary and Hybrid both need a Fixed Salary figure; Service
  /// Commission has nothing to configure here.
  bool get _showSalaryConfiguration => _salaryType == 'Fixed Salary' || _salaryType == 'Hybrid';

  static String _numOrEmpty(double? value, {bool allowZero = false}) {
    if (value == null) return '';
    if (value == 0 && !allowZero) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  double? _parse(String value) => double.tryParse(value.trim());

  bool _validateSelections() {
    if (_salaryType.isEmpty) {
      AppSnackbar.warning(context, 'Please select: salary type');
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

      final recoveryOn = _allowAdvanceRecovery == 'Yes';

      final payload = {
        'name': _name.trim(),
        'description': _description.trim(),
        'salary_type': _salaryType,
        'fixed_salary': _showSalaryConfiguration ? _parse(_fixedSalary) : null,
        'monthly_target': _parse(_monthlyTarget),
        'target_bonus': _parse(_targetBonus),
        'allow_advance_recovery': recoveryOn,
        'max_recovery_per_month': recoveryOn ? _parse(_maxRecoveryPerMonth) : null,
        'status': _status,
      };

      final response = widget.isEdit
          ? await _api.updateSalaryRule(widget.existing!.id, payload)
          : await _api.createSalaryRule(payload);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.isSuccess) {
        AppSnackbar.success(
          context,
          widget.isEdit ? 'Salary rule updated successfully' : 'Salary rule created successfully',
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
          widget.isEdit ? 'Edit Salary Rule' : 'Add New Salary Rule',
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
                  label: 'Salary Rule Name',
                  icon: Icons.rule_folder_outlined,
                  initialValue: _name,
                  onChanged: (v) => _name = v,
                  validator: (v) => NumericFieldValidators.required(v, 'Salary Rule Name'),
                ),
                AppTextField(
                  label: 'Description (optional)',
                  icon: Icons.notes_outlined,
                  initialValue: _description,
                  onChanged: (v) => _description = v,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Salary Type'),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
                  child: SegmentedToggle(
                    options: _salaryTypes,
                    value: _salaryType,
                    onChanged: (val) => setState(() => _salaryType = val),
                  ),
                ),
                // Salary Configuration (Fixed Salary) only shows for
                // Fixed Salary / Hybrid — Service Commission has
                // nothing to configure here, since commission lives on
                // the Service itself.
                if (_showSalaryConfiguration) ...[
                  const SizedBox(height: AppSpacing.verticalSmall),
                  _sectionTitle('Salary Configuration'),
                  AppTextField(
                    label: 'Fixed Salary (₹)',
                    icon: Icons.currency_rupee,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    initialValue: _fixedSalary,
                    onChanged: (v) => _fixedSalary = v,
                    validator: (v) => NumericFieldValidators.positiveNumber(v, 'Fixed Salary'),
                  ),
                ],
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Bonus'),
                AppTextField(
                  label: 'Monthly Target (₹, optional)',
                  icon: Icons.flag_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  initialValue: _monthlyTarget,
                  onChanged: (v) => _monthlyTarget = v,
                  validator: (v) => NumericFieldValidators.nonNegativeNumber(v, 'Monthly Target'),
                ),
                AppTextField(
                  label: 'Bonus (₹, optional)',
                  icon: Icons.card_giftcard_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  initialValue: _targetBonus,
                  onChanged: (v) => _targetBonus = v,
                  validator: (v) => NumericFieldValidators.nonNegativeNumber(v, 'Bonus'),
                ),
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Advance Recovery'),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
                  child: SegmentedToggle(
                    options: _yesNo,
                    value: _allowAdvanceRecovery,
                    onChanged: (val) => setState(() => _allowAdvanceRecovery = val),
                  ),
                ),
                if (_allowAdvanceRecovery == 'Yes')
                  AppTextField(
                    label: 'Maximum Recovery Per Month (₹, optional)',
                    icon: Icons.savings_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    initialValue: _maxRecoveryPerMonth,
                    onChanged: (v) => _maxRecoveryPerMonth = v,
                    validator: (v) => NumericFieldValidators.nonNegativeNumber(
                        v, 'Maximum Recovery Per Month'),
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
