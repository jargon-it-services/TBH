import 'dart:io';

/// Holds every field across the 4-step registration flow (Account, Owner,
/// Account Setup, Review). Business/branch details are collected separately
/// in the Add Branch flow, so they don't live here.
class RegistrationData {
  // ---- Step 1: Account Information ----
  String accountName = '';
  String address = '';
  String city = '';
  String state = '';
  String zip = '';
  String phone = '';
  String accountEmail = '';

  /// Optional — Indian GSTIN, 15 characters when provided.
  String gstin = '';

  /// Optional — the account's photo/logo. Distinct from the Owner's ID
  /// proof document ([idProofDocument]).
  File? accountPhoto;

  // ---- Step 2: Owner ----
  String ownerName = '';
  String designation = '';
  String idProofType = 'Select ID Type';
  String idProofNumber = '';
  File? idProofDocument;

  // ---- Step 3: Account ----
  String loginEmail = '';
  String password = '';

  static const idProofTypes = [
    'PAN Card',
    'Aadhaar Card',
    'Passport',
    'Driving License',
    'Voter ID',
  ];
}
