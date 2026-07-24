import 'package:flutter/material.dart';

/// Holds the single [GlobalKey] handed to `MaterialApp.navigatorKey`.
///
/// This is the one place that knows how to "go to Login and clear the
/// stack" — used by both the forced-logout path (DioClient, when a
/// refresh-token attempt ultimately fails) and the explicit Logout flow
/// (AccountPage), so there is exactly one implementation of that
/// behavior instead of two independent ones that could drift apart.
///
/// The GlobalKey exists specifically for the DioClient case: an
/// interceptor has no BuildContext of its own to navigate with.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// Clears the navigation stack and lands on the named `/login` route
  /// (registered in `main.dart`). Safe to call from anywhere, including
  /// outside a BuildContext. If the navigator isn't attached yet (e.g.
  /// called before the app has finished its first frame), this is a
  /// no-op rather than throwing.
  ///
  /// [sessionExpired] distinguishes *why* the user landed here: true
  /// for a forced logout (DioClient giving up after a failed token
  /// refresh), false for an explicit, user-initiated logout. LoginPage
  /// reads this back out of the route arguments to show a one-time
  /// "Session expired" message only in the forced case — an explicit
  /// logout needs no explanation, the user just did it.
  static void goToLoginAndClearStack({bool sessionExpired = false}) {
    final state = key.currentState;
    if (state == null) return;
    state.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
      arguments: sessionExpired ? const {'sessionExpired': true} : null,
    );
  }

  /// Resolves "where does the user land after Splash / after finishing
  /// onboarding" — Home if a session exists, Login otherwise — as one
  /// shared call. Previously SplashPage and IntroductionPage each
  /// independently wrote the same `isLoggedIn ? Home : Login` branch;
  /// centralizing it here means that decision can't drift between the
  /// two call sites, the same reasoning as [goToLoginAndClearStack]
  /// above. Uses the named `/home` and `/login` routes (registered in
  /// `main.dart`) rather than importing the page widgets directly, so
  /// this stays a plain navigation utility rather than pulling feature
  /// widgets into `core/`.
  static void pushReplacementPostAuth(
    BuildContext context, {
    required bool isLoggedIn,
  }) {
    Navigator.of(context).pushReplacementNamed(isLoggedIn ? '/home' : '/login');
  }
}
