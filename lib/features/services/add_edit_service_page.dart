import 'dart:io';

import 'package:action_slider/action_slider.dart';
import 'package:flutter/material.dart';

import '../../core/network/apis/branches_api.dart';
import '../../core/network/apis/services_api.dart';
import '../../core/services/DataModels/branch_model.dart';
import '../../core/services/DataModels/service_detail_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/jargon_dropdown.dart';
import '../../core/widgets/logo_picker_field.dart';
import '../../core/widgets/multi_select_field.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../core/widgets/slide_action_button.dart';
import 'service_validators.dart';

/// Create/Edit Service form.
///
/// Pass [existing] to edit an already-loaded service (fields
/// pre-filled, Save calls `ServicesApi.updateService`); omit it to
/// create a new one (`ServicesApi.createService`). Structure and
/// building blocks mirror `AddEditBranchPage` throughout: [AppTextField]
/// for text/number inputs, [SegmentedToggle] for every binary/small
/// choice (Applicable Gender, Status, Home Service Available, Commission
/// Type — this is the app's existing Active/Inactive-style toggle,
/// reused rather than reinvented), [JargonDropdown] for Category (five
/// options — a row-of-pills toggle would be cramped), [LogoPickerField]
/// for the Service Photo, [MultiSelectField] for Branch Assignment, and
/// [SlideActionButton] for Save, per the Service Management spec.
class AddEditServicePage extends StatefulWidget {
  final ServiceDetailResponse? existing;

  const AddEditServicePage({super.key, this.existing});

  bool get isEdit => existing != null;

  @override
  State<AddEditServicePage> createState() => _AddEditServicePageState();
}

class _AddEditServicePageState extends State<AddEditServicePage> {
  static const List<String> _categories = [
    'Hair',
    'Facial',
    'Nail',
    'Spa',
    'Makeup',
  ];
  static const List<String> _genders = ['Male', 'Female', 'Unisex'];
  static const List<String> _homeServiceOptions = ['Yes', 'No'];
  static const List<String> _commissionTypes = ['Fixed Amount', 'Percentage'];
  static const List<String> _branchScopeOptions = [
    'All Branches',
    'Selected Branches',
  ];

  final _formKey = GlobalKey<FormState>();
  final ServicesApi _servicesApi = ServicesApi();
  final BranchesApi _branchesApi = BranchesApi();

  // ------------- Basic Information -------------
  late String _name = widget.existing?.name ?? '';
  late String _description = widget.existing?.description ?? '';
  late String _category =
      widget.existing != null && widget.existing!.category.isNotEmpty
          ? widget.existing!.category
          : _categories.first;
  late String _durationMinutes =
      widget.existing != null && widget.existing!.durationMinutes > 0
          ? widget.existing!.durationMinutes.toString()
          : '';
  late String _applicableGender = widget.existing?.applicableGender ?? 'Unisex';

  // Not shown as a field in this form — a separate Mark
  // Active/Inactive action on Service Details handles status changes.
  // Defaults to Active for a brand-new service; Edit Service carries
  // over whatever status the service already has, untouched.
  late String _status;

  // ------------- Photo -------------
  File? _pickedPhoto;
  bool _photoRemoved = false;

  // ------------- Pricing -------------
  late String _customerPrice = _numOrEmpty(widget.existing?.customerPrice);
  late String _materialCost = _numOrEmpty(widget.existing?.materialCost, allowZero: true);
  late String _commissionType =
      widget.existing?.commissionType ?? _commissionTypes.first;
  late String _commissionValue =
      _numOrEmpty(widget.existing?.commissionValue, allowZero: true);
  late String _otherCost = _numOrEmpty(widget.existing?.otherCost, allowZero: true);

  // ------------- Home Service -------------
  late String _homeServiceAvailable =
      (widget.existing?.homeServiceAvailable ?? false) ? 'Yes' : 'No';
  late String _homeVisitCharges = _numOrEmpty(widget.existing?.homeVisitCharges);
  late String _serviceRadiusKm = _numOrEmpty(widget.existing?.serviceRadiusKm);
  late String _extraChargePerKm = _numOrEmpty(widget.existing?.extraChargePerKm);

  // ------------- Branch Assignment -------------
  late String _branchScope =
      (widget.existing?.allBranches ?? true) ? 'All Branches' : 'Selected Branches';
  late Set<int> _selectedBranchIds =
      (widget.existing?.branches ?? []).map((b) => b.id).toSet();
  List<BranchModel> _allBranchOptions = [];
  bool _loadingBranches = true;

  bool _isSaving = false;

