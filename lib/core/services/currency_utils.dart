class CurrencyUtils {
  CurrencyUtils._(); // prevents instantiation

  /// Formats [value] using the Indian Cr/L/K abbreviation style (kept
  /// hardcoded on purpose — this product targets the Indian market),
  /// with [symbol] as the only dynamic piece. Callers should pass
  /// `meta.currency_symbol` from the dashboard response instead of
  /// relying on the default; the default only exists so pre-existing
  /// call sites that don't have a dynamic symbol handy keep compiling
  /// unchanged.
  static String format(double value, {String symbol = '₹'}) {
    if (value >= 10000000) {
      return '$symbol${(value / 10000000).toStringAsFixed(1)}Cr';
    }
    if (value >= 100000) {
      return '$symbol${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${value.toStringAsFixed(0)}';
  }
}
