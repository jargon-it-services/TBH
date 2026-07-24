import '../storage/secure_storage_service.dart';

/// Tracks whether the user has completed the one-time onboarding
/// (Information Screen) flow.
///
/// Deliberately its own small singleton, separate from [SessionManager],
/// so that nothing about auth (login/logout/token refresh) can ever
/// touch this flag. [SessionManager.clearSession] only ever deletes its
/// own auth-related keys — it has no reference to the key used here —
/// so "logout must not clear onboarding_completed" holds by construction,
/// not by a checklist someone has to remember.
///
/// Reuses [SecureStorageService] purely to avoid introducing a second
/// storage dependency into the project. The value stored here isn't
/// sensitive; if a plain (non-secure) local storage layer is added to
/// this app later for other reasons, this is a reasonable candidate to
/// move onto it — but that's a separate decision, not needed today.
class OnboardingManager {
  OnboardingManager._internal();

  static final OnboardingManager instance = OnboardingManager._internal();

  static const _onboardingCompletedKey = 'onboarding_completed';

  final SecureStorageService _storage = SecureStorageService();

  bool? _cachedValue;

  /// Whether the user has already been through onboarding. Cached in
  /// memory after the first read (per app run) so SplashPage and
  /// IntroductionPage don't each trigger a separate storage read.
  Future<bool> isOnboardingCompleted() async {
    if (_cachedValue != null) return _cachedValue!;
    try {
      final value = await _storage.read(_onboardingCompletedKey);
      _cachedValue = value == 'true';
    } catch (_) {
      // If storage can't be read, fail safe into "not completed" so the
      // user sees onboarding rather than the app silently skipping it.
      _cachedValue = false;
    }
    return _cachedValue!;
  }

  /// Marks onboarding as complete, persisted so it survives app
  /// restarts (and, since it lives outside SessionManager entirely,
  /// survives logout too).
  Future<void> markOnboardingCompleted() async {
    _cachedValue = true;
    await _storage.write(_onboardingCompletedKey, 'true');
  }
}
