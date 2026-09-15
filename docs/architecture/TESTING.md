## 8. Testing strategy

| Layer    | Tooling                              | Approach                                  |
|----------|--------------------------------------|-------------------------------------------|
| Database | `sqflite_common_ffi`, in-memory DB   | Full CRUD, migration, cleanup tests       |
| Services | `mocktail` mocks for http client     | Isolated unit tests with stubbed I/O      |
| Providers| `ProviderContainer`                  | Test provider wiring and defaults         |
| Screens  | `pumpApp()` helper + mocks           | Widget tests with Riverpod scope + l10n   |
| Widgets  | `pumpApp()` helper                   | Visual assertions on cards, error states  |
| Utils    | Pure Dart                            | Logger output capture, snackbar styling   |
| Golden  | `matchesGoldenFile`                  | Visual regression for badges, screens     |

**In-memory database isolation**: `sqflite_common_ffi` caches open databases
by path, so opening `inMemoryDatabasePath` twice returns the same database
instance. Tests that hold two databases open concurrently MUST use a unique
path per instance; `test/helpers/test_database.dart` provides
`uniqueTestDbPath()` and `openTestDatabase()`, which also applies the
baseline schema.

**Schema tests**: `baseline_schema_test.dart` freezes the expected tables,
columns, indexes, foreign keys, and the seeded default pantry.
`migration_round_trip_test.dart` verifies that `down` clears the schema,
`up` rebuilds it identically, and `resetDatabase()` reseeds the default
pantry. `downgrade_wipe_test.dart` verifies that a database reporting a
higher `user_version` is wiped and rebuilt from the baseline.
