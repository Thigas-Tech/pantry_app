import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pantry_app/config.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/feedback_queue_dao.dart';
import 'package:pantry_app/services/device_id.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Submits feedback as GitHub Issues and manages an offline queue.
///
/// On platforms that support HTTP (Android, iOS, desktop), issues are
/// posted either through the serverless feedback proxy (release builds,
/// configured by [AppConfig.feedbackProxyUrl]) or directly to the GitHub
/// Issues API with the developer's PAT (development only). When the
/// device is offline the issue is stored in the feedback_queue SQLite
/// table and flushed automatically when connectivity is restored.
///
/// On web, issue submissions are not supported;
/// [GithubIssueService.submitIssue] throws [UnsupportedError].
class GithubIssueService {
  /// Creates a [GithubIssueService].
  ///
  /// All dependencies can be injected for testing.  When omitted they
  /// default to live instances (real HTTP client, real database, etc.).
  GithubIssueService({
    http.Client? httpClient,
    DatabaseHelper? databaseHelper,
    FeedbackQueueDao? feedbackQueueDao,
  }) : _httpClient = httpClient ?? http.Client(),
       _dbHelper = databaseHelper ?? DatabaseHelper(),
       _queueDao = feedbackQueueDao ?? const FeedbackQueueDao();

  final http.Client _httpClient;
  final DatabaseHelper _dbHelper;
  final FeedbackQueueDao _queueDao;
  bool _isFlushing = false;
  DateTime? _lastFlushTime;

