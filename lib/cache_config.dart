/// Device cache policy constants.
///
/// These values define how long the device-local product cache is kept and
/// when the background inventory refresh should fire. There is no
/// intermediate server-side cache; the local SQLite database is the only
/// cache and expired entries are flushed periodically.
library;

/// Maximum age of an API-fetched cached product before it is flushed from
/// the device. Two months.
///
/// Products whose lastSynced timestamp is older than this are removed by
/// DatabaseHelper.flushExpiredCachedProducts and re-fetched on the next
/// access or background refresh.
const Duration productCacheMaxAge = Duration(days: 60);

/// Number of days after which the cached product data is considered stale
/// and a batch inventory refresh should fire.
const int inventoryRefreshOverdueDays = 5;
