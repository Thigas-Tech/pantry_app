/// @file Submission flow vocabulary tests.
///
/// Verifies the localized strings added for the manual submission flow are
/// generated, interpolate correctly, and carry real Portuguese translations
/// rather than silently falling back to English. gen-l10n falls back to the
/// template language for any key a locale is missing, so these tests guard
/// the new submission vocabulary (progress labels, partial state, duplicate
/// response, gallery permission, fetch failure) across all three locales.
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/l10n/app_localizations.dart';

void main() {
  group('submission flow vocabulary', () {
    test('uploadingPhotos interpolates current and total', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(l10n.uploadingPhotos(1, 3), 'Uploading photo 1 of 3…');
    });

    test('new vocabulary is non-empty in every locale', () async {
      const locales = <Locale>[
        Locale('en'),
        Locale('pt'),
        Locale('pt', 'BR'),
      ];
      for (final locale in locales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        expect(l10n.submittingMetadata, isNotEmpty, reason: '$locale');
        expect(
          l10n.submissionPartiallyCompleted,
          isNotEmpty,
          reason: '$locale',
        );
        expect(l10n.productAlreadyInOff, isNotEmpty, reason: '$locale');
        expect(
          l10n.submissionWrongCredentialsError,
          isNotEmpty,
          reason: '$locale',
        );
        expect(
          l10n.productAlreadyInOffTitle,
          isNotEmpty,
          reason: '$locale',
        );
        expect(
          l10n.galleryPermissionDeniedTitle,
          isNotEmpty,
          reason: '$locale',
        );
        expect(
          l10n.galleryPermissionDeniedBody,
          isNotEmpty,
          reason: '$locale',
        );
        expect(l10n.fetchProductFailed, isNotEmpty, reason: '$locale');
        expect(l10n.notAvailable, isNotEmpty, reason: '$locale');
      }
    });

    test('Portuguese translations do not fall back to English', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final pt = await AppLocalizations.delegate.load(const Locale('pt'));
      final ptBr = await AppLocalizations.delegate.load(
        const Locale('pt', 'BR'),
      );
      final values = <String Function(AppLocalizations)>[
        (l) => l.submittingMetadata,
        (l) => l.submissionPartiallyCompleted,
        (l) => l.productAlreadyInOff,
        (l) => l.submissionWrongCredentialsError,
        (l) => l.galleryPermissionDeniedTitle,
        (l) => l.galleryPermissionDeniedBody,
        (l) => l.fetchProductFailed,
      ];
      for (final value in values) {
        expect(value(pt), isNot(value(en)), reason: 'pt falls back to en');
        expect(value(ptBr), isNot(value(en)), reason: 'pt_BR falls back');
      }
    });
  });
}
