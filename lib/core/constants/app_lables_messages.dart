class AppConstantData {
  AppConstantData._();
  static const contact = "https://yourdomain.com/contact";
  static const terms = "https://yourdomain.com/terms-and-conditions";
  static const privacy = "https://yourdomain.com/privacy-policy";

  // TODO(store-listing): Replace with the real numeric Apple App Store
  // ID once the app is published (format:
  // https://apps.apple.com/app/id<APP_STORE_ID>). The Android Play
  // Store URL doesn't need a constant — AccountPage builds it directly
  // from the running app's package name via PackageInfo.
  static const appStoreUrl = "https://apps.apple.com/app/id0000000000";
}