  static String _numOrEmpty(double? value, {bool allowZero = false}) {
    if (value == null) return '';
    if (value == 0 && !allowZero) return '';
    // Avoids "20.0" showing up in a numeric text field for whole values.
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  @override
  void initState() {
    super.initState();
    _status = widget.existing?.status ?? 'Active';
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

  double? _parse(String value) => double.tryParse(value.trim());

  /// Live profit preview, recalculated from whatever is currently typed
  /// in the pricing fields — matches the spec's "Whenever any pricing
  /// field changes, Profit should update immediately."
  double get _liveProfit {
    final price = _parse(_customerPrice) ?? 0;
    final material = _parse(_materialCost) ?? 0;
    final commissionValue = _parse(_commissionValue) ?? 0;
    final other = _parse(_otherCost) ?? 0;
    final commission = _commissionType == 'Percentage'
        ? price * (commissionValue / 100)
        : commissionValue;
    return price - material - commission - other;
  }

  /// Validates the non-TextFormField selections (dropdowns, toggles,
  /// branch assignment) that live outside the [Form] — same approach
  /// `AddEditBranchPage._validateSelections` uses.
  bool _validateSelections() {
    final errors = <String>[];
    if (_category.isEmpty) errors.add('category');
    if (_applicableGender.isEmpty) errors.add('applicable gender');
    if (_commissionType.isEmpty) errors.add('commission type');

    if (_homeServiceAvailable == 'Yes') {
      if (_parse(_homeVisitCharges) == null) errors.add('home visit charges');
      if (_parse(_serviceRadiusKm) == null) errors.add('service radius');
      if (_parse(_extraChargePerKm) == null) errors.add('extra charge per km');
    }

    if (_branchScope == 'Selected Branches' && _selectedBranchIds.isEmpty) {
      errors.add('at least one branch');
    }

    if (errors.isNotEmpty) {
      AppSnackbar.warning(context, 'Please select: ${errors.join(', ')}');
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

      final homeServiceOn = _homeServiceAvailable == 'Yes';

      final payload = {
        'name': _name.trim(),
        'description': _description.trim(),
        'category': _category,
        'duration_minutes': int.tryParse(_durationMinutes.trim()) ?? 0,
        'applicable_gender': _applicableGender,
        'type': 'Service',
        'status': _status,
        'customer_price': _parse(_customerPrice) ?? 0,
        'material_cost': _parse(_materialCost) ?? 0,
        'commission_type': _commissionType,
        'commission_value': _parse(_commissionValue) ?? 0,
        'other_cost': _parse(_otherCost) ?? 0,
        'home_service_available': homeServiceOn,
        'home_visit_charges': homeServiceOn ? _parse(_homeVisitCharges) : null,
        'service_radius_km': homeServiceOn ? _parse(_serviceRadiusKm) : null,
        'extra_charge_per_km': homeServiceOn ? _parse(_extraChargePerKm) : null,
        'all_branches': _branchScope == 'All Branches',
        'branch_ids': _branchScope == 'All Branches'
            ? []
            : _selectedBranchIds.toList(),
      };

      final response = widget.isEdit
          ? await _servicesApi.updateService(
              widget.existing!.id,
              payload,
              photo: _pickedPhoto,
              removePhoto: _photoRemoved,
            )
          : await _servicesApi.createService(payload, photo: _pickedPhoto);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (response.isSuccess) {
        AppSnackbar.success(
          context,
          widget.isEdit
              ? 'Service updated successfully'
              : 'Service created successfully',
        );
        Navigator.pop(context, true);
      } else {
        // Covers both API failures (server said no) and network
        // failures (offline/timeout) — same handling as
        // AddEditBranchPage._save.
        AppSnackbar.error(
          context,
          response.error ?? 'Something went wrong. Please try again.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(
        context,
        "Something went wrong while saving. Please try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Edit Service' : 'Add New Service',
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
                _sectionTitle('Service Photo'),
                LogoPickerField(
                  title: 'Service Photo',
                  existingUrl: widget.existing?.photo,
                  pickedFile: _pickedPhoto,
                  removed: _photoRemoved,
                  allowRemove: widget.isEdit,
                  onPicked: (file) => setState(() {
                    _pickedPhoto = file;
                    _photoRemoved = false;
                  }),
                  onRemoved: () => setState(() {
                    _pickedPhoto = null;
                    _photoRemoved = true;
                  }),
                ),
                const SizedBox(height: AppSpacing.verticalLarge),
                _sectionTitle('Basic Information'),
                AppTextField(
                  label: 'Service Name',
                  icon: Icons.design_services_outlined,
                  initialValue: _name,
                  onChanged: (v) => _name = v,
                  validator: (v) =>
                      ServiceValidators.required(v, 'Service Name'),
                ),
                AppTextField(
                  label: 'Description (optional)',
                  icon: Icons.notes_outlined,
                  initialValue: _description,
                  onChanged: (v) => _description = v,
                  maxLines: 3,
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
                  child: JargonDropdown(
                    label: 'Category',
                    value: _category,
                    icon: Icons.category_outlined,
                    options: _categories,
                    showLabel: true,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ),
                AppTextField(
                  label: 'Duration (Minutes)',
                  icon: Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                  initialValue: _durationMinutes,
                  onChanged: (v) => _durationMinutes = v,
                  validator: (v) =>
                      ServiceValidators.positiveNumber(v, 'Duration'),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Applicable Gender'),
                      SegmentedToggle(
                        options: _genders,
                        value: _applicableGender.isEmpty
                            ? null
                            : _applicableGender,
                        onChanged: (val) =>
                            setState(() => _applicableGender = val),
                      ),
                    ],
                  ),
                ),
                // Type is intentionally not shown here — it's always
                // "Service" and is still sent as such in the save
                // payload (see _save), just no longer surfaced as a
                // field in the Create/Edit form per the latest spec.
                // Status likewise isn't shown here — a separate Mark
                // Active/Inactive action on Service Details handles
                // status changes; this form only sets Active by
                // default for a new service and carries over the
                // existing status untouched on edit.
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Pricing'),
                AppTextField(
                  label: 'Customer Price (₹)',
                  icon: Icons.currency_rupee,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  initialValue: _customerPrice,
                  onChanged: (v) => setState(() => _customerPrice = v),
                  validator: (v) =>
                      ServiceValidators.positiveNumber(v, 'Customer Price'),
                ),
                AppTextField(
                  label: 'Material Cost (₹, optional)',
                  icon: Icons.inventory_2_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  initialValue: _materialCost,
                  onChanged: (v) => setState(() => _materialCost = v),
                  validator: (v) =>
                      ServiceValidators.nonNegativeNumber(v, 'Material Cost'),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Staff Commission'),
                      SegmentedToggle(
                        options: _commissionTypes,
                        value: _commissionType,
                        onChanged: (val) =>
                            setState(() => _commissionType = val),
                      ),
                    ],
                  ),
                ),
                AppTextField(
                  label: _commissionType == 'Percentage'
                      ? 'Commission Value (%)'
                      : 'Commission Value (₹)',
                  icon: Icons.percent_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  initialValue: _commissionValue,
                  onChanged: (v) => setState(() => _commissionValue = v),
                  validator: (v) => ServiceValidators.requiredNonNegativeNumber(
                      v, 'Commission Value'),
                ),
                AppTextField(
                  label: 'Other Cost (₹, optional)',
                  icon: Icons.receipt_long_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  initialValue: _otherCost,
                  onChanged: (v) => setState(() => _otherCost = v),
                  validator: (v) =>
                      ServiceValidators.nonNegativeNumber(v, 'Other Cost'),
                ),
                _profitPreview(),
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Home Service'),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
                  child: SegmentedToggle(
                    options: _homeServiceOptions,
                    value: _homeServiceAvailable,
                    onChanged: (val) =>
                        setState(() => _homeServiceAvailable = val),
                  ),
                ),
                if (_homeServiceAvailable == 'Yes') ...[
                  AppTextField(
                    label: 'Home Visit Charges (₹)',
                    icon: Icons.home_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    initialValue: _homeVisitCharges,
                    onChanged: (v) => _homeVisitCharges = v,
                    validator: (v) => ServiceValidators.requiredNonNegativeNumber(
                        v, 'Home Visit Charges'),
                  ),
                  AppTextField(
                    label: 'Service Available Within (KM)',
                    icon: Icons.social_distance_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    initialValue: _serviceRadiusKm,
                    onChanged: (v) => _serviceRadiusKm = v,
                    validator: (v) => ServiceValidators.requiredNonNegativeNumber(
                        v, 'Service Radius'),
                  ),
                  AppTextField(
                    label: 'Extra Charge Per KM Beyond Radius (₹)',
                    icon: Icons.add_road_outlined,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    initialValue: _extraChargePerKm,
                    onChanged: (v) => _extraChargePerKm = v,
                    validator: (v) => ServiceValidators.requiredNonNegativeNumber(
                        v, 'Extra Charge Per KM'),
                  ),
                ],
                const SizedBox(height: AppSpacing.verticalSmall),
                _sectionTitle('Branch Assignment'),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.verticalMedium,
                  ),
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
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.verticalMedium,
                          ),
                          child: MultiSelectField(
                            label: 'Selected Branches',
                            icon: Icons.store_mall_directory_outlined,
                            options: _allBranchOptions
                                .map((b) => MultiSelectOption(
                                    id: b.id, label: b.name))
                                .toList(),
                            selectedIds: _selectedBranchIds,
                            onChanged: (ids) =>
                                setState(() => _selectedBranchIds = ids),
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
        style: AppTextStyles.h3.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Read-only, live-updating Profit preview — recalculated on every
  /// build from whatever pricing values are currently typed, per the
  /// spec's "Whenever any pricing field changes, Profit should update
  /// immediately."
  Widget _profitPreview() {
    final profit = _liveProfit;
    final isNegative = profit < 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: (isNegative ? AppColors.error : AppColors.success)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: (isNegative ? AppColors.error : AppColors.success)
              .withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up_rounded,
            color: isNegative ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profit',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  '₹${profit.toStringAsFixed(2)}',
                  style: AppTextStyles.h3.copyWith(
                    color: isNegative ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
