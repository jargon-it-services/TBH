import 'package:package_info_plus/package_info_plus.dart';

/// Exposes the running app's build number as a plain `int`, matching
/// the numeric `minimum_build`/`latest_build` contract the backend
/// version-check API uses (see AppVersionApi, AppVersionService).
///
/// Uses `package_info_plus`, which this project already anticipates —
/// `splash_page.dart` has a commented-out `PackageInfo.fromPlatform()`
/// call for its (unrelated, cosmetic) version-label text. This is a
/// separate call for a separate purpose, but the same mechanism, so no
/// new pattern is being introduced.
class AppBuildInfo {
  AppBuildInfo._();

  static int? _cachedBuildNumber;

  /// Cached after the first read (per app run) — the build number
  /// can't change while the app is running, so there's no reason to
  /// re-read platform info on every version check.
  static Future<int> currentBuildNumber() async {
    if (_cachedBuildNumber != null) return _cachedBuildNumber!;
    final info = await PackageInfo.fromPlatform();
    // buildNumber is a String on every platform (Android versionCode,
    // iOS CFBundleVersion) — parsed defensively since a malformed/empty
    // value must never crash the version check.
    _cachedBuildNumber = int.tryParse(info.buildNumber) ?? 0;
    return _cachedBuildNumber!;
  }
}
