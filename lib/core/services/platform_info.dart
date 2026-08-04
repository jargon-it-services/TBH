import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Auto-detects which platform the app is running on — never shown to
/// the user as a field; silently attached to request payloads that
/// need to know where a request originated (Registration, Account Info
/// update).
class PlatformInfo {
  PlatformInfo._();

  /// "android", "ios", or "web".
  static String get current {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }
}
