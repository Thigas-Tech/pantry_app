import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/migrations/v1_baseline_schema.dart';

/// Returns all known migrations sorted by version.
List<Migration> allMigrations() => [const MigrationV1()];
