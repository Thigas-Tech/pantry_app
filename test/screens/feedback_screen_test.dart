/// @file FeedbackScreen widget tests.
///
/// Tests for the feedback and bug-report form.  Verifies:
///   - The screen renders without crashing.
///   - The form fields (title, description) are present.
///   - [IssueType] enum extension maps to correct GitHub labels.
///   - Online submit flow calls [GithubIssueService.submitIssue], then
///     resets the form and pops the screen.
///   - Offline submit queues the issue and pops.
///   - Online submit falling back to queue also pops.
///
/// Uses the shared `pumpApp` helper.  Providers are overridden to isolate
/// the screen from real network, storage, and service dependencies.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/github_issue_service_provider.dart';
import 'package:pantry_app/screens/feedback_screen.dart';
import 'package:pantry_app/services/github_issue_service.dart';

import '../helpers/pump_app.dart';

class MockGithubIssueService extends Mock implements GithubIssueService {}

/// Pushes [screen] as a route so that popping it can be verified.
class _SubmitShell extends StatelessWidget {
  const _SubmitShell({required this.screen});
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => screen),
          ),
          child: const Text('Open feedback'),
        ),
      ),
    );
  }
}

void main() {
  group('IssueType', () {
    /// Verifies the [IssueTypeLabel.gitHubLabel] returns the correct
    /// GitHub label for each issue type.
    test('gitHubLabel returns correct label for each type', () {
      expect(IssueType.bug.gitHubLabel(), 'bug');
      expect(IssueType.feature.gitHubLabel(), 'enhancement');
      expect(IssueType.feedback.gitHubLabel(), '');
      expect(IssueType.regression.gitHubLabel(), 'regression');
      expect(IssueType.translation.gitHubLabel(), 'translation');
    });

    /// Verifies that [IssueType.values] contains all five variants.
    test('values contains all issue types', () {
      expect(IssueType.values, contains(IssueType.bug));
      expect(IssueType.values, contains(IssueType.feature));
      expect(IssueType.values, contains(IssueType.feedback));
      expect(IssueType.values, contains(IssueType.regression));
      expect(IssueType.values, contains(IssueType.translation));
      expect(IssueType.values.length, 5);
    });
  });

  group('FeedbackScreen widget', () {
    /// Verifies the screen builds without runtime errors when all
    /// dependencies are mocked with safe defaults.
    testWidgets('renders without crashing', (tester) async {
      await pumpApp(
        tester,
        const FeedbackScreen(),
        settle: false,
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => const Stream<bool>.empty(),
          ),
        ],
      );
      await tester.pump();
      expect(find.byType(FeedbackScreen), findsOneWidget);
    });

    /// Verifies the form displays title and description text fields.
    testWidgets('shows form with title and description fields', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const FeedbackScreen(),
        settle: false,
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => const Stream<bool>.empty(),
          ),
        ],
      );
      await tester.pump();
      expect(find.byType(FeedbackScreen), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    /// Verifies the online submit flow calls [GithubIssueService.submitIssue],
    /// then resets the form and pops the screen.
    testWidgets('online submit pops the screen', (tester) async {
      final mockService = MockGithubIssueService();

      when(
        () => mockService.submitIssue(
          title: any(named: 'title'),
          body: any(named: 'body'),
          label: any(named: 'label'),
        ),
      ).thenAnswer((_) async => 'https://github.com/owner/repo/issues/1');

      when(() => mockService.isDuplicate(any(), any())).thenReturn(false);

      await pumpApp(
        tester,
        const _SubmitShell(screen: FeedbackScreen()),
        settle: false,
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
          githubIssueServiceProvider.overrideWithValue(mockService),
        ],
      );
      await tester.pump();

      // Navigate to the feedback screen.
      await tester.tap(find.text('Open feedback'));
      await tester.pumpAndSettle();

      // Fill in the title field.
      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Test bug report title',
      );
      await tester.pump();

      // Fill in the description field.
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'This is a test bug description with enough chars.',
      );
      await tester.pump();

      // Tap the submit button.
      await tester.ensureVisible(find.text('Create issue'));
      await tester.tap(find.text('Create issue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The screen is popped after successful submission.
      expect(find.byType(FeedbackScreen), findsNothing);
      verify(
        () => mockService.submitIssue(
          title: any(named: 'title'),
          body: any(named: 'body'),
          label: any(named: 'label'),
        ),
      ).called(1);
    });

    /// Verifies the offline submit calls [GithubIssueService.queueOffline]
    /// when connectivity is false, then pops the screen.
    testWidgets('offline submit queues and pops', (tester) async {
      final mockService = MockGithubIssueService();

      when(() => mockService.isDuplicate(any(), any())).thenReturn(false);
      when(
        () => mockService.queueOffline(
          title: any(named: 'title'),
          body: any(named: 'body'),
          label: any(named: 'label'),
        ),
      ).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const _SubmitShell(screen: FeedbackScreen()),
        settle: false,
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream<bool>.value(false),
          ),
          githubIssueServiceProvider.overrideWithValue(mockService),
        ],
      );
      await tester.pump();

      // Navigate to the feedback screen.
      await tester.tap(find.text('Open feedback'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Test title',
      );
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Test description with enough chars.',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Create issue'));
      await tester.tap(find.text('Create issue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The screen is popped after queuing offline.
      expect(find.byType(FeedbackScreen), findsNothing);
      verify(
        () => mockService.queueOffline(
          title: any(named: 'title'),
          body: any(named: 'body'),
          label: any(named: 'label'),
        ),
      ).called(1);
    });

    /// Verifies the submit button displays validation errors when
    /// title or description are too short.
    testWidgets('shows validation errors when fields are empty', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const FeedbackScreen(),
        settle: false,
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
        ],
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Create issue'));
      await tester.tap(find.text('Create issue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ensure error messages are visible.
      await tester.ensureVisible(
        find.text('Title is required (min 5 characters)'),
      );
      expect(find.text('Title is required (min 5 characters)'), findsOneWidget);
      expect(
        find.text('Description is required (min 10 characters)'),
        findsOneWidget,
      );
    });

    /// Verifies the duplicate detection shows a warning snackbar
    /// when [GithubIssueService.isDuplicate] returns true.
    testWidgets('shows duplicate warning when issue is duplicate', (
      tester,
    ) async {
      final mockService = MockGithubIssueService();

      when(() => mockService.isDuplicate(any(), any())).thenReturn(true);

      await pumpApp(
        tester,
        const FeedbackScreen(),
        settle: false,
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
          githubIssueServiceProvider.overrideWithValue(mockService),
        ],
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Test title with enough chars',
      );
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Test description with enough chars for validation.',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Create issue'));
      await tester.tap(find.text('Create issue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.ensureVisible(
        find.text('You recently submitted a similar report.'),
      );
      expect(
        find.text('You recently submitted a similar report.'),
        findsOneWidget,
      );
    });

    /// Verifies that when [GithubIssueService.submitIssue] throws
    /// [IssueSubmissionException], the form falls back to
    /// [GithubIssueService.queueOffline] and pops the screen.
    testWidgets('online submit falls back to queue and pops', (
      tester,
    ) async {
      final mockService = MockGithubIssueService();

      when(
        () => mockService.submitIssue(
          title: any(named: 'title'),
          body: any(named: 'body'),
          label: any(named: 'label'),
        ),
      ).thenThrow(const IssueSubmissionException('Network error'));
      when(() => mockService.isDuplicate(any(), any())).thenReturn(false);
      when(
        () => mockService.queueOffline(
          title: any(named: 'title'),
          body: any(named: 'body'),
          label: any(named: 'label'),
        ),
      ).thenAnswer((_) async {});

      await pumpApp(
        tester,
        const _SubmitShell(screen: FeedbackScreen()),
        settle: false,
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => Stream<bool>.value(true),
          ),
          githubIssueServiceProvider.overrideWithValue(mockService),
        ],
      );
      await tester.pump();

      // Navigate to the feedback screen.
      await tester.tap(find.text('Open feedback'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Title'),
        'Network error test title',
      );
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'Description'),
        'Test description with enough characters.',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Create issue'));
      await tester.tap(find.text('Create issue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The screen is popped after falling back to queue.
      expect(find.byType(FeedbackScreen), findsNothing);
      verify(
        () => mockService.submitIssue(
          title: any(named: 'title'),
          body: any(named: 'body'),
          label: any(named: 'label'),
        ),
      ).called(1);
      verify(
        () => mockService.queueOffline(
          title: any(named: 'title'),
          body: any(named: 'body'),
          label: any(named: 'label'),
        ),
      ).called(1);
    });
  });
}
