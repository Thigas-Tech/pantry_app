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
