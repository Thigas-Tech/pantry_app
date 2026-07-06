import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/github_issue_service.dart';

void main() {
  group('GithubIssueService', () {
    late GithubIssueService service;

    setUp(() {
      service = GithubIssueService();
    });

    tearDown(() {
      service.dispose();
    });

    test('can be instantiated', () {
      expect(service, isA<GithubIssueService>());
    });

    group('rate limiting', () {
      test('isDuplicate returns false for new content', () {
        expect(
          service.isDuplicate('Test title 12345', 'Test body 67890'),
          isFalse,
        );
      });

      test('isDuplicate returns false for empty strings', () {
        expect(service.isDuplicate('', ''), isFalse);
      });
    });
  });

  group('IssueSubmissionException', () {
    test('has a message', () {
      const ex = IssueSubmissionException('Test error');
      expect(ex.message, 'Test error');
      expect(ex.toString(), contains('Test error'));
    });
  });
}
