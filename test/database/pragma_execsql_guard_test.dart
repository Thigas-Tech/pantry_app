import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Guards against running row-returning PRAGMA statements through
/// [Database.execute] on Android.
///
/// [Database.execute] maps to Android's SQLiteDatabase.execSQL, whose native
/// implementation rejects statements that produce a result row with
/// "Queries can be performed using SQLiteDatabase query or rawQuery methods
/// only." [PRAGMA journal_mode = WAL] returns the new journal mode as a row,
/// so it must be set through the setJournalMode helper instead.
///
/// Tests run against sqflite_common_ffi, which bundles a plain sqlite3
/// binding without the Android execSQL restriction, so they cannot reproduce
/// the failure on their own. This test scans the production source tree and
/// fails if the pattern is reintroduced.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('row-returning pragma usage', () {
    test(
      'row-returning PRAGMAs are never passed to Database.execute',
      () {
        final libDir = Directory('lib');
        expect(libDir.existsSync(), isTrue, reason: 'lib/ must exist');

        final bannedPragmas = <String, RegExp>{
          'journal_mode': RegExp(
            "execute\\(\\s*['\\\"]PRAGMA\\s+journal_mode",
          ),
          'mmap_size': RegExp(
            "execute\\(\\s*['\\\"]PRAGMA\\s+mmap_size",
          ),
        };

        final dartFiles = libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList();
        expect(dartFiles, isNotEmpty);

        final violations = <String>[];
        for (final file in dartFiles) {
          final content = file.readAsStringSync();
          for (final entry in bannedPragmas.entries) {
            for (final match in entry.value.allMatches(content)) {
              final line = content.substring(0, match.start).split('\n').length;
              violations.add('${file.path}:$line uses PRAGMA ${entry.key}');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'PRAGMA journal_mode = WAL and PRAGMA mmap_size return a result '
              'row and Android execSQL rejects them. Set journal_mode via '
              'Database.setJournalMode and run mmap_size through '
              'Database.rawQuery instead.\n'
              '${violations.join('\n')}',
        );
      },
    );

    test(
      'database opens on a real file with WAL journal mode active',
      () async {
        final tempDir = Directory.systemTemp.createTempSync('pantry_wal_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final dbPath = '${tempDir.path}/pantry.db';

        final db = DatabaseHelper.withPath(dbPath);
        final database = await db.database;
        addTearDown(database.close);

        final rows = await database.rawQuery('PRAGMA journal_mode');
        expect(rows.first['journal_mode'], 'wal');

        await db.insertProduct(
          const Product(
            barcode: 'wal-guard',
            name: 'Wal Guard',
            source: 'manual',
          ),
        );
        expect(await db.getProduct('wal-guard'), isNotNull);
      },
    );
  });
}
