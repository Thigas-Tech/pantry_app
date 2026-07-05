import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/services/changelog_parser.dart';

void main() {
  group('ChangelogParser.parse', () {
    final parser = ChangelogParser();

    test('empty string returns empty list', () {
      expect(parser.parse(''), isEmpty);
    });

    test('string with no version headers returns empty list', () {
      expect(
        parser.parse('# Changelog\n\nSome text without headers.'),
        isEmpty,
      );
    });

    test('single version section parses correctly', () {
      const raw = '''
# Changelog

## [0.1.0] — Initial release

### Core
- Barcode scanning
- Food lookup
''';
      final entries = parser.parse(raw);
      expect(entries, hasLength(1));
      expect(entries.first.version, '0.1.0');
      expect(entries.first.content, contains('Barcode scanning'));
      expect(entries.first.content, contains('Food lookup'));
    });

    test('multiple versions ordered newest first', () {
      const raw = '''
## [0.1.0] — Old release

### Core
- Old feature

## [1.0.0] — New release

### Core
- New feature
''';
      final entries = parser.parse(raw);
      expect(entries, hasLength(2));
      expect(entries[0].version, '1.0.0');
      expect(entries[1].version, '0.1.0');
    });

    test('[Unreleased] always sorts first', () {
      const raw = '''
## [1.0.0] — Released

### Core
- Stable

## [Unreleased]

### Enhancements
- Dev work
''';
      final entries = parser.parse(raw);
      expect(entries, hasLength(2));
      expect(entries[0].version, 'Unreleased');
      expect(entries[1].version, '1.0.0');
    });

    test('extracts version from header with subtitle text', () {
      const raw = '## [0.1.0] — Initial release (MVP)\n\nContent';
      final entries = parser.parse(raw);
      expect(entries.single.version, '0.1.0');
    });

    test('strips trailing horizontal rule separator', () {
      const raw = '''
## [0.1.0] — Release

### Core
- Item A

---

''';
      final entries = parser.parse(raw);
      expect(entries.first.content, isNot(contains('---')));
    });

    test('section with empty body produces empty content string', () {
      const raw = '## [0.1.0]';
      final entries = parser.parse(raw);
      expect(entries.single.content, isEmpty);
    });

    test('handles version with trailing whitespace in header', () {
      const raw = '## [0.1.0  ]\n\nContent';
      final entries = parser.parse(raw);
      expect(entries.single.version, '0.1.0');
    });

    test('header with multiple consecutive line breaks separates body', () {
      const raw = '''
## [0.2.0]


### Core
- Item A
''';
      final entries = parser.parse(raw);
      expect(entries.single.version, '0.2.0');
      expect(entries.single.content, contains('### Core'));
    });
  });

  group('ChangelogParser.filterUnseen', () {
    final parser = ChangelogParser();

    test('shows version greater than lastSeen and less-or-equal current', () {
      const raw = '''
## [0.2.0]

### Core
- Middle version
''';
      final entries = parser.parse(raw);
      final filtered = parser.filterUnseen(entries, '0.1.0', '0.3.0');
      expect(filtered, hasLength(1));
      expect(filtered.first.version, '0.2.0');
    });

    test('excludes version equal to lastSeen', () {
      const raw = '''
## [0.2.0]

### Core
- Should not appear
''';
      final entries = parser.parse(raw);
      final filtered = parser.filterUnseen(entries, '0.2.0', '0.3.0');
      expect(filtered, isEmpty);
    });

    test('includes version equal to current', () {
      const raw = '''
## [0.3.0]

### Core
- Should appear
''';
      final entries = parser.parse(raw);
      final filtered = parser.filterUnseen(entries, '0.2.0', '0.3.0');
      expect(filtered, hasLength(1));
      expect(filtered.first.version, '0.3.0');
    });

    test('always includes [Unreleased] when upgrading', () {
      const raw = '''
## [Unreleased]

### Enhancements
- Dev
''';
      final entries = parser.parse(raw);
      final filtered = parser.filterUnseen(entries, '0.1.0', '0.2.0');
      expect(filtered, hasLength(1));
      expect(filtered.first.version, 'Unreleased');
    });

    test('returns empty when all versions are older than lastSeen', () {
      const raw = '''
## [0.1.0]

### Core
- Old
''';
      final entries = parser.parse(raw);
      final filtered = parser.filterUnseen(entries, '0.2.0', '0.3.0');
      expect(filtered, isEmpty);
    });

    test('handles 2-segment versions by padding with zeros', () {
      const raw = '## [1.0]\n\nContent';
      final entries = parser.parse(raw);
      final filtered = parser.filterUnseen(entries, '0.9', '2.0');
      expect(filtered, hasLength(1));
    });

    test('handles build-number suffix in version strings', () {
      const raw = '## [1.0.0]\n\nContent';
      final entries = parser.parse(raw);
      final filtered = parser.filterUnseen(entries, '0.1.0+5', '1.0.0+1');
      // lastSeen 0.1.0 < 1.0.0 <= current 1.0.0 → included
      expect(filtered, hasLength(1));
    });
  });

  group('ChangelogParser semver comparison', () {
    final parser = ChangelogParser();

    test('major version comparison works correctly', () {
      // 1.0.0 < 2.0.0 → 2.x sorted first in filtered results
      const raw = '''
## [1.0.0]

### Core
- Old

## [2.0.0]

### Core
- New
''';
      final entries = parser.parse(raw);
      expect(entries[0].version, '2.0.0');
      expect(entries[1].version, '1.0.0');
    });

    test('numeric comparison prevents string-sort bug (1.10.0 vs 1.2.0)', () {
      const raw = '''
## [1.2.0]

### Core
- Minor

## [1.10.0]

### Core
- Major
''';
      final entries = parser.parse(raw);
      expect(entries[0].version, '1.10.0');
      expect(entries[1].version, '1.2.0');
    });

    test('3-segment comparison across all positions', () {
      const raw = '''
## [0.0.1]

## [0.1.0]

## [0.1.1]

## [1.0.0]
''';
      final entries = parser.parse(raw);
      expect(entries[0].version, '1.0.0');
      expect(entries[1].version, '0.1.1');
      expect(entries[2].version, '0.1.0');
      expect(entries[3].version, '0.0.1');
    });
  });
}
