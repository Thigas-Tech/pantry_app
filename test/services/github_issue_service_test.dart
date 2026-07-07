/// @file GithubIssueService unit tests.
///
/// Tests for issue submission, rate limiting, offline queue management,
/// and duplicate detection.  HTTP calls are mocked with [MockHttpClient],
/// SharedPreferences with [SharedPreferences.setMockInitialValues].
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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
      dotenv.loadFromString(isOptional: true, mergeWith: {});
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
  });
}
