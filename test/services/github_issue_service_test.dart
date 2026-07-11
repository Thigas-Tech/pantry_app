/// @file GithubIssueService unit tests.
///
/// Tests for issue submission, rate limiting, offline queue management,
/// screenshot processing (WebP encoding + Imgur upload), and duplicate
/// detection. HTTP calls are mocked with [MockHttpClient],
/// SharedPreferences with [SharedPreferences.setMockInitialValues].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/services/github_issue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
    registerFallbackValue(<String, String>{});
    registerFallbackValue('');
  });

  group('GithubIssueService', () {
    late MockHttpClient mockHttp;
    late GithubIssueService service;

    setUp(() async {
      dotenv.loadFromString(
        isOptional: true,
        mergeWith: {'FEEDBACK_TOKEN': 'test-token-for-ci'},
      );
      SharedPreferences.setMockInitialValues({});
      await GithubIssueService.initPreferences();
      mockHttp = MockHttpClient();
      service = GithubIssueService(httpClient: mockHttp);
    });

    tearDown(() {
      service.dispose();
    });

    /// Verifies the service can be constructed with default dependencies.
    test('can be instantiated with defaults', () {
      final s = GithubIssueService();
      expect(s, isA<GithubIssueService>());
      s.dispose();
    });

    group('submitIssue', () {
      /// Verifies a successful 201 response returns the issue URL.
      test('returns html_url on 201', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'html_url': 'https://github.com/owner/repo/issues/1'}),
            201,
          ),
        );

        final url = await service.submitIssue(
          title: 'Test',
          body: 'Description',
          label: 'bug',
        );
        expect(url, 'https://github.com/owner/repo/issues/1');
      });

      /// Verifies the request body includes both the type label and
      /// [from-app] when a type label is provided.
      test('includes type label and from-app label when type is set', () async {
        final mockHttp2 = MockHttpClient();
        final yesterday = DateTime.now()
            .subtract(const Duration(hours: 24))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'feedback_last_submit': yesterday,
          'feedback_daily_count': 0,
        });
        await GithubIssueService.initPreferences();
        final svc = GithubIssueService(httpClient: mockHttp2);
        String? capturedBody;
        when(
          () => mockHttp2.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((invocation) async {
          capturedBody = invocation.namedArguments[#body] as String;
          return http.Response(
            jsonEncode({'html_url': 'https://github.com/owner/repo/issues/1'}),
            201,
          );
        });

        await svc.submitIssue(
          title: 'Test',
          body: 'Description',
          label: 'bug',
        );
        final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
        final labels = body['labels'] as List<dynamic>;
        expect(labels, contains('bug'));
        expect(labels, contains('from-app'));

        svc.dispose();
      });

      /// Verifies the request body includes only [from-app] when no
      /// type label is provided (general feedback).
      test('includes only from-app label when no type label', () async {
        final mockHttp3 = MockHttpClient();
        final yesterday = DateTime.now()
            .subtract(const Duration(hours: 24))
            .millisecondsSinceEpoch;
        SharedPreferences.setMockInitialValues({
          'feedback_last_submit': yesterday,
          'feedback_daily_count': 0,
        });
        await GithubIssueService.initPreferences();
        final svc = GithubIssueService(httpClient: mockHttp3);
        String? capturedBody;
        when(
          () => mockHttp3.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((invocation) async {
          capturedBody = invocation.namedArguments[#body] as String;
          return http.Response(
            jsonEncode({'html_url': 'https://github.com/owner/repo/issues/1'}),
            201,
          );
        });

        await svc.submitIssue(
          title: 'No label',
          body: 'General feedback',
        );
        final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
        final labels = body['labels'] as List<dynamic>;
        expect(labels, contains('from-app'));
        expect(labels.length, 1);

        svc.dispose();
      });

      /// Verifies a timeout throws [IssueSubmissionException].
      test('throws on timeout', () {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenThrow(TimeoutException('timeout'));

        expect(
          () => service.submitIssue(title: 'Test', body: 'Body'),
          throwsA(isA<IssueSubmissionException>()),
        );
      });

      /// Verifies a network error throws [IssueSubmissionException].
      test('throws on network error', () {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenThrow(http.ClientException('connection refused'));

        expect(
          () => service.submitIssue(title: 'Test', body: 'Body'),
          throwsA(isA<IssueSubmissionException>()),
        );
      });

      /// Verifies a non-201 status throws [IssueSubmissionException].
      test('throws on non-201 response', () {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"message":"Bad request"}', 400),
        );

        expect(
          () => service.submitIssue(title: 'Test', body: 'Body'),
          throwsA(isA<IssueSubmissionException>()),
        );
      });

      /// Verifies screenshots are processed (decoded, resized, encoded
      /// as WebP) and when no [IMGUR_CLIENT_ID] is configured the
      /// image is silently skipped without embedding raw bytes in the
      /// issue body.
      test(
        'processes screenshots to WebP and skips on missing Imgur client',
        () async {
          final image = img.Image(width: 2000, height: 2000);
          final rawBytes = Uint8List.fromList(img.encodePng(image));
          final screenshots = <List<int>>[rawBytes];

          String? capturedBody;
          when(
            () => mockHttp.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((invocation) async {
            capturedBody = invocation.namedArguments[#body] as String;
            return http.Response(
              jsonEncode({
                'html_url': 'https://github.com/owner/repo/issues/1',
              }),
              201,
            );
          });

          await service.submitIssue(
            title: 'Screenshot test',
            body: 'Description',
            label: 'bug',
            screenshotBytesList: screenshots,
          );

          expect(capturedBody, isNotNull);
          expect(capturedBody, isNot(contains(base64Encode(rawBytes))));
          expect(capturedBody, isNot(contains('<details>')));
          expect(capturedBody, isNot(contains('![screenshot]')));
          expect(capturedBody, contains('Description'));
        },
      );

      /// Verifies body stays under GitHub API size limit even with
      /// large screenshots.
      test(
        'body size is within GitHub API limits with large screenshots',
        () async {
          final image = img.Image(width: 2000, height: 2000);
          final rawBytes = Uint8List.fromList(img.encodePng(image));
          final screenshots = <List<int>>[rawBytes];

          String? capturedBody;
          when(
            () => mockHttp.post(
              any(),
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((invocation) async {
            capturedBody = invocation.namedArguments[#body] as String;
            return http.Response(
              jsonEncode({
                'html_url': 'https://github.com/owner/repo/issues/1',
              }),
              201,
            );
          });

          await service.submitIssue(
            title: 'Large',
            body: 'Description',
            label: 'bug',
            screenshotBytesList: screenshots,
          );

          expect(capturedBody!.length, lessThan(256 * 1024));
        },
      );

      /// Verifies that when no screenshots are attached, the body does not
      /// contain any image markdown or details blocks.
      test('body has no image data when no screenshots provided', () async {
        String? capturedBody;
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((invocation) async {
          capturedBody = invocation.namedArguments[#body] as String;
          return http.Response(
            jsonEncode({
              'html_url': 'https://github.com/owner/repo/issues/1',
            }),
            201,
          );
        });

        await service.submitIssue(
          title: 'No screenshot test',
          body: 'Plain description',
          label: 'bug',
        );

        expect(capturedBody, isNot(contains('data:image')));
        expect(capturedBody, isNot(contains('<details>')));
        expect(capturedBody, contains('No screenshot test'));
        expect(capturedBody, contains('Plain description'));
      });
    });

    group('isDuplicate', () {
      /// Verifies [isDuplicate] returns false when no previous submissions
      /// exist with the same content hash.
      test('returns false for new content', () {
        expect(
          service.isDuplicate('New title', 'New body'),
          isFalse,
        );
      });

      /// Verifies [isDuplicate] returns false for empty strings.
      test('returns false for empty strings', () {
        expect(service.isDuplicate('', ''), isFalse);
      });
    });

    group('IssueSubmissionException', () {
      /// Verifies the exception message and toString output.
      test('has a message', () {
        const ex = IssueSubmissionException('Test error');
        expect(ex.message, 'Test error');
        expect(ex.toString(), contains('Test error'));
      });
    });

    group('submitIssue rate limiting', () {
      /// Verifies [submitIssue] throws [IssueSubmissionException] when
      /// called within 60 seconds of the last submission.
      test('respects 60-second cooldown', () async {
        final recent = DateTime.now().subtract(const Duration(seconds: 30));
        SharedPreferences.setMockInitialValues({
          'feedback_last_submit': recent.millisecondsSinceEpoch,
        });
        await GithubIssueService.initPreferences();

        final svc = GithubIssueService(httpClient: mockHttp);
        expect(
          () => svc.submitIssue(title: 'Rapid', body: 'Rapid'),
          throwsA(isA<IssueSubmissionException>()),
        );
        svc.dispose();
      });

      /// Verifies the daily limit of 5 is enforced even on the
      /// first-ever submission (when [feedback_daily_start] is 0).
      test('enforces daily limit on first submission', () async {
        SharedPreferences.setMockInitialValues({
          'feedback_daily_count': 5,
          'feedback_daily_start': 0,
        });
        await GithubIssueService.initPreferences();

        final svc = GithubIssueService(httpClient: mockHttp);
        expect(
          () => svc.submitIssue(title: 'First Day', body: 'Body'),
          throwsA(isA<IssueSubmissionException>()),
        );
        svc.dispose();
      });

      /// Verifies the daily limit resets when the day changes
      /// (using local time, not UTC).
      test('daily limit resets on new local day', () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        SharedPreferences.setMockInitialValues({
          'feedback_daily_count': 5,
          'feedback_daily_start': yesterday.millisecondsSinceEpoch,
          'feedback_last_submit': DateTime.now()
              .subtract(const Duration(seconds: 90))
              .millisecondsSinceEpoch,
        });
        await GithubIssueService.initPreferences();

        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'html_url': 'https://github.com/owner/repo/issues/1'}),
            201,
          ),
        );

        final svc = GithubIssueService(httpClient: mockHttp);
        final url = await svc.submitIssue(
          title: 'New Day',
          body: 'Body',
        );
        expect(url, 'https://github.com/owner/repo/issues/1');
        svc.dispose();
      });
    });

    group('submitIssue HTTP error handling', () {
      /// Verifies a 401 response produces a token-specific error message.
      test('401 produces token invalid message', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"message":"Bad credentials"}', 401),
        );

        try {
          await service.submitIssue(title: 'Test', body: 'Body');
          fail('Should have thrown');
        } on IssueSubmissionException catch (e) {
          expect(e.message, contains('invalid or expired'));
        }
      });

      /// Verifies a 403 response produces a permission-specific message.
      test('403 produces permission denied message', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"message":"Forbidden"}', 403),
        );

        try {
          await service.submitIssue(title: 'Test', body: 'Body');
          fail('Should have thrown');
        } on IssueSubmissionException catch (e) {
          expect(e.message, contains('Permission denied'));
        }
      });

      /// Verifies a 429 response produces a rate-limit-specific message.
      test('429 produces rate limit message', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            '{"message":"API rate limit exceeded"}',
            429,
          ),
        );

        try {
          await service.submitIssue(title: 'Test', body: 'Body');
          fail('Should have thrown');
        } on IssueSubmissionException catch (e) {
          expect(e.message, contains('rate limit'));
        }
      });

      /// Verifies a 503 response produces an unavailability message.
      test('503 produces unavailable message', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response('{"message":"Server Error"}', 503),
        );

        try {
          await service.submitIssue(title: 'Test', body: 'Body');
          fail('Should have thrown');
        } on IssueSubmissionException catch (e) {
          expect(e.message, contains('temporarily unavailable'));
        }
      });
    });

    group('submitIssue _recordSubmission', () {
      /// Verifies that [submitIssue] awaits [_recordSubmission] so the
      /// daily count is updated before the next submission attempt.
      test('records submission before returning', () async {
        when(
          () => mockHttp.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({'html_url': 'https://github.com/owner/repo/issues/1'}),
            201,
          ),
        );

        await service.submitIssue(title: 'Test', body: 'Body');

        final prefs = await SharedPreferences.getInstance();
        final count = prefs.getInt('feedback_daily_count') ?? 0;
        expect(count, 1);
      });
    });
  });
}
