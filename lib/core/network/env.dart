class Env {
  static const bool isMock = true; // change to false for prod

  /// Hosts the auth/identity/account surface — see [DioClient]'s
  /// `_authServicePaths` for exactly which relative paths route here.
  /// No trailing slash, to match how every `*_api.dart` file's path
  /// strings already start with '/' (avoids a double-slash join).
  static const String authBaseUrl = 'https://authapi.jargonits.com/api';

  /// Hosts everything else — the default for any path not explicitly
  /// listed in `_authServicePaths`.
  static const String appBaseUrl = 'https://tbhapi.jargonits.com/api';

  /// OneSignal App ID (Settings > Keys & IDs in the OneSignal
  /// dashboard). Left as a placeholder here -- `NotificationPushService`
  /// checks for this exact placeholder and skips initialization rather
  /// than crashing/spamming errors when it hasn't been configured yet.
  static const String oneSignalAppId = '57014558-858c-4e0f-b382-f47072708b9e';
}
