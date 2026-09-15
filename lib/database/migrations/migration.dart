import 'package:sqflite/sqflite.dart';

/// A single database migration step.
///
/// Subclasses define a [version] number, the schema changes to apply in
/// [up], and their inverse in [down]. The migration runner applies [up]
/// in ascending version order during creation and upgrades, and [down] in
/// descending order during a rollback or a full database reset.
abstract class Migration {
  /// Creates a migration.
  const Migration();

  /// The target database version after this migration runs.
  int get version;

  /// Applies the schema changes for this migration.
  ///
  /// Called inside a creation or upgrade transaction. Must be resilient to
  /// re-execution whenever possible.
  Future<void> up(DatabaseExecutor db);

  /// Reverts the schema changes made by [up].
  ///
  /// Called inside a rollback transaction, in descending version order.
  /// Must be resilient to re-execution (use DROP ... IF EXISTS).
  Future<void> down(DatabaseExecutor db);
}