  /// Posts an issue to the feedback proxy or GitHub API and returns the
  /// issue URL.
  ///
  /// When [AppConfig.feedbackProxyUrl] is set, the issue is POSTed to the
  /// proxy (which holds the GitHub PAT and enforces server-side rate
  /// limits). Otherwise it is posted directly to the GitHub API with the
  /// development [AppConfig.feedbackToken]. Throws
  /// [IssueSubmissionException] on failure; throws [IssueRateLimitException]
  /// when the proxy rejects the request for rate limiting. On web this
  /// throws [UnsupportedError] because submissions are not supported.
  Future<String> submitIssue({
    required String title,
    required String body,
    String? label,
    bool fromFlush = false,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('GitHub API submissions are not supported on web');
    }

    if (AppConfig.feedbackProxyUrl.isEmpty && AppConfig.feedbackToken.isEmpty) {
      logError('Feedback is not configured (no proxy URL or token)');
      throw const IssueSubmissionException(
        'Feedback is not configured.',
      );
    }

    if (!fromFlush && !_canSubmit()) {
      throw const IssueSubmissionException(
        'Rate limit reached. Try again later.',
      );
    }

    if (AppConfig.feedbackProxyUrl.isNotEmpty) {
      return _submitViaProxy(
        title: title,
        body: body,
        label: label,
        fromFlush: fromFlush,
      );
    }

    final tokenLength = AppConfig.feedbackToken.length;
    logInfo(
      'submitIssue: title="$title" tokenLength=$tokenLength '
      'repo=${AppConfig.githubOwner}/${AppConfig.githubRepo}',
    );

    late final http.Response response;
    try {
      response = await _httpClient
          .post(
            Uri.parse(
              'https://api.github.com/repos/'
              '${AppConfig.githubOwner}/${AppConfig.githubRepo}/issues',
            ),
            headers: _headers(),
            body: jsonEncode({
              'title': title,
              'body': body,
              'labels': [
                ?label,
                'from-app',
              ],
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const IssueSubmissionException('Request timed out');
    } on http.ClientException catch (e) {
      throw IssueSubmissionException('Network error: ${e.message}');
    }

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['html_url'] as String;
      if (!fromFlush) {
        await _recordSubmission(title, body);
      }
      logInfo('Issue created: $url');
      return url;
    }

    final message = _parseGitHubError(response);
    logError(
      'GitHub API error ${response.statusCode}: $message '
      '(tokenLength=${AppConfig.feedbackToken.length})',
    );
    throw IssueSubmissionException(message);
  }

  /// Submits an issue through the serverless feedback proxy.
  ///
  /// The proxy owns the GitHub PAT (never shipped in the app) and enforces
  /// per-device rate limits. The device id is sent as the X-Device-Id
  /// header so the server can key its counters; no credentials are sent.
  Future<String> _submitViaProxy({
    required String title,
    required String body,
    required bool fromFlush,
    String? label,
  }) async {
    final deviceId = await DeviceId.get();
    late final http.Response response;
    try {
      response = await _httpClient
          .post(
            Uri.parse(AppConfig.feedbackProxyUrl),
            headers: {
              'Content-Type': 'application/json',
              'X-Device-Id': deviceId,
              'User-Agent': 'PantryApp/1.0',
            },
            body: jsonEncode({
              'title': title,
              'body': body,
              if (label != null && label.isNotEmpty) 'label': label,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const IssueSubmissionException('Request timed out');
    } on http.ClientException catch (e) {
      throw IssueSubmissionException('Network error: ${e.message}');
    }

    if (response.statusCode == 201) {
      if (!fromFlush) {
        await _recordSubmission(title, body);
      }
      final url = _jsonField(response, 'url');
      logInfo('Issue created via proxy: $url');
      return url;
    }

    if (response.statusCode == 429) {
      throw const IssueRateLimitException(
        'Rate limit reached. Try again later.',
      );
    }

    final message = _parseProxyError(response);
    logError('Feedback proxy error ${response.statusCode}: $message');
    throw IssueSubmissionException(message);
  }

  /// Extracts a JSON string field from [response], or the empty string.
  String _jsonField(http.Response response, String field) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data[field] as String? ?? '';
    } on Exception {
      return '';
    }
  }

  /// Maps a proxy error status to a human-readable message.
  String _parseProxyError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        return 'Feedback could not be submitted (invalid request)';
      case 502:
      case 503:
      case 504:
        return 'Feedback service is temporarily unavailable. Try again later';
      default:
        return 'Feedback could not be submitted (HTTP ${response.statusCode})';
    }
  }

  /// Queues an issue for offline submission.
  ///
  /// On web this is a no-op.
  Future<void> queueOffline({
    required String title,
    required String body,
    String? label,
  }) async {
    if (kIsWeb) return;

    final dbInstance = await _dbHelper.database;
    await _queueDao.insert(
      dbInstance,
      title: title,
      body: body,
      label: label,
    );
    logInfo('Issue queued for offline submission: $title');
  }

  /// Flushes all queued issues to GitHub.
  ///
  /// Returns the number of successfully submitted and failed issues.
  /// Skips if a flush is already in progress.
  Future<({int submitted, int failed})> flushQueue() async {
    if (_isFlushing) return (submitted: 0, failed: 0);

    if (_lastFlushTime != null &&
        DateTime.now().difference(_lastFlushTime!) <
            const Duration(seconds: 5)) {
      return (submitted: 0, failed: 0);
    }

    _isFlushing = true;
    _lastFlushTime = DateTime.now();
    var submitted = 0;
    var failed = 0;

    late final Database dbInstance;

    try {
      dbInstance = await _dbHelper.database;
      final pending = await _queueDao.getAllPending(dbInstance);
      if (pending.isEmpty) {
        logInfo('No queued issues to flush');
        return (submitted: 0, failed: 0);
      }

      logInfo('Flushing ${pending.length} queued feedback issues');

      for (final row in pending) {
        final id = row['id'] as int;
        final title = row['title'] as String;
        final body = row['body'] as String;
        final label = row['label'] as String?;
        final retryCount = row['retry_count'] as int;

        try {
          await submitIssue(
            title: title,
            body: body,
            label: label,
            fromFlush: true,
          );
          await _queueDao.delete(dbInstance, id);
          await Future<void>.delayed(const Duration(milliseconds: 200));
          submitted++;
        } on Exception {
          await _queueDao.incrementRetry(dbInstance, id);
          if (retryCount >= 2) {
            await _queueDao.markFailed(dbInstance, id);
            logWarning('Feedback issue $id failed after 3 retries');
          }
          failed++;
        }
      }
    } on Exception catch (e) {
      logError('Queue flush failed: $e');
    } finally {
      _isFlushing = false;
    }

    // Cleanup stale failed rows.
    try {
      await _queueDao.deleteStaleFailures(await _dbHelper.database);
    } on Exception catch (e) {
      logWarning('Stale failure cleanup failed: $e');
    }

    return (submitted: submitted, failed: failed);
  }

  /// Returns true if the user has not exceeded rate limits.
  bool _canSubmit() {
    try {
      final prefs = _prefs;
      if (prefs == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch;
      final lastSubmit = prefs.getInt('feedback_last_submit') ?? 0;
      if (now - lastSubmit < 60000) return false;

      final todayCount = prefs.getInt('feedback_daily_count') ?? 0;
      final todayStart = prefs.getInt('feedback_daily_start') ?? 0;

      if (todayStart == 0) {
        return todayCount < 5;
      }

      if (_isSameDay(todayStart, now)) {
        if (todayCount >= 5) return false;
      }

      return true;
    } on Exception {
      return true;
    }
  }

  /// Records a successful submission for rate limit tracking.
  Future<void> _recordSubmission(String title, String body) async {
    try {
      final prefs = _prefs;
      if (prefs == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('feedback_last_submit', now);

      final todayStart = prefs.getInt('feedback_daily_start') ?? 0;
      final todayCount = prefs.getInt('feedback_daily_count') ?? 0;
      if (todayStart != 0 && _isSameDay(todayStart, now)) {
        await prefs.setInt('feedback_daily_count', todayCount + 1);
      } else {
        await prefs.setInt('feedback_daily_start', now);
        await prefs.setInt('feedback_daily_count', 1);
      }

      final hash = _hashIssue(title, body);
      await prefs.setString('feedback_hash_$hash', now.toString());

      await _cleanupOldHashKeys(prefs, now);
    } on Exception {
      // best-effort
    }
  }

  /// Returns true if an identical issue was submitted in the last 24 hours.
  bool isDuplicate(String title, String body) {
    try {
      final prefs = _prefs;
      if (prefs == null) return false;
      final hash = _hashIssue(title, body);
      final lastSubmitted = prefs.getString('feedback_hash_$hash');
      if (lastSubmitted == null) return false;
      final lastTs = int.tryParse(lastSubmitted);
      if (lastTs == null) return false;
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastTs;
      return elapsed < const Duration(hours: 24).inMilliseconds;
    } on Exception {
      return false;
    }
  }

  /// Returns the number of pending queued issues.
  Future<int> pendingCount() async {
    try {
      final pending = await _queueDao.getAllPending(await _dbHelper.database);
      return pending.length;
    } on Exception {
      return 0;
    }
  }

  /// Disposes the underlying HTTP client.
  void dispose() {
    _httpClient.close();
  }

  SharedPreferences? get _prefs {
    // SharedPreferences must be awaited. For synchronous rate-limit checks
    // we load it lazily. The first call will be async — subsequent calls
    // reuse the cached instance.
    // In practice the check happens inside `submitIssue()` which is async,
    // so the instance is always available.
    return _cachedPrefs;
  }

  static SharedPreferences? _cachedPrefs;

  /// Must be called once at startup to initialise preferences.
  static Future<void> initPreferences() async {
    _cachedPrefs = await SharedPreferences.getInstance();
  }

  Map<String, String> _headers() {
    return {
      'Authorization': 'Bearer ${AppConfig.feedbackToken}',
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'PantryApp/1.0',
      'Content-Type': 'application/json',
    };
  }

  String _parseGitHubError(http.Response response) {
    final code = response.statusCode;
    String apiMessage;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      apiMessage = data['message'] as String? ?? '';
    } on Exception {
      apiMessage = '';
    }

    switch (code) {
      case 401:
        return 'Feedback token is invalid or expired';
      case 403:
        return apiMessage.isNotEmpty
            ? 'Permission denied: $apiMessage'
            : 'Permission denied — token may lack Issues:write scope';
      case 422:
        return apiMessage.isNotEmpty
            ? 'Validation error: $apiMessage'
            : 'Validation error (HTTP 422)';
      case 429:
        return 'GitHub API rate limit reached. Try again later';
      case 500:
      case 502:
      case 503:
        return 'GitHub is temporarily unavailable. Try again later';
      default:
        return apiMessage.isNotEmpty ? apiMessage : 'HTTP $code';
    }
  }

  String _hashIssue(String title, String body) {
    final bytes = utf8.encode('$title|$body');
    return sha256.convert(bytes).toString();
  }

  bool _isSameDay(int timestamp1, int timestamp2) {
    final d1 = DateTime.fromMillisecondsSinceEpoch(timestamp1);
    final d2 = DateTime.fromMillisecondsSinceEpoch(timestamp2);
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Future<void> _cleanupOldHashKeys(SharedPreferences prefs, int now) async {
    const maxAge = Duration(hours: 24);
    final keys = prefs.getKeys().where((k) => k.startsWith('feedback_hash_'));
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value == null) continue;
      final ts = int.tryParse(value);
      if (ts == null) continue;
      if (now - ts > maxAge.inMilliseconds) {
        await prefs.remove(key);
      }
    }
  }
}

/// Thrown when an issue submission fails.
class IssueSubmissionException implements Exception {
  /// Creates an [IssueSubmissionException] with a human-readable [message].
  const IssueSubmissionException(this.message);

  /// A human-readable description of the failure.
  final String message;

  @override
  String toString() => 'IssueSubmissionException: $message';
}

/// Thrown when the feedback proxy rejects a submission for rate limiting.
///
/// The UI shows the rate-limit message and does **not** fall back to the
/// offline queue (a server-side limit will not clear by retrying later).
class IssueRateLimitException extends IssueSubmissionException {
  /// Creates an [IssueRateLimitException] with a human-readable [message].
  const IssueRateLimitException(super.message);

  @override
  String toString() => 'IssueRateLimitException: $message';
}
