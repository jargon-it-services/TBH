import 'dart:async';

import 'package:app_links/app_links.dart';

import 'invite_token_manager.dart';

/// Handles Android App Links / iOS Universal Links of the form
/// `https://app.tbh.com/i/{token}` and extracts + stores the invite
/// token they carry.
///
/// This is deliberately narrow in scope. [DeepLinkService] does NOT:
///   - navigate anywhere
///   - call any API
///   - show any dialog/snackbar
///   - know or care whether the user is authenticated
///
/// Its only job is "a link came in → is it an invite link → if so,
/// hand the token to [InviteTokenManager]". Whatever happens next
/// (registration reading the token later) is entirely someone else's
/// responsibility — this keeps deep link handling reusable for
/// whatever other link types the app may need in the future, without
/// this service accumulating unrelated concerns.
///
/// Uses `app_links` (not Firebase Dynamic Links, Branch, or uni_links)
/// per the project's chosen deep-linking approach.
class DeepLinkService {
  DeepLinkService._internal();

  static final DeepLinkService instance = DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  final InviteTokenManager _inviteTokenManager = InviteTokenManager();

  StreamSubscription<Uri>? _linkSubscription;

  /// Call once during application startup (see `main.dart`).
  ///
  /// Covers all three cases the feature needs:
  ///   - Cold start: the link that launched the app, via
  ///     [AppLinks.getInitialLink].
  ///   - Warm start / app already running: subsequent links delivered
  ///     while the app is alive, via [AppLinks.uriLinkStream].
  Future<void> initialize() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleUri(initialUri);
      }
    } catch (_) {
      // A malformed initial link must never crash app startup — this
      // service's only job is to opportunistically capture a token,
      // never to gate whether the app can launch.
    }

    _linkSubscription ??= _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {
        // Same reasoning as above: swallow, don't propagate. Deep link
        // handling must stay best-effort and silent by design.
      },
    );
  }

  Future<void> _handleUri(Uri uri) async {
    final token = _extractInviteToken(uri);
    if (token != null && token.isNotEmpty) {
      await _inviteTokenManager.saveToken(token);
    }
  }

  /// Extracts the opaque token from an invite link of the form
  /// `https://app.tbh.com/i/{token}`. Returns null for any URI that
  /// isn't shaped like an invite link — this service only ever
  /// recognizes that one deep link format, per the backend contract
  /// (no account/referral code, user id, or business id is ever
  /// exposed in the link).
  String? _extractInviteToken(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length == 2 && segments[0] == 'i') {
      return segments[1];
    }
    return null;
  }

  /// Stops listening for incoming links. Not currently called anywhere
  /// (this service lives for the app's entire lifetime, same as
  /// [SessionManager]), provided for symmetry/testability.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}
