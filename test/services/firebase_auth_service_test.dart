import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/auth_user.dart';
import 'package:pantry_app/services/firebase_auth_service.dart';

// controller.close() fires in tearDown — no need to await.
// ignore_for_file: discarded_futures

// ====================================================================
//  Mocks
// ====================================================================

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  group('FirebaseAuthService', () {
    late MockFirebaseAuth mockAuth;
    late StreamController<User?> authStateController;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authStateController = StreamController<User?>.broadcast();
      when(() => mockAuth.authStateChanges()).thenAnswer(
        (_) => authStateController.stream,
      );
    });

    tearDown(() {
      authStateController.close();
    });

    // ------------------------------------------------------------------
    //  Constructor
    // ------------------------------------------------------------------

    test('subscribes to authStateChanges on construction', () {
      FirebaseAuthService(mockAuth);
      verify(() => mockAuth.authStateChanges()).called(1);
    });

    // ------------------------------------------------------------------
    //  signInAnonymously
    // ------------------------------------------------------------------

    group('signInAnonymously', () {
      test('returns AuthUser on success', () async {
        final mockCred = MockUserCredential();
        final mockFirebaseUser = MockUser();
        when(() => mockFirebaseUser.uid).thenReturn('new-uid');
        when(() => mockFirebaseUser.isAnonymous).thenReturn(true);
        when(() => mockFirebaseUser.email).thenReturn(null);
        when(() => mockFirebaseUser.displayName).thenReturn(null);
        when(() => mockCred.user).thenReturn(mockFirebaseUser);
        when(() => mockAuth.signInAnonymously()).thenAnswer(
          (_) async => mockCred,
        );
        when(() => mockAuth.currentUser).thenReturn(null);
        final service = FirebaseAuthService(mockAuth);

        final result = await service.signInAnonymously();

        expect(result, isNotNull);
        expect(result!.uid, 'new-uid');
        expect(result.isAnonymous, isTrue);
      });

      test('returns existing user when already signed in', () async {
        final mockFirebaseUser = MockUser();
        when(() => mockFirebaseUser.uid).thenReturn('existing-uid');
        when(() => mockFirebaseUser.isAnonymous).thenReturn(true);
        when(() => mockFirebaseUser.email).thenReturn(null);
        when(() => mockFirebaseUser.displayName).thenReturn(null);
        when(() => mockAuth.currentUser).thenReturn(mockFirebaseUser);
        final service = FirebaseAuthService(mockAuth);

        final result = await service.signInAnonymously();

        expect(result, isNotNull);
        expect(result!.uid, 'existing-uid');
        verifyNever(() => mockAuth.signInAnonymously());
      });

      test('returns null on FirebaseAuthException', () async {
        when(() => mockAuth.signInAnonymously()).thenThrow(
          FirebaseAuthException(code: 'network-error'),
        );
        when(() => mockAuth.currentUser).thenReturn(null);
        final service = FirebaseAuthService(mockAuth);

        final result = await service.signInAnonymously();

        expect(result, isNull);
      });

      test('returns null on generic Exception', () async {
        when(() => mockAuth.signInAnonymously()).thenThrow(
          Exception('something went wrong'),
        );
        when(() => mockAuth.currentUser).thenReturn(null);
        final service = FirebaseAuthService(mockAuth);

        final result = await service.signInAnonymously();

        expect(result, isNull);
      });

      test(
        'returns null and logs warning when credential.user is null',
        () async {
          final mockCred = MockUserCredential();
          when(() => mockCred.user).thenReturn(null);
          when(() => mockAuth.signInAnonymously()).thenAnswer(
            (_) async => mockCred,
          );
          when(() => mockAuth.currentUser).thenReturn(null);
          final service = FirebaseAuthService(mockAuth);

          final result = await service.signInAnonymously();

          expect(result, isNull);
        },
      );

      test('is idempotent when already signed in', () async {
        final mockFirebaseUser = MockUser();
        when(() => mockFirebaseUser.uid).thenReturn('uid');
        when(() => mockFirebaseUser.isAnonymous).thenReturn(true);
        when(() => mockFirebaseUser.email).thenReturn(null);
        when(() => mockFirebaseUser.displayName).thenReturn(null);
        when(() => mockAuth.currentUser).thenReturn(mockFirebaseUser);
        final service = FirebaseAuthService(mockAuth);

        await service.signInAnonymously();
        await service.signInAnonymously();

        verifyNever(() => mockAuth.signInAnonymously());
      });
    });

    // ------------------------------------------------------------------
    //  signOut
    // ------------------------------------------------------------------

    group('signOut', () {
      test('calls FirebaseAuth.signOut', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});
        final service = FirebaseAuthService(mockAuth);

        await service.signOut();

        verify(() => mockAuth.signOut()).called(1);
      });

      test('emits null on authStateChanges after sign out', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});
        final service = FirebaseAuthService(mockAuth);

        final emitted = <AuthUser?>[];
        final sub = service.authStateChanges.listen(emitted.add);

        authStateController.add(null);
        await Future<void>.delayed(Duration.zero);

        expect(emitted, contains(null));
        await sub.cancel();
      });
    });

    // ------------------------------------------------------------------
    //  currentUser
    // ------------------------------------------------------------------

    group('currentUser', () {
      test('returns null before any sign in', () {
        final service = FirebaseAuthService(mockAuth);
        expect(service.currentUser, isNull);
      });

      test('returns AuthUser after authStateChanges emits a user', () async {
        final mockFirebaseUser = MockUser();
        when(() => mockFirebaseUser.uid).thenReturn('uid');
        when(() => mockFirebaseUser.isAnonymous).thenReturn(true);
        when(() => mockFirebaseUser.email).thenReturn(null);
        when(() => mockFirebaseUser.displayName).thenReturn(null);
        final service = FirebaseAuthService(mockAuth);

        authStateController.add(mockFirebaseUser);
        await Future<void>.delayed(Duration.zero);

        expect(service.currentUser, isNotNull);
        expect(service.currentUser!.uid, 'uid');
      });

      test('returns null after authStateChanges emits null', () async {
        final service = FirebaseAuthService(mockAuth);
        authStateController.add(null);
        await Future<void>.delayed(Duration.zero);

        expect(service.currentUser, isNull);
      });
    });

    // ------------------------------------------------------------------
    //  authStateChanges stream
    // ------------------------------------------------------------------

    group('authStateChanges', () {
      test('emits AuthUser when Firebase emits a User', () async {
        final mockFirebaseUser = MockUser();
        when(() => mockFirebaseUser.uid).thenReturn('uid1');
        when(() => mockFirebaseUser.isAnonymous).thenReturn(true);
        when(() => mockFirebaseUser.email).thenReturn(null);
        when(() => mockFirebaseUser.displayName).thenReturn(null);
        final service = FirebaseAuthService(mockAuth);

        final emitted = <AuthUser?>[];
        final sub = service.authStateChanges.listen(emitted.add);

        authStateController.add(mockFirebaseUser);
        await Future<void>.delayed(Duration.zero);

        expect(emitted.length, greaterThanOrEqualTo(1));
        expect(emitted.last?.uid, 'uid1');
        await sub.cancel();
      });

      test('emits null when Firebase emits null', () async {
        final service = FirebaseAuthService(mockAuth);

        final emitted = <AuthUser?>[];
        final sub = service.authStateChanges.listen(emitted.add);

        authStateController.add(null);
        await Future<void>.delayed(Duration.zero);

        expect(emitted, contains(null));
        await sub.cancel();
      });

      test('supports multiple listeners', () async {
        final mockFirebaseUser = MockUser();
        when(() => mockFirebaseUser.uid).thenReturn('uid');
        when(() => mockFirebaseUser.isAnonymous).thenReturn(true);
        when(() => mockFirebaseUser.email).thenReturn(null);
        when(() => mockFirebaseUser.displayName).thenReturn(null);
        final service = FirebaseAuthService(mockAuth);

        final emitted1 = <AuthUser?>[];
        final emitted2 = <AuthUser?>[];
        final sub1 = service.authStateChanges.listen(emitted1.add);
        final sub2 = service.authStateChanges.listen(emitted2.add);

        authStateController.add(mockFirebaseUser);
        await Future<void>.delayed(Duration.zero);

        expect(emitted1.last?.uid, 'uid');
        expect(emitted2.last?.uid, 'uid');
        await sub1.cancel();
        await sub2.cancel();
      });
    });
  });
}
