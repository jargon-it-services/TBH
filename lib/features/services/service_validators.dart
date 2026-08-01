/// Validators used by [TextFormField.validator] across the Service
/// module's Add/Edit form. Mirrors
/// `features/auth/registration/registration_validators.dart`'s
/// feature-local pattern — these numeric checks (positive/non-negative
/// amounts) are specific to Service pricing/duration fields, so they
/// live here rather than inside the registration-scoped validators.
class ServiceValidators {
  ServiceValidators._();

  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  /// Required and must parse to a number greater than zero — used for
  /// Customer Price and Duration.
  static String? positiveNumber(String? value, String label) {
    final req = required(value, label);
    if (req != null) return req;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid $label';
    if (parsed <= 0) return '$label must be greater than 0';
    return null;
  }

  /// Optional, but if present must parse to a number and can't be
  /// negative — used for Material Cost, Other Cost.
  static String? nonNegativeNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid $label';
    if (parsed < 0) return '$label cannot be negative';
    return null;
  }

  /// Required and can't be negative — used for Commission Value and,
  /// when Home Service is enabled, its three charge/radius fields.
  static String? requiredNonNegativeNumber(String? value, String label) {
    final req = required(value, label);
    if (req != null) return req;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid $label';
    if (parsed < 0) return '$label cannot be negative';
    return null;
  }
}
