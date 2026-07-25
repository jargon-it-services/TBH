import 'package:intl/intl.dart';

/// Formats dashboard dates/times using the API's own `meta.date_format`
/// (an ICU/`intl` pattern like `"dd MMM yyyy"`, used as-is with
/// [DateFormat]) and `meta.timezone`, instead of any hardcoded pattern.
///
/// Timezone handling: this app has no IANA timezone database dependency
/// (that's a separate `timezone` package, out of scope for this task —
/// only `intl` was approved), so this uses a small fixed-offset table
/// for the zones the API actually sends. That's not a shortcut for
/// `Asia/Kolkata` specifically — India has a single fixed UTC+5:30
/// offset with no daylight-saving shifts, so a fixed offset is exactly
/// correct there, not an approximation. A timestamp with no UTC/offset
/// marker (e.g. `"2026-07-25T16:30:00"`) is treated as already being
/// wall-clock time in `meta.timezone` and is formatted as-is. A
/// timestamp that *is* UTC (has a `Z`/offset suffix) is shifted by the
/// matched zone's offset first. An unrecognized timezone string falls
/// back to the device's local time rather than guessing.
class DashboardDateFormatter {
  DashboardDateFormatter._();

  static const Map<String, Duration> _fixedOffsets = {
    'Asia/Kolkata': Duration(hours: 5, minutes: 30),
    'UTC': Duration.zero,
    'GMT': Duration.zero,
  };

  static DateTime _inTimezone(DateTime dateTime, String timezone) {
    if (!dateTime.isUtc) {
      // No UTC/offset marker on the source string — already local
      // wall-clock time for `timezone`, nothing further to shift.
      return dateTime;
    }
    final offset = _fixedOffsets[timezone];
    if (offset == null) return dateTime.toLocal();
    return dateTime.add(offset);
  }

  /// Parses [rawDate] (an ISO-8601 string from the API, or null/empty)
  /// and formats it with [pattern], shifted into [timezone]. Returns an
  /// empty string for anything unparsable, rather than throwing.
  static String formatIso(
    String? rawDate, {
    required String pattern,
    required String timezone,
  }) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return '';
    return format(parsed, pattern: pattern, timezone: timezone);
  }

  /// Formats an already-parsed [dateTime] with [pattern], shifted into
  /// [timezone]. Falls back to the raw ISO string if [pattern] is empty
  /// or formatting otherwise fails, rather than throwing or showing
  /// nothing.
  static String format(
    DateTime? dateTime, {
    required String pattern,
    required String timezone,
  }) {
    if (dateTime == null) return '';
    if (pattern.trim().isEmpty) return dateTime.toIso8601String();
    try {
      final zoned = _inTimezone(dateTime, timezone);
      return DateFormat(pattern).format(zoned);
    } catch (_) {
      return dateTime.toIso8601String();
    }
  }
}
