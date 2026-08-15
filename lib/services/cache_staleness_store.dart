import 'package:shared_preferences/shared_preferences.dart';

/// Tracks the last time the device product cache was refreshed.
///
/// The timestamp is persisted in [SharedPreferences] so the background
/// refresh decision survives app restarts without a database round trip.
/// It previously lived in the firebase_cache_meta table; the device-only
/// cache policy keeps it in preferences instead.
class CacheStalenessStore {
  /// Creates a [CacheStalenessStore] backed by the given prefs future.
  ///
  /// The prefs future is resolved lazily on first use so the store can be
  /// constructed synchronously in a Riverpod provider. The now clock is an
  /// injectable function for deterministic tests and defaults to
  /// [DateTime.now].
  CacheStalenessStore(this._prefsFuture, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Preference key holding the last refresh time in epoch milliseconds.
  static const String _lastRefreshKey = 'last_product_refresh_ms';

  final Future<SharedPreferences> _prefsFuture;
  final DateTime Function() _now;

  /// Records the current time as the last successful product refresh.
  Future<void> recordRefresh() async {
    final prefs = await _prefsFuture;
    await prefs.setInt(_lastRefreshKey, _now().millisecondsSinceEpoch);
  }

  /// Returns the stored last-refresh timestamp, or null when no refresh has
  /// ever been recorded.
  Future<DateTime?> lastRefresh() async {
    final prefs = await _prefsFuture;
    final raw = prefs.getInt(_lastRefreshKey);
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }

  /// Returns true when no refresh was ever recorded or the last refresh is
  /// older than [overdueAfter]. Exactly at the boundary the cache is
  /// considered overdue.
  Future<bool> isOverdue(Duration overdueAfter) async {
    final last = await lastRefresh();
    if (last == null) return true;
    final cutoff = _now().subtract(overdueAfter);
    return !last.isAfter(cutoff);
  }
}
