import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the platform's browser/store app. Shared by
/// [ForceUpdatePage] and [OptionalUpdateDialog] so this parse-and-guard
/// logic exists in exactly one place instead of being copied between
/// them.
class AppStoreLauncher {
  AppStoreLauncher._();

  static Future<void> open(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
