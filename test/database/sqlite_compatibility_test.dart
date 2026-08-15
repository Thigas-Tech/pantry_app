import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against SQLite syntax that postdates the minimum supported
/// Android system SQLite.
///
/// The app targets minSdk 24 (Android 7.0), which bundles SQLite 3.9.2.
/// The following SQL features require newer engines:
/// - NULLS LAST / NULLS FIRST in ORDER BY: SQLite 3.30.0 (Android 11+)
/// - Window functions (ROW_NUMBER() OVER ...): SQLite 3.25.0 (Android 10+)
/// - ALTER TABLE DROP COLUMN: SQLite 3.35.0 (Android 13+)
/// - ALTER TABLE RENAME COLUMN: SQLite 3.25.0 (Android 10+)
/// - UPSERT (ON CONFLICT DO UPDATE): SQLite 3.24.0 (Android 10+)
/// - RETURNING clause: SQLite 3.35.0 (Android 13+)
///
/// Tests run against sqflite_common_ffi, which bundles a modern sqlite3,
/// so they cannot catch version-gated SQL on their own. This test scans
/// the production source tree and fails if such syntax is reintroduced.
///
/// The allowlisted file may still use the syntax: v43 deliberately
/// uses DROP COLUMN inside a try/catch because the statement is rejected on
/// SQLite < 3.35 (the column is retained there rather than blocking the
/// upgrade).
void main() {
  final bannedPatterns = <String, RegExp>{
    'NULLS LAST': RegExp(r'NULLS\s+LAST'),
    'NULLS FIRST': RegExp(r'NULLS\s+FIRST'),
    'window functions (OVER clause)': RegExp(
      r'\b(ROW_NUMBER|RANK|DENSE_RANK|NTILE|LAG|LEAD|FIRST_VALUE|'
      r'LAST_VALUE|CUME_DIST|PERCENT_RANK)\s*\(\s*\)\s*OVER\s*\(',
    ),
    'DROP COLUMN': RegExp(r'DROP\s+COLUMN'),
    'RENAME COLUMN': RegExp(r'RENAME\s+COLUMN'),
    'UPSERT (ON CONFLICT DO UPDATE)': RegExp(
      r'ON\s+CONFLICT[^;]*DO\s+UPDATE',
    ),
    'RETURNING clause': RegExp(r'\bRETURNING\b'),
  };

  final allowlistedPaths = <String>{
    'lib/database/migrations/v43_remove_recipe_shared_id.dart',
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
        if (allowlistedPaths.contains(file.path)) continue;
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
            'correlated subqueries instead of window functions, and guarded '
            'DDL for DROP/RENAME COLUMN.\n'
            '${violations.join('\n')}',
      );
    },
  );
}
