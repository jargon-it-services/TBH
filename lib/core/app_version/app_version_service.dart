import '../network/apis/app_version_api.dart';
import '../services/app_build_info.dart';

/// Result of evaluating a version check against the running app's build
/// number — see [AppVersionService.checkVersion].
enum AppVersionCheckStatus {
  /// Backend says the app is under maintenance — block navigation
  /// entirely.
  maintenance,

  /// `currentBuild < minimumBuild` — block navigation, only an Update
  /// button.
  forceUpdate,

  /// `minimumBuild <= currentBuild < latestBuild` — don't block; show a
  /// dismissible "update available" prompt.
  optionalUpdate,

  /// Nothing to show — proceed exactly as the app did before this
  /// feature existed.
  upToDate,
}

/// [status] plus the raw [result] the decision was based on (null only
/// when the check itself couldn't complete — see [AppVersionService]).
class AppVersionCheckResult {
  final AppVersionCheckStatus status;
  final AppVersionResult? result;

  const AppVersionCheckResult(this.status, this.result);
}

/// Single source of truth for "should the app let the user in right
/// now" — calls [AppVersionApi], compares build numbers, and returns
/// one [AppVersionCheckStatus]. Same singleton shape as
/// [OnboardingManager]/[ConnectivityService] — no new architectural
/// pattern introduced.
class AppVersionService {
  AppVersionService._internal();

  static final AppVersionService instance = AppVersionService._internal();

  final AppVersionApi _api = AppVersionApi();

  /// Runs the check. Deliberately "fails open": if the version-check
  /// call itself can't complete (offline, timeout, backend error,
  /// malformed response), this returns [AppVersionCheckStatus.upToDate]
  /// rather than blocking a legitimate user over an unrelated
  /// infrastructure problem — that matches the app's behavior before
  /// this feature existed (no gate at all). If your rollout policy
  /// wants fail-closed instead (block on an unreachable check), change
  /// the `!response.isSuccess` branch below to return `maintenance`.
  Future<AppVersionCheckResult> checkVersion() async {
    final response = await _api.checkVersion();

    if (!response.isSuccess || response.data == null) {
      return const AppVersionCheckResult(
        AppVersionCheckStatus.upToDate,
        null,
      );
    }

    final result = response.data!;

    if (result.maintenance) {
      return AppVersionCheckResult(AppVersionCheckStatus.maintenance, result);
    }

    final currentBuild = await AppBuildInfo.currentBuildNumber();
    final minimumBuild = result.minimumBuild;
    final latestBuild = result.latestBuild;

    // Build-number comparison only, per the version-management spec —
    // never semantic version strings.
    if (minimumBuild != null && currentBuild < minimumBuild) {
      return AppVersionCheckResult(AppVersionCheckStatus.forceUpdate, result);
    }

    if (latestBuild != null && currentBuild < latestBuild) {
      return AppVersionCheckResult(
        AppVersionCheckStatus.optionalUpdate,
        result,
      );
    }

    return AppVersionCheckResult(AppVersionCheckStatus.upToDate, result);
  }
}
