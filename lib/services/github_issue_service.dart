import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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

  /// Posts an issue to the GitHub API and returns the issue URL.
  ///
  /// Throws [IssueSubmissionException] on failure. On web this throws
  /// [UnsupportedError] because direct GitHub API calls are not supported.
  Future<String> submitIssue({
    required String title,
    required String body,
    String? label,
    List<List<int>> screenshotBytesList = const [],
    bool fromFlush = false,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('GitHub API submissions are not supported on web');
    }

    if (AppConfig.feedbackToken.isEmpty) {
      logError('FEEDBACK_TOKEN is empty — in-app feedback will fail');
      throw const IssueSubmissionException(
        'Feedback token is not configured.',
      );
    }

    if (!fromFlush && !_canSubmit()) {
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
            fromFlush: true,
          );
          await _queueDao.delete(dbInstance, id);
          await Future<void>.delayed(const Duration(milliseconds: 200));
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
    const maxBody = 200 * 1024;
    final buffer = StringBuffer()..writeln(description);

    for (var i = 0; i < screenshotBytesList.length; i++) {
      final bytes = screenshotBytesList[i];
      if (bytes.isEmpty) continue;

      Uint8List webpBytes;
      try {
        webpBytes = await compute(
          _encodeWebP,
          Uint8List.fromList(bytes),
        ).timeout(const Duration(seconds: 15));
      } on TimeoutException {
        logWarning('Screenshot ${i + 1} encoding timed out');
        continue;
      } on Exception {
        logWarning('Screenshot ${i + 1} encoding failed');
        continue;
      }
      if (webpBytes.isEmpty) continue;

      final url = await _uploadToCatbox(webpBytes);
      if (url != null) {
        buffer
          ..writeln()
          ..writeln('![screenshot]($url)');
      } else {
        logWarning('Screenshot upload failed, using base64 fallback');
        final base64Str = base64Encode(webpBytes);
        final pendingBlock =
            '\n<details>\n<summary>Screenshot (WebP base64)</summary>\n\n'
            '```\n$base64Str\n```\n\n</details>\n';
        if (buffer.length + pendingBlock.length > maxBody) {
          logWarning(
            'Skipping screenshot ${i + 1} base64: body would exceed '
            'size limit',
          );
          continue;
        }
        buffer.write(pendingBlock);
      }
    }

    return buffer.toString();
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

  Future<String> _saveScreenshot(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final feedbackDir = Directory('${dir.path}/feedback_queue');
    if (!await feedbackDir.exists()) {
      await feedbackDir.create(recursive: true);
    }
    final filename =
        '${DateTime.now().millisecondsSinceEpoch}_${bytes.hashCode}.webp';
    final file = File('${feedbackDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
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

  /// Uploads [webpBytes] to catbox.moe and returns the hosted URL.
  ///
  /// Returns `null` if the upload fails. Catbox.moe is a free, anonymous
  /// file host that requires no API key. The uploaded URL is permanent.
  Future<String?> _uploadToCatbox(Uint8List webpBytes) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://catbox.moe/user/api.php'),
        );
        request.fields['reqType'] = 'fileupload';
        request.fields['filename'] = 'screenshot.webp';
        request.files.add(
          http.MultipartFile.fromBytes(
            'fileToUpload',
            webpBytes,
            filename: 'screenshot.webp',
          ),
        );

        final streamedResponse = await _httpClient
            .send(request)
            .timeout(const Duration(seconds: 30));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 &&
            response.body.startsWith('https://')) {
          final url = response.body.trim();
          logInfo('Screenshot uploaded to catbox.moe: $url');
          return url;
        }
        logWarning(
          'Catbox.moe upload failed: ${response.statusCode} '
          '(attempt ${attempt + 1})',
        );
      } on Object catch (e) {
        logWarning(
          'Catbox.moe upload error: $e (attempt ${attempt + 1})',
        );
      }
    }
    return null;
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

/// Encodes a screenshot to a resized WebP byte array.
///
/// Runs in a background isolate via [compute]. Decodes any supported
/// image format (PNG, JPEG, WebP, etc.), resizes to a maximum width
/// of 800 pixels, and re-encodes as WebP at quality 70 for compact
/// file sizes suitable for upload.
Uint8List _encodeWebP(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return Uint8List(0);

  var resized = decoded;
  if (resized.width > 800) {
    resized = img.copyResize(resized, width: 800);
  }

  return Uint8List.fromList(img.encodeWebP(resized));
}
