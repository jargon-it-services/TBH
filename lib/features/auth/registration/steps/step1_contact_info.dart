import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/apis/pincode_api.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/widgets/inline_action_button.dart';
import '../registration_data.dart';
import '../registration_validators.dart';
import '../widgets/registration_step_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/searchable_select_field.dart';

class Step1ContactInfo extends StatefulWidget {
  const Step1ContactInfo({
    super.key,
    required this.data,
    required this.onBack,
    required this.onContinue,
  });

  final RegistrationData data;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<Step1ContactInfo> createState() => _Step1ContactInfoState();
}

class _Step1ContactInfoState extends State<Step1ContactInfo>
    with AutomaticKeepAliveClientMixin {
  // Keeps this page's Element alive once scrolled off-screen instead of
  // letting PageView deactivate it. Without this, tapping "Save &
  // Continue" while a field is still focused can race the outgoing
  // page's deactivation against that field's unfocus/rebuild, throwing
  // "Looking up a deactivated widget's ancestor is unsafe."
  @override
  bool get wantKeepAlive => true;

  final _formKey = GlobalKey<FormState>();
  final _shakeTrigger = ValueNotifier<int>(0);
  final _pincodeApi = PincodeApi();

  // Full states+cities data loaded from the local JSON asset, keyed by
  // state name, e.g. {"Maharashtra": ["Mumbai", "Pune", ...], ...}.
  Map<String, List<String>> _stateCityMap = {};

  List<String> _states = [];
  List<String> _cities = [];
  bool _loadingStates = false;
  bool _loadingCities = false;
  bool _citiesFailed = false;
  String? _citiesFailMessage;
  bool _verifyingZip = false;
  bool _zipVerified = false;
  String? _zipError;
  String? _stateError;
  String? _cityError;
  String? _lastVerifiedZip;

  @override
  void initState() {
    super.initState();
    loadStatesAndCities();
  }

  @override
  void dispose() {
    _shakeTrigger.dispose();
    super.dispose();
  }

  /// Loads the states+cities data bundled as a local asset
  /// (`assets/india_states_cities.json`) instead of hitting an API.
  Future<void> loadStatesAndCities() async {
    if (_loadingStates) return;

    setState(() => _loadingStates = true);
    try {
      final String jsonStr =
          await rootBundle.loadString('assets/india_states_cities.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> rawStates = data['states'] as List<dynamic>;

      final map = <String, List<String>>{};
      for (final entry in rawStates) {
        final stateEntry = entry as Map<String, dynamic>;
        final name = stateEntry['state'] as String;
        final cities = List<String>.from(stateEntry['cities'] as List);
        map[name] = cities;
      }

      if (!mounted) return;
      setState(() {
        _stateCityMap = map;
        _states = map.keys.toList();
        _loadingStates = false;
      });

      // If a state was already selected (e.g. restoring saved progress),
      // populate its cities right away.
      if (widget.data.state.isNotEmpty) {
        _loadCitiesForState(widget.data.state);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStates = false);
    }
  }

  /// Looks up the cities for [state] from the locally loaded JSON data.
  void _loadCitiesForState(String state) {
    setState(() {
      _citiesFailed = false;
      _cities = _stateCityMap[state] ?? [];
      if (_cities.isEmpty) {
        _citiesFailed = true;
        _citiesFailMessage = 'No cities found for this state';
      }
    });
  }

  Future<void> _verifyZip() async {
    // Same synchronous guard as above — blocks a double-tap outright.
    if (_verifyingZip) return;

    final zip = widget.data.zip.trim();
    if (zip.isEmpty) {
      setState(() => _zipError = 'Enter a postal code to verify');
      return;
    }

    setState(() {
      _verifyingZip = true;
      _zipError = null;
    });

    final result = await _pincodeApi.verify(zip);

    if (!mounted) return;
    setState(() => _verifyingZip = false);

    if (result.isOffline) {
      setState(() {
        _zipVerified = false;
        _zipError =
            "You're offline — check your connection and try verifying again.";
      });
      return;
    }

    if (!result.isValid) {
      setState(() {
        _zipVerified = false;
        _zipError =
            "We couldn't find this postal code. Please enter a valid one.";
      });
      return;
    }

    // Verified — auto-populate City/State from the result. Still fully
    // editable afterward via the dropdowns below.
    setState(() {
      _lastVerifiedZip = zip;
      _zipVerified = true;
      _zipError = null;
      if (result.state != null && result.state!.isNotEmpty) {
        widget.data.state = result.state!;
        _stateError = null;
      }
    });

    if (result.state != null && result.state!.isNotEmpty) {
      _loadCitiesForState(result.state!);
      if (result.city != null &&
          result.city!.isNotEmpty &&
          _cities.contains(result.city)) {
        setState(() {
          widget.data.city = result.city!;
          _cityError = null;
        });
      }
    }
  }

  bool _validateSelections() {
    final valid = widget.data.state.isNotEmpty && widget.data.city.isNotEmpty;
    setState(() {
      _stateError = widget.data.state.isEmpty ? 'Please select a state' : null;
      _cityError = widget.data.city.isEmpty ? 'Please select a city' : null;
    });
    if (!valid) _shakeTrigger.value++;
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d = widget.data;
    // Once the ZIP text is edited past what we last verified, this goes
    // false again — the Verify button reappears and the badge hides.
    final zipUnchangedSinceVerify = _zipVerified &&
        d.zip.trim() == _lastVerifiedZip &&
        d.zip.trim().isNotEmpty;

    return RegistrationStepScaffold(
      stepIndex: 0,
      totalSteps: 4,
      title: 'Account Information',
      subtitle: "Your account's contact details",
      formKey: _formKey,
      shakeTrigger: _shakeTrigger,
      onBack: widget.onBack,
      onContinue: () async {
        if (_validateSelections()) widget.onContinue();
        return false;
      },
      child: Column(
        children: [
          AppTextField(
            label: 'Account Name',
            icon: Icons.person_outline,
            initialValue: d.accountName,
            onChanged: (v) => d.accountName = v,
            validator: (v) =>
                RegistrationValidators.required(v, 'Account Name'),
          ),
          AppTextField(
            label: 'Phone Number',
            icon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            initialValue: d.phone,
            onChanged: (v) => d.phone = v,
            validator: RegistrationValidators.phone,
          ),
          AppTextField(
            label: 'Account Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            initialValue: d.accountEmail,
            onChanged: (v) => d.accountEmail = v,
            validator: RegistrationValidators.email,
          ),
          AppTextField(
            label: 'Address',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            initialValue: d.address,
            onChanged: (v) => d.address = v,
            validator: (v) => RegistrationValidators.required(v, 'Address'),
          ),
          AppTextField(
            label: 'ZIP / Postal Code',
            icon: Icons.pin_drop_outlined,
            keyboardType: TextInputType.number,
            initialValue: d.zip,
            onChanged: (v) {
              d.zip = v;
              if (_zipError != null) setState(() => _zipError = null);
              // Editing past the last verified value invalidates it —
              // this flips zipUnchangedSinceVerify back to false on
              // rebuild, which swaps the badge back to the Verify button.
              if (d.zip.trim() != _lastVerifiedZip) setState(() {});
            },
            validator: RegistrationValidators.zip,
            suffixIcon: _verifyingZip
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
                            const Icon(Icons.check_circle,
                                size: 16, color: AppColors.success),
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
                    : InlineActionButton(
                        label: 'Verify',
                        onPressed: _verifyZip,
                      ),
          ),
          if (_zipError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 13, color: AppColors.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _zipError!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          SearchableSelectField(
            label: 'City',
            icon: Icons.location_city_outlined,
            value: d.city.isEmpty ? null : d.city,
            options: _cities,
            loading: _loadingCities,
            failed: _citiesFailed,
            failedMessage: _citiesFailMessage,
            onRetry: () => _loadCitiesForState(d.state),
            enabled: false,
            disabledHint: 'Please select a State first',
            errorText: _cityError,
            onSelected: (v) => setState(() {
              d.city = v;
              _cityError = null;
            }),
          ),
          SearchableSelectField(
            label: 'State',
            icon: Icons.map_outlined,
            value: d.state.isEmpty ? null : d.state,
            options: _states,
            loading: _loadingStates,
            errorText: _stateError,
            enabled: false,
            onSelected: (v) {
              setState(() {
                d.state = v;
                d.city = ''; // reset city when state changes
                _stateError = null;
              });
              _loadCitiesForState(v);
            },
          ),
        ],
      ),
    );
  }
}
