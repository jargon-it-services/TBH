/// ================= ACCOUNT INFO =================
///
/// Everything the user filled in during Registration (`RegistrationData`
/// — Account Information, Owner Details, Login), read back so an
/// Account Admin can see "what did we fill in at signup?" in one place.
///
/// Only [phone], [address], [zip] (with [city]/[state] auto-derived
/// from it), [ownerName], and [designation] are editable via
/// `AccountInfoApi.updateAccountInfo` — every other field here is
/// read-only, matching the Account Info spec.
class AccountInfoResponse {
  // ---- Account Information (Step 1) ----
  final String accountName;
  final String accountEmail;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String zip;

  // ---- Owner Details (Step 2) ----
  final String ownerName;
  final String designation;
  final String idProofType;
  final String idProofNumber;
  final String? idProofDocumentUrl;

  // ---- Login (Step 3) ----
  final String loginEmail;

  const AccountInfoResponse({
    required this.accountName,
    required this.accountEmail,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.ownerName,
    required this.designation,
    required this.idProofType,
    required this.idProofNumber,
    this.idProofDocumentUrl,
    required this.loginEmail,
  });

  factory AccountInfoResponse.fromJson(Map<String, dynamic> json) {
    return AccountInfoResponse(
      accountName: json['account_name'] ?? '',
      accountEmail: json['account_email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zip: json['zip'] ?? '',
      ownerName: json['owner_name'] ?? '',
      designation: json['designation'] ?? '',
      idProofType: json['id_proof_type'] ?? '',
      idProofNumber: json['id_proof_number'] ?? '',
      idProofDocumentUrl: json['id_proof_document_url'] as String?,
      loginEmail: json['login_email'] ?? '',
    );
  }
}
