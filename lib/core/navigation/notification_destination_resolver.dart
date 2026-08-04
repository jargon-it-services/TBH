import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/payments/payment_details_page.dart';
import '../../features/subscriptions/subscription_plans_page.dart';
import '../../features/transactions/transaction_details_page.dart';
import '../services/DataModels/notification_model.dart';
import '../widgets/app_snackbar.dart';

/// Maps `destination.type` to an existing, feature-specific screen (or
/// external action) and performs the navigation.
///
/// This is deliberately the ONLY file in the whole app allowed to
/// contain a `switch (destination.type)` for notification purposes --
/// see the module's core design principle ("never hardcode navigation
/// logic based on notification type" anywhere else). `NotificationListPage`,
/// `NotificationDetailPage`, and `NotificationNavigator` all stay
/// completely generic; they only ever call
/// [NotificationDestinationResolver.resolve].
///
/// Adding a brand-new destination type in the future means adding
/// exactly one new `case` here -- nothing else in the module changes.
class NotificationDestinationResolver {
  const NotificationDestinationResolver._();

  /// Resolves and performs the navigation/action for [destination].
  /// Every branch is wrapped so a bad/missing `reference_id`, an
  /// invalid URL, or a screen that doesn't exist yet degrades to a
  /// friendly message instead of crashing -- per the "gracefully
  /// handle unknown destination types / missing reference IDs /
  /// invalid URLs / failed navigation" requirement.
  static Future<void> resolve(
    BuildContext context,
    NotificationDestination destination,
  ) async {
    try {
      switch (destination.type) {
        case 'transaction':
          await _openTransaction(context, destination);
          return;

        case 'payment':
          await _openPayment(context, destination);
          return;

        case 'subscription':
          await _openSubscription(context);
          return;

        // ---------------------------------------------------------
        // Part of the contract (02_API_Contracts.md /
        // Enterprise_Notification_Module_Prompt.md) but no
        // corresponding screen exists in this project yet (no
        // Payslip / P&L / Revenue Summary / Payment Mode /
        // Performance feature has been built). Per "Future
        // Extensibility", wiring a real screen up later is a
        // one-line change *right here* -- replace the branch below
        // with a real `Navigator.push(...)` once that screen exists.
        // Until then this fails gracefully instead of crashing or
        // silently doing nothing.
        // ---------------------------------------------------------
        case 'payslip':
        case 'payslip_list':
        case 'pnl':
        case 'revenue_summary':
        case 'payment_mode':
        case 'performance':
          _openNotYetAvailable(context);
          return;

        case 'webview':
          await _openInAppBrowser(context, destination.url);
          return;

        case 'browser':
          await _openExternalBrowser(context, destination.url);
          return;

        case 'none':
          // Informational notification -- deliberately no navigation.
          return;

        default:
          // Unknown/future destination.type this build doesn't
          // recognize yet -- fail safe rather than throw.
          _openNotYetAvailable(context);
          return;
      }
    } catch (_) {
      // Absolute last line of defense: navigation must never crash
      // the app, regardless of what went wrong above.
      if (context.mounted) {
        AppSnackbar.error(context, "We couldn't open that right now.");
      }
    }
  }

  // ---------------- concrete destinations ----------------

  static Future<void> _openTransaction(
    BuildContext context,
    NotificationDestination destination,
  ) async {
    final id = destination.referenceId;
    if (id == null || id.isEmpty) {
      AppSnackbar.error(context, "This transaction couldn't be found.");
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionDetailsPage(transactionId: id),
      ),
    );
  }

  static Future<void> _openPayment(
    BuildContext context,
    NotificationDestination destination,
  ) async {
    final id = destination.referenceId;
    if (id == null || id.isEmpty) {
      AppSnackbar.error(context, "This payment couldn't be found.");
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentDetailsPage(transactionId: id),
      ),
    );
  }

  static Future<void> _openSubscription(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionPlansPage()),
    );
  }

  static void _openNotYetAvailable(BuildContext context) {
    if (!context.mounted) return;
    AppSnackbar.info(context, "This feature isn't available yet.");
  }

  static Future<void> _openInAppBrowser(
    BuildContext context,
    String? url,
  ) async {
    final uri = _parseHttpUri(url);
    if (uri == null) {
      AppSnackbar.error(context, "This link isn't valid.");
      return;
    }
    // "webview" is fulfilled via url_launcher's in-app browser mode
    // (Chrome Custom Tabs / SFSafariViewController) rather than adding
    // a new webview_flutter dependency -- url_launcher is already a
    // project dependency, so this stays inside "reuse existing
    // utilities" instead of pulling in a new package for one screen.
    final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!launched && context.mounted) {
      AppSnackbar.error(context, "Couldn't open this link.");
    }
  }

  static Future<void> _openExternalBrowser(
    BuildContext context,
    String? url,
  ) async {
    final uri = _parseHttpUri(url);
    if (uri == null) {
      AppSnackbar.error(context, "This link isn't valid.");
      return;
    }
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      AppSnackbar.error(context, "Couldn't open this link.");
    }
  }

  static Uri? _parseHttpUri(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }
    return uri;
  }
}
