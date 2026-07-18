import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/models/auth_user.dart';

/// Tests for [AuthUser].
///
/// Covers construction, defaults, equality, and copyWith.
void main() {
  group('AuthUser', () {
    test('constructor sets uid', () {
      const user = AuthUser(uid: 'abc123');
      expect(user.uid, 'abc123');
    });

    test('isAnonymous defaults to true', () {
      const user = AuthUser(uid: 'abc123');
      expect(user.isAnonymous, isTrue);
    });

    test('isAnonymous can be set to false', () {
      const user = AuthUser(uid: 'abc123', isAnonymous: false);
      expect(user.isAnonymous, isFalse);
    });

    test('email defaults to null', () {
      const user = AuthUser(uid: 'abc123');
      expect(user.email, isNull);
    });

    test('email can be set', () {
      const user = AuthUser(uid: 'abc123', email: 'user@example.com');
      expect(user.email, 'user@example.com');
    });

    test('displayName defaults to null', () {
      const user = AuthUser(uid: 'abc123');
      expect(user.displayName, isNull);
    });

    test('displayName can be set', () {
      const user = AuthUser(uid: 'abc123', displayName: 'Alice');
      expect(user.displayName, 'Alice');
    });

    group('equality', () {
      test('same uid and fields are equal', () {
        const a = AuthUser(uid: '1', email: 'a@b.com');
        const b = AuthUser(uid: '1', email: 'a@b.com');
        expect(a, equals(b));
      });

      test('different uid are not equal', () {
        const a = AuthUser(uid: '1');
        const b = AuthUser(uid: '2');
        expect(a, isNot(equals(b)));
      });

      test('different isAnonymous are not equal', () {
        const a = AuthUser(uid: '1');
        const b = AuthUser(uid: '1', isAnonymous: false);
        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('returns identical copy when no args', () {
        const user = AuthUser(uid: 'abc', email: 'test@test.com');
        expect(user.copyWith(), equals(user));
      });

      test('overrides uid when provided', () {
        const user = AuthUser(uid: 'old');
        expect(user.copyWith(uid: 'new').uid, 'new');
      });

      test('overrides isAnonymous when provided', () {
        const user = AuthUser(uid: '1');
        expect(user.copyWith(isAnonymous: false).isAnonymous, isFalse);
      });

      test('overrides email when provided', () {
        const user = AuthUser(uid: '1', email: 'old@test.com');
        expect(user.copyWith(email: 'new@test.com').email, 'new@test.com');
      });

      test('overrides displayName when provided', () {
        const user = AuthUser(uid: '1', displayName: 'Old');
        expect(user.copyWith(displayName: 'New').displayName, 'New');
      });

      test('preserves unset fields', () {
        const user = AuthUser(
          uid: '1',
          email: 'user@test.com',
          displayName: 'User',
        );
        final updated = user.copyWith(uid: '2');
        expect(updated.uid, '2');
        expect(updated.isAnonymous, isTrue);
        expect(updated.email, 'user@test.com');
        expect(updated.displayName, 'User');
      });
    });

    test('hashCode is consistent with equality', () {
      const a = AuthUser(uid: '1', email: 'a@b.com');
      const b = AuthUser(uid: '1', email: 'a@b.com');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toString includes uid', () {
      const user = AuthUser(uid: 'test-uid');
      expect(user.toString(), contains('test-uid'));
    });
  });
}
