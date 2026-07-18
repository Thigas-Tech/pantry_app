import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pantry_app/models/auth_user.dart';
import 'package:pantry_app/providers/auth_provider.dart';
import 'package:pantry_app/services/auth_service.dart';

// ====================================================================
//  Mock AuthService
// ====================================================================

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('authProvider', () {
    test('authServiceProvider returns the AuthService instance', () {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith((ref) => MockAuthService()),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(authServiceProvider);
      expect(service, isA<AuthService>());
    });

    test('authStateProvider is AsyncLoading before stream emits', () {
      final mockService = MockAuthService();
      when(() => mockService.authStateChanges).thenAnswer(
        (_) => const Stream.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authStateProvider);
      expect(state, isA<AsyncLoading<AuthUser?>>());
    });

    test('authStateProvider emits a user', () async {
      final mockService = MockAuthService();
      const testUser = AuthUser(uid: 'test-uid');
      when(() => mockService.authStateChanges).thenAnswer(
        (_) => Stream.value(testUser),
      );

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final completer = Completer<AsyncValue<AuthUser?>>();
      final sub = container.listen<AsyncValue<AuthUser?>>(
        authStateProvider,
        (prev, next) {
          if (!completer.isCompleted) completer.complete(next);
        },
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 1),
      );
      sub.close();

      expect(result.value?.uid, 'test-uid');
    });

    test('authStateProvider emits null on sign out', () async {
      final mockService = MockAuthService();
      final controller = StreamController<AuthUser?>.broadcast();
      when(() => mockService.authStateChanges).thenAnswer(
        (_) => controller.stream,
      );

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockService),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<AuthUser?>>[];
      final sub = container.listen<AsyncValue<AuthUser?>>(
        authStateProvider,
        (prev, next) {
          values.add(next);
        },
      );

      controller.add(const AuthUser(uid: 'u1'));
      await Future<void>.delayed(Duration.zero);
      controller.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(values.any((v) => v.value?.uid == 'u1'), isTrue);
      expect(values.any((v) => v.value == null), isTrue);
      await controller.close();
      sub.close();
    });
  });
}
