import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads `assets/india_states_cities.json` into a `{state: [cities]}`
/// map.
///
/// Extracted out of `Step1ContactInfo` (registration flow), which had
/// this exact parsing logic inlined as a private method. The Branch
/// Create/Edit form needs the same State → City data for its own
/// address fields, so rather than copy-pasting that block a second
/// time, it's pulled out here as the one shared place that knows how
/// to read this asset. `Step1ContactInfo` itself is left untouched
/// (out of scope for the Branch module, and safer not to touch a
/// working registration flow) — this is purely additive.
class IndiaStatesCitiesService {
  IndiaStatesCitiesService._();

  static Map<String, List<String>>? _cache;

  /// Returns the cached map after the first successful load.
  static Future<Map<String, List<String>>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final String jsonStr =
        await rootBundle.loadString('assets/india_states_cities.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final List<dynamic> rawStates = data['states'] as List<dynamic>;

    final map = <String, List<String>>{};
    for (final entry in rawStates) {
      final stateEntry = entry as Map<String, dynamic>;
      final name = stateEntry['state'] as String;
      final cities = List<String>.from(stateEntry['cities'] as List);
      map[name] = cities;
    }

    _cache = map;
    return map;
  }
}
