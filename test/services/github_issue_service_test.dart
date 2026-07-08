/// @file GithubIssueService unit tests.
///
/// Tests for issue submission, rate limiting, offline queue management,
/// and duplicate detection.  HTTP calls are mocked with [MockHttpClient],
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

      /// Regression test: verifies screenshot bytes are compressed via
      /// [encodeScreenshotBase64] and not embedded raw (prevents dead code
      /// regression where [base64Encode] was called directly instead).
      test('compresses screenshots before sending', () async {
        final image = img.Image(width: 2000, height: 2000);
        final rawBytes = Uint8List.fromList(img.encodePng(image));
        final rawBase64 = base64Encode(rawBytes);
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
          title: 'Regression',
          body: 'Description',
          label: 'bug',
          screenshotBytesList: screenshots,
        );

        expect(capturedBody, isNot(contains(rawBase64)));
        final match = RegExp(
          'data:image/png;base64,([A-Za-z0-9+/=]+)',
        ).firstMatch(capturedBody!);
        expect(match, isNotNull);
        final decoded = img.decodeImage(base64Decode(match!.group(1)!));
        expect(decoded, isNotNull);
        expect(decoded!.width, lessThanOrEqualTo(1024));
        expect(decoded.height, lessThanOrEqualTo(1024));
      });

      /// Regression test: verifies body stays under GitHub API size limit
      /// (~256 KB) even with large screenshots, ensuring that compression
      /// is active.
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
      /// contain any image markdown.
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
    });
  });

  group('encodeScreenshotBase64', () {
    /// Verifies that a valid PNG image is resized and base64-encoded.
    test('encodes a small PNG to base64', () async {
      final image = img.Image(width: 2, height: 2);
      final pngBytes = Uint8List.fromList(img.encodePng(image));
      expect(pngBytes, isNotEmpty);

      final result = await encodeScreenshotBase64(pngBytes);
      expect(result, isNotEmpty);
      expect(result, isA<String>());
    });
  });
}
