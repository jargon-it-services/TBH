import 'package:flutter/material.dart';

import '../../features/auth/registration/widgets/searchable_select_field.dart';
import '../network/apis/pincode_api.dart';
import '../services/india_states_cities_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_text_field.dart';
import 'inline_action_button.dart';

/// Pin/ZIP code field with a "Verify" action that looks the code up via
/// [PincodeApi] and auto-fills State + City — plus the State/City
/// selectors themselves, kept together since they're one unit of
/// behavior.
///
/// This is the same lookup-and-autofill flow `Step1ContactInfo` (the
/// Registration flow) already has, pulled out into one shared widget
/// so the Branch Create and Branch Edit forms don't reimplement it a
/// second and third time. `Step1ContactInfo` itself is left exactly as
/// it was — it's a working, already-shipped step of Registration, and
/// swapping its internals for this widget carries real regression risk
/// for no behavior change the user would see, so it isn't worth
/// touching. New code (Branch Create/Edit) uses this shared widget from
/// the start instead.
class PincodeLookupField extends StatefulWidget {
  const PincodeLookupField({
    super.key,
    required this.initialPincode,
    required this.onPincodeChanged,
    required this.initialState,
    required this.initialCity,
    required this.onStateSelected,
    required this.onCitySelected,
    this.pincodeValidator,
  });

  final String initialPincode;
  final ValueChanged<String> onPincodeChanged;

  final String initialState;
  final String initialCity;
  final ValueChanged<String> onStateSelected;
  final ValueChanged<String> onCitySelected;

  final String? Function(String?)? pincodeValidator;

  @override
  State<PincodeLookupField> createState() => PincodeLookupFieldState();
}

/// Public so callers can hold a `GlobalKey<PincodeLookupFieldState>` and
/// invoke [validateSelections] from the parent form's own Save flow.
class PincodeLookupFieldState extends State<PincodeLookupField> {
  final _pincodeApi = PincodeApi();

  late String _pincode = widget.initialPincode;
  late String _state = widget.initialState;
  late String _city = widget.initialCity;

  Map<String, List<String>> _stateCityMap = {};
  List<String> _states = [];
  List<String> _cities = [];
  bool _loadingStates = true;
  String? _stateError;
  String? _cityError;

  bool _verifying = false;
  bool _verified = false;
  String? _zipError;
  String? _lastVerifiedZip;

  @override
  void initState() {
    super.initState();
    _loadStatesAndCities();
  }

  Future<void> _loadStatesAndCities() async {
    try {
      final map = await IndiaStatesCitiesService.load();
      if (!mounted) return;
      setState(() {
        _stateCityMap = map;
        _states = map.keys.toList();
        _loadingStates = false;
        if (_state.isNotEmpty) _cities = map[_state] ?? [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStates = false);
    }
  }

  void _onStateSelected(String state) {
    setState(() {
      _state = state;
      _city = '';
      _cities = _stateCityMap[state] ?? [];
      _stateError = null;
    });
    widget.onStateSelected(state);
    widget.onCitySelected('');
  }

  void _onCitySelected(String city) {
    setState(() {
      _city = city;
      _cityError = null;
    });
    widget.onCitySelected(city);
  }

  Future<void> _verifyZip() async {
    if (_verifying) return;

    final zip = _pincode.trim();
    if (zip.isEmpty) {
      setState(() => _zipError = 'Enter a postal code to verify');
      return;
    }

    setState(() {
      _verifying = true;
      _zipError = null;
    });

    final result = await _pincodeApi.verify(zip);
    if (!mounted) return;
    setState(() => _verifying = false);

    if (result.isOffline) {
      setState(() {
        _verified = false;
        _zipError =
            "You're offline — check your connection and try verifying again.";
      });
      return;
    }

    if (!result.isValid) {
      setState(() {
        _verified = false;
        _zipError =
            "We couldn't find this postal code. Please enter a valid one.";
      });
      return;
    }

    setState(() {
      _lastVerifiedZip = zip;
      _verified = true;
      _zipError = null;
    });

    if (result.state != null && result.state!.isNotEmpty) {
      _onStateSelected(result.state!);
      if (result.city != null &&
          result.city!.isNotEmpty &&
          (_stateCityMap[result.state!] ?? []).contains(result.city)) {
        _onCitySelected(result.city!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zipUnchangedSinceVerify =
        _verified &&
        _pincode.trim() == _lastVerifiedZip &&
        _pincode.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Pin Code / ZIP Code',
          icon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
          initialValue: _pincode,
          onChanged: (v) {
            _pincode = v;
            widget.onPincodeChanged(v);
            if (_zipError != null) setState(() => _zipError = null);
            if (v.trim() != _lastVerifiedZip) setState(() {});
          },
          validator: widget.pincodeValidator,
          suffixIcon: _verifying
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : zipUnchangedSinceVerify
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : InlineActionButton(label: 'Verify', onPressed: _verifyZip),
        ),
        if (_zipError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 13,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _zipError!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SearchableSelectField(
          label: 'State',
          icon: Icons.map_outlined,
          value: _state.isEmpty ? null : _state,
          options: _states,
          loading: _loadingStates,
          errorText: _stateError,
          disabledHint: "Please enter 'Pin Code / ZIP Code' first",
          onSelected: _onStateSelected,
          enabled: false,
        ),
        SearchableSelectField(
          label: 'City',
          icon: Icons.location_city_outlined,
          value: _city.isEmpty ? null : _city,
          options: _cities,
          disabledHint: "Please enter 'Pin Code / ZIP Code' first",
          errorText: _cityError,
          onSelected: _onCitySelected,
          enabled: false,
        ),
      ],
    );
  }

  /// Called by the parent form's own validation pass (State/City live
  /// outside the `Form`'s own field validators, same as
  /// `Step1ContactInfo._validateSelections`).
  bool validateSelections() {
    final valid = _state.isNotEmpty && _city.isNotEmpty;
    setState(() {
      _stateError = _state.isEmpty ? 'Please select a state' : null;
      _cityError = _city.isEmpty ? 'Please select a city' : null;
    });
    return valid;
  }
}
