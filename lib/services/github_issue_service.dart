import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:pantry_app/config.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/database/feedback_queue_dao.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Submits feedback as GitHub Issues and manages an offline queue.
///
/// On platforms that support HTTP (Android, iOS, desktop), issues are
/// posted to the GitHub Issues API with the developer's PAT. When the
/// device is offline the issue is stored in the `feedback_queue` SQLite
/// table and flushed automatically when connectivity is restored.
///
/// On web the service falls back to a `mailto:` URI because sqflite and
/// direct HTTP calls to authenticated GitHub endpoints are not practical.
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

  /// Posts an issue to the GitHub API and returns the issue URL.
  ///
  /// Throws [IssueSubmissionException] on failure. On web this throws
  /// [UnsupportedError] because direct GitHub API calls are not supported.
  Future<String> submitIssue({
    required String title,
    required String body,
    String? label,
    List<List<int>> screenshotBytesList = const [],
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('GitHub API submissions are not supported on web');
    }

    if (!_canSubmit()) {
      throw const IssueSubmissionException(
        'Rate limit reached. Try again later.',
      );
    }

    final tokenLength = AppConfig.feedbackToken.length;
    logInfo(
      'submitIssue: title="$title" tokenLength=$tokenLength '
      'repo=${AppConfig.githubOwner}/${AppConfig.githubRepo} '
      'screenshots=${screenshotBytesList.length}',
    );

    final fullBody = await _buildBody(body, screenshotBytesList);

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
              'body': fullBody,
              if (label != null) 'labels': [label],
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
      _recordSubmission(title, body);
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

  /// Queues an issue for offline submission.
  ///
  /// Each set of screenshot bytes is saved to a separate temporary file.
  /// Paths are stored as a JSON-encoded list in the queue row.
  /// On web this is a no-op.
  Future<void> queueOffline({
    required String title,
    required String body,
    String? label,
    List<List<int>> screenshotBytesList = const [],
  }) async {
    if (kIsWeb) return;

    String? screenshotPathsJson;
    if (screenshotBytesList.isNotEmpty) {
      final paths = <String>[];
      for (final bytes in screenshotBytesList) {
        paths.add(await _saveScreenshot(bytes));
      }
      screenshotPathsJson = jsonEncode(paths);
    }

    final dbInstance = await _dbHelper.database;
    await _queueDao.insert(
      dbInstance,
      title: title,
      body: body,
      label: label,
      screenshotPath: screenshotPathsJson,
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
            const Duration(seconds: 60)) {
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
        final screenshotPathsJson = row['screenshot_path'] as String?;
        final retryCount = row['retry_count'] as int;

        final screenshotBytesList = <List<int>>[];
        if (screenshotPathsJson != null) {
          try {
            final paths = (jsonDecode(screenshotPathsJson) as List<dynamic>)
                .cast<String>();
            for (final path in paths) {
              final file = File(path);
              if (await file.exists()) {
                screenshotBytesList.add(await file.readAsBytes());
              }
            }
          } on Exception {
            // best-effort
          }
        }

        try {
          await submitIssue(
            title: title,
            body: body,
            label: label,
            screenshotBytesList: screenshotBytesList,
          );
          await _queueDao.delete(dbInstance, id);
          if (screenshotPathsJson != null) {
            try {
              final paths = (jsonDecode(screenshotPathsJson) as List<dynamic>)
                  .cast<String>();
              for (final path in paths) {
                try {
                  await File(path).delete();
                } on Exception {
                  // best-effort cleanup
                }
              }
            } on Exception {
              // best-effort cleanup
            }
          }
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

  /// Returns `true` if the user has not exceeded rate limits.
  bool _canSubmit() {
    try {
      final prefs = _prefs;
      if (prefs == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch;
      final lastSubmit = prefs.getInt('feedback_last_submit') ?? 0;
      if (now - lastSubmit < 60000) return false;

      final todayCount = prefs.getInt('feedback_daily_count') ?? 0;
      final todayStart = prefs.getInt('feedback_daily_start') ?? 0;

      if (_isSameDay(todayStart, now)) {
        if (todayCount >= 5) return false;
      }

      return true;
    } on Exception {
      return true;
    }
  }

  /// Records a successful submission for rate limit tracking.
  void _recordSubmission(String title, String body) {
    try {
      final prefs = _prefs;
      if (prefs == null) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      unawaited(prefs.setInt('feedback_last_submit', now));

      final todayStart = prefs.getInt('feedback_daily_start') ?? 0;
      final todayCount = prefs.getInt('feedback_daily_count') ?? 0;
      if (_isSameDay(todayStart, now)) {
        unawaited(prefs.setInt('feedback_daily_count', todayCount + 1));
      } else {
        unawaited(
          Future.wait([
            prefs.setInt('feedback_daily_start', now),
            prefs.setInt('feedback_daily_count', 1),
          ]),
        );
      }

      final hash = _hashIssue(title, body);
      unawaited(prefs.setString('feedback_hash_$hash', now.toString()));
    } on Exception {
      // best-effort
    }
  }

  /// Returns `true` if an identical issue was submitted in the last 24 hours.
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

  Future<String> _buildBody(
    String description,
    List<List<int>> screenshotBytesList,
  ) async {
    final buffer = StringBuffer()..writeln(description);

    for (final bytes in screenshotBytesList) {
      if (bytes.isNotEmpty) {
        final base64 = await encodeScreenshotBase64(Uint8List.fromList(bytes));
        if (base64.isEmpty) continue;
        buffer
          ..writeln()
          ..writeln('![screenshot](data:image/png;base64,$base64)');
      }
    }

    return buffer.toString();
  }

  String _parseGitHubError(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['message'] as String? ?? 'Unknown error';
    } on Exception {
      return 'HTTP ${response.statusCode}';
    }
  }

  Future<String> _saveScreenshot(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final feedbackDir = Directory('${dir.path}/feedback_queue');
    if (!await feedbackDir.exists()) {
      await feedbackDir.create(recursive: true);
    }
    final filename =
        '${DateTime.now().millisecondsSinceEpoch}_${bytes.hashCode}.png';
    final file = File('${feedbackDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  String _hashIssue(String title, String body) {
    return '${title.hashCode}_${body.hashCode}';
  }

  bool _isSameDay(int timestamp1, int timestamp2) {
    final d1 = DateTime.fromMillisecondsSinceEpoch(timestamp1, isUtc: true);
    final d2 = DateTime.fromMillisecondsSinceEpoch(timestamp2, isUtc: true);
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
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

/// Encodes raw bytes to a base64 data URI string.
///
/// Runs in a background isolate via [compute].
Future<String> encodeScreenshotBase64(Uint8List bytes) {
  return compute(_encodeBase64, bytes);
}

String _encodeBase64(Uint8List bytes) {
  final decoded = img.decodePng(bytes);
  if (decoded == null) return '';

  var resized = decoded;
  if (resized.width > 1024) {
    resized = img.copyResize(resized, width: 1024);
  }

  final encoded = img.encodePng(resized);
  return base64Encode(encoded);
}
