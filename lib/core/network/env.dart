class Env {
  static const bool isMock = true; // change to false for prod
  static const String apiBaseUrl = 'https://api.yourdomain.com';

  /// OneSignal App ID (Settings > Keys & IDs in the OneSignal
  /// dashboard). Left as a placeholder here -- `NotificationPushService`
  /// checks for this exact placeholder and skips initialization rather
  /// than crashing/spamming errors when it hasn't been configured yet.
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID';
}
