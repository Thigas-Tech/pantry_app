import 'package:pantry_app/database/migrations/migration_runner.dart';
import 'package:sqflite/sqflite.dart';

/// A single database migration step.
///
/// Subclasses define a [version] number and the schema changes to apply
/// in [up]. The [MigrationRunner] discovers subclasses by version and
/// runs them in order during `onUpgrade`.
abstract class Migration {
  /// The target database version after this migration runs.
  int get version;

  /// Applies the schema changes for this migration.
  ///
  /// Called inside the `onUpgrade` callback. Should be resilient to
  /// re-execution (idempotent) whenever possible.
  Future<void> up(Database db);
}
