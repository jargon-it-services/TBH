/// Validators used by TextFormField.validator across the registration flow.
/// Kept centralized so the rules stay consistent step to step.
class RegistrationValidators {
  RegistrationValidators._();

  static String? required(String? value, [String label = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? name(String? value, [String label = 'Name']) {
    final req = required(value, label);
    if (req != null) return req;
    if (value!.trim().length < 2) return '$label looks too short';
    return null;
  }

  static String? email(String? value) {
    final req = required(value, 'Email');
    if (req != null) return req;
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value!.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? value) {
    final req = required(value, 'Phone number');
    if (req != null) return req;
    final digitsOnly = value!.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  static String? zip(String? value) {
    final req = required(value, 'ZIP / Postal code');
    if (req != null) return req;
    if (value!.trim().length < 4) return 'Enter a valid postal code';
    return null;
  }

  static String? password(String? value) {
    final req = required(value, 'Password');
    if (req != null) return req;
    if (value!.length < 8) return 'Use at least 8 characters';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    if (!hasLetter || !hasDigit) {
      return 'Mix letters and numbers for a stronger password';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final req = required(value, 'Confirm password');
    if (req != null) return req;
    if (value != original) return 'Passwords do not match';
    return null;
  }

  /// Validates the ID number against the format expected for
  /// [idProofType]. PAN and Aadhaar get real format checks (both have a
  /// well-defined, fixed structure); every other ID type keeps the
  /// original generic "at least 4 characters" check unchanged.
  static String? idProofNumber(String? value, String idProofType) {
    final req = required(value, 'ID proof number');
    if (req != null) return req;
    final trimmed = value!.trim();

    switch (idProofType) {
      case 'PAN Card':
        // Indian PAN format: 5 letters, 4 digits, 1 letter (e.g. ABCDE1234F).
        final panRegex = RegExp(r'^[A-Za-z]{5}[0-9]{4}[A-Za-z]$');
        if (!panRegex.hasMatch(trimmed)) {
          return 'Enter a valid PAN number (e.g. ABCDE1234F)';
        }
        return null;

      case 'Aadhaar Card':
        // 12 digits — allow the user to type it with spaces (as it's
        // normally displayed, e.g. "1234 5678 9012") but validate the
        // digits themselves.
        final digitsOnly = trimmed.replaceAll(RegExp(r'\s+'), '');
        if (!RegExp(r'^\d{12}$').hasMatch(digitsOnly)) {
          return 'Enter a valid 12-digit Aadhaar number';
        }
        return null;

      default:
        if (trimmed.length < 4) return 'Enter a valid ID number';
        return null;
    }
  }
}
