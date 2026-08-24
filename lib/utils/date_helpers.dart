/// Parses an ISO‑8601 date string (e.g. '2026-07-15') to a [DateTime].
///
/// Returns null if the string is null, empty, or cannot be parsed.
DateTime? parseExpiryDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  return DateTime.tryParse(dateString);
}

/// Whether [dateString] represents a date strictly before today (expired).
bool isExpired(String? dateString) {
  final date = parseExpiryDate(dateString);
  if (date == null) return false;
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  return date.isBefore(todayStart);
}

/// Whether [dateString] represents a date within [days] days from today
/// (not yet expired, but soon). Returns false if already expired or no date.
bool isExpiringSoon(String? dateString, int days) {
  final date = parseExpiryDate(dateString);
  if (date == null) return false;
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final threshold = todayStart.add(Duration(days: days));
  return !date.isBefore(todayStart) && date.isBefore(threshold);
}

/// Today plus the default produce shelf-life (14 days).
///
/// Used as the pre-selected expiry date for produce added in a market trip or
/// to the pantry, so fresh items get a sensible default that can still be
/// changed or cleared by the user.
DateTime defaultProduceExpiry([DateTime? now]) =>
    (now ?? DateTime.now()).add(const Duration(days: 14));

/// Formats [date] as dd/mm/yyyy (e.g. 15/06/2026).
///
/// Shared by the price history chart, the history tiles, and the product
/// detail recent-price rows so the format stays consistent.
String formatShortDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
