/// Shared test utilities for initialising the in‑memory SQLite backend.
///
/// Call [initTestDatabase] from `setUpAll` in test files that need a
/// real [DatabaseHelper] without touching the file system.
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialises the FFI database factory for tests.
///
/// This must be called once before any in‑memory database is opened,
/// typically inside `setUpAll`. After calling this, `databaseFactory`
/// points to an FFI‑based implementation that can create temporary
/// in‑memory databases.
void initTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
