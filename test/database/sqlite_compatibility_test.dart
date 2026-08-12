import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against SQLite syntax that postdates the minimum supported
/// Android system SQLite.
///
/// The app targets minSdk 24 (Android 7.0), which bundles SQLite 3.9.2.
/// Two SQL features used historically require newer engines:
/// - NULLS LAST / NULLS FIRST in ORDER BY: SQLite 3.30.0 (Android 11+)
/// - Window functions (ROW_NUMBER() OVER ...): SQLite 3.25.0 (Android 10+)
///
/// Tests run against sqflite_common_ffi, which bundles a modern sqlite3,
/// so they cannot catch version-gated SQL on their own. This test scans
/// the production source tree and fails if either syntax is reintroduced.
void main() {
  final bannedPatterns = <String, RegExp>{
    'NULLS LAST': RegExp(r'NULLS\s+LAST'),
    'NULLS FIRST': RegExp(r'NULLS\s+FIRST'),
    'window functions (OVER clause)': RegExp(
      r'\b(ROW_NUMBER|RANK|DENSE_RANK|NTILE|LAG|LEAD|FIRST_VALUE|'
      r'LAST_VALUE|CUME_DIST|PERCENT_RANK)\s*\(\s*\)\s*OVER\s*\(',
    ),
  };

  test(
    'production code uses only SQLite 3.9.2-compatible SQL syntax',
    () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib/ must exist');

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(dartFiles, isNotEmpty);

      final violations = <String>[];
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final entry in bannedPatterns.entries) {
          for (final match in entry.value.allMatches(content)) {
            final line = content.substring(0, match.start).split('\n').length;
            violations.add(
              '${file.path}:$line uses ${entry.key} '
              '(${match.group(0)}) which requires newer SQLite',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Version-gated SQLite syntax found in lib/. Replace it with '
            'portable SQL: ORDER BY (col IS NULL), col ASC for NULLS LAST, '
            'and correlated subqueries instead of window functions.\n'
            '${violations.join('\n')}',
      );
    },
  );
}
