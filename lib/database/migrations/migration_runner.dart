import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Runs a list of [Migration]s in order during database upgrade.
///
/// The runner:
/// - Only runs migrations with a version in the upgrade window
/// - Logs each migration's elapsed time
/// - Aborts on the first failure so the upgrade transaction rolls back
///   and the database version stays unchanged (retried on next launch)
class MigrationRunner {
  /// Creates a [MigrationRunner] with the given ordered [migrations].
  const MigrationRunner(this.migrations);

  /// All known migrations, sorted by version ascending.
  final List<Migration> migrations;

  /// Runs every migration whose version is <= [newVersion] and > [oldVersion].
  ///
  /// The upgrade window: migrations with a version greater than [oldVersion]
  /// and less than or equal to [newVersion] are applied.
  ///
  /// Throws the first failing migration's exception after logging it, so
  /// sqflite rolls back the whole upgrade and retries on the next launch.
  /// Returns a [MigrationResult] describing the outcome on success.
  Future<MigrationResult> run(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    final results = <int, MigrationStatus>{};

    for (final m in migrations) {
      if (m.version <= oldVersion) continue;
      if (m.version > newVersion) break;

      final start = DateTime.now();
      try {
        await m.up(db);
        final elapsed = DateTime.now().difference(start);
        logInfo(
          'Migration v${m.version} completed in ${elapsed.inMilliseconds} ms',
        );
        results[m.version] = const MigrationStatusSuccess();
      } on Exception catch (e) {
        logWarning('Migration v${m.version} failed: $e');
        rethrow;
      }
    }

    return MigrationResult._(results);
  }
}

/// The outcome of a [MigrationRunner.run] call.
class MigrationResult {
  const MigrationResult._(this._results);

  final Map<int, MigrationStatus> _results;

  /// The set of versions that ran successfully.
  Set<int> get succeeded => _results.entries
      .where((e) => e.value is MigrationStatusSuccess)
      .map((e) => e.key)
      .toSet();

  /// The set of versions that failed.
  Set<int> get failed => _results.entries
      .where((e) => e.value is MigrationStatusFailure)
      .map((e) => e.key)
      .toSet();

  /// True when every migration that ran succeeded.
  bool get isSuccess => failed.isEmpty;

  /// True when none of the migrations ran.
  bool get nothingToUpgrade => _results.isEmpty;
}

/// Status of a single migration.
sealed class MigrationStatus {
  const MigrationStatus();
}

/// The migration ran and completed without error.
class MigrationStatusSuccess extends MigrationStatus {
  /// Creates a success status.
  const MigrationStatusSuccess();
}

/// The migration ran but threw an exception.
class MigrationStatusFailure extends MigrationStatus {
  /// Creates a failure status with the given [error] message.
  const MigrationStatusFailure(this.error);

  /// The exception message from the failed migration.
  final String error;
}
