/// ================= ACCOUNT INFO =================
///
/// Everything the user filled in during Registration (`RegistrationData`
/// — Account Information, Owner Details, Login), read back so an
/// Account Admin can see "what did we fill in at signup?" in one place.
///
/// Editable via `AccountInfoApi.updateAccountInfo`: [phone], [address],
/// [zip] (with [city]/[state] auto-derived from it), [gstin],
/// [accountPhotoUrl], [ownerName], and [designation]. Every other
/// field — including [accountCode] — is read-only.
class AccountInfoResponse {
  /// System-assigned, non-editable identifier for this account.
  final String accountCode;

  // ---- Account Information (Step 1) ----
  final String accountName;
  final String accountEmail;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zip;

  /// Optional — Indian GSTIN, 15 characters when provided. Editable.
  final String gstin;

  /// Optional — the account's photo/logo. Editable, distinct from the
  /// Owner's read-only ID proof document ([idProofDocumentUrl]).
  final String? accountPhotoUrl;

  // ---- Owner Details (Step 2) ----
  final String ownerName;
  final String designation;
  final String idProofType;
  final String idProofNumber;
  final String? idProofDocumentUrl;

  // ---- Login (Step 3) ----
  final String loginEmail;

  bool get hasAccountPhoto => accountPhotoUrl != null && accountPhotoUrl!.trim().isNotEmpty;

  const AccountInfoResponse({
    required this.accountCode,
    required this.accountName,
    required this.accountEmail,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    this.gstin = '',
    this.accountPhotoUrl,
    required this.ownerName,
    required this.designation,
    required this.idProofType,
    required this.idProofNumber,
    this.idProofDocumentUrl,
    required this.loginEmail,
  });

  factory AccountInfoResponse.fromJson(Map<String, dynamic> json) {
    return AccountInfoResponse(
      accountCode: json['account_code'] ?? '',
      accountName: json['account_name'] ?? '',
      accountEmail: json['account_email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zip: json['zip'] ?? '',
      gstin: json['gstin'] ?? '',
      accountPhotoUrl: json['account_photo_url'] as String?,
      ownerName: json['owner_name'] ?? '',
      designation: json['designation'] ?? '',
      idProofType: json['id_proof_type'] ?? '',
      idProofNumber: json['id_proof_number'] ?? '',
      idProofDocumentUrl: json['id_proof_document_url'] as String?,
      loginEmail: json['login_email'] ?? '',
    );
  }
}
