/// Shared numeric validators for [TextFormField.validator], used by the
/// Expenses and Salary Rules modules' Add/Edit forms.
///
/// `service_validators.dart` (feature-local to Services) already has an
/// equivalent set; that one is left as-is to avoid touching shipped
/// code. This shared copy lives in `core` so Expenses, Salary Rules,
/// and any future module reuse one implementation instead of each
/// growing its own near-identical validator class.
class NumericFieldValidators {
  NumericFieldValidators._();

  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  /// Required and must parse to a number greater than zero.
  static String? positiveNumber(String? value, String label) {
    final req = required(value, label);
    if (req != null) return req;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid $label';
    if (parsed <= 0) return '$label must be greater than 0';
    return null;
  }

  /// Optional, but if present must parse to a number and can't be
  /// negative.
  static String? nonNegativeNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid $label';
    if (parsed < 0) return '$label cannot be negative';
    return null;
  }

  /// Required and can't be negative.
  static String? requiredNonNegativeNumber(String? value, String label) {
    final req = required(value, label);
    if (req != null) return req;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null) return 'Enter a valid $label';
    if (parsed < 0) return '$label cannot be negative';
    return null;
  }
}
