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
instance. Tests that open only one database at a time may use
`inMemoryDatabasePath` provided they close it in `tearDown`; tests that hold
two databases open concurrently (e.g. the on-create vs replay comparison in
`oncreate_schema_parity_test.dart` or the v45 upgrade test) MUST use a unique
path per instance (`_uniqueDbPath()` building on `inMemoryDatabasePath`),
mirroring those tests.
