import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Runs migrations in order during database creation, upgrade, or rollback.
///
/// The runner:
/// - Only runs migrations with a version in the requested window
/// - Logs each migration's elapsed time
/// - Aborts on the first failure so the surrounding transaction rolls back
///   and the database stays unchanged (retried on the next launch)
class MigrationRunner {
  /// Creates a [MigrationRunner] with the given ordered [migrations].
  const MigrationRunner(this.migrations);

  /// All known migrations, sorted by version ascending.
  final List<Migration> migrations;

  /// Runs every migration whose version is <= [newVersion] and > [oldVersion].
  ///
  /// The upgrade window: migrations with a version greater than [oldVersion]
  /// and less than or equal to [newVersion] are applied, in ascending order.
  ///
  /// Throws the first failing migration's exception after logging it, so the
  /// surrounding transaction rolls back and retries on the next launch.
  /// Returns a [MigrationResult] describing the outcome on success.
  Future<MigrationResult> run(
    DatabaseExecutor db,
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

  /// Runs every migration whose version is <= [fromVersion] and
  /// > [toVersion], in descending version order.
  ///
  /// The rollback window: migrations with a version greater than [toVersion]
  /// and less than or equal to [fromVersion] are reverted, newest first.
  ///
  /// Throws the first failing migration's exception after logging it, so the
  /// surrounding transaction rolls back and the database stays consistent.
  Future<MigrationResult> runDown(
    DatabaseExecutor db,
    int fromVersion,
    int toVersion,
  ) async {
    final results = <int, MigrationStatus>{};
    final descending = migrations.toList()
      ..sort((a, b) => b.version.compareTo(a.version));

    for (final m in descending) {
      if (m.version > fromVersion) continue;
      if (m.version <= toVersion) break;

      final start = DateTime.now();
      try {
        await m.down(db);
        final elapsed = DateTime.now().difference(start);
        logInfo(
          'Rollback v${m.version} completed in ${elapsed.inMilliseconds} ms',
        );
        results[m.version] = const MigrationStatusSuccess();
      } on Exception catch (e) {
        logWarning('Rollback v${m.version} failed: $e');
        rethrow;
      }
    }

    return MigrationResult._(results);
  }
}

/// The outcome of a [MigrationRunner] run.
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

  /// True when no migrations were applied during an upgrade.
  bool get nothingToUpgrade => _results.isEmpty;

  /// True when no migrations were reverted during a rollback.
  bool get nothingToRollback => _results.isEmpty;
}

/// Status of a single migration.
sealed class MigrationStatus {
  /// Base constructor shared by every [MigrationStatus] variant.
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
