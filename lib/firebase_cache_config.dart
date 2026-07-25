/// Default interval (ms) between Firestore cache refreshes for barcoded
/// products. 180 days — matches Firestore free-tier write limits.
const int productRefreshIntervalMs = 180 * 24 * 60 * 60 * 1000;

/// Default interval (ms) between Firestore cache refreshes for produce
/// entries. 180 days — matches Firestore free-tier write limits.
const int produceRefreshIntervalMs = 180 * 24 * 60 * 60 * 1000;

/// Default interval (ms) between Firestore cache refreshes for recipe
/// entries. 180 days — matches Firestore free-tier write limits.
const int recipeRefreshIntervalMs = 180 * 24 * 60 * 60 * 1000;

/// Number of days after which the local product cache is considered stale
/// and a batch inventory refresh should fire.
const int inventoryRefreshOverdueDays = 5;
