import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/services/image_cache_service.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A callable that reports the installed version and build number.
///
/// Injected into [AppUpdateHandler] so tests can fake the platform call.
typedef VersionInfoSource =
    Future<({String version, String buildNumber})> Function();

/// The real [PackageInfo.fromPlatform]-backed version source.
Future<({String version, String buildNumber})> platformVersionInfo() async {
  final info = await PackageInfo.fromPlatform();
  return (version: info.version, buildNumber: info.buildNumber);
}

/// Handles the app-version and changelog bookkeeping at startup.
///
/// The version comparison runs before the first frame (one fast platform
/// call), while the changelog content-hash check and the post-update cache
/// flush are deferred until after the first frame so startup does not
/// block on asset loads or database writes.
class AppUpdateHandler {
  /// Creates an [AppUpdateHandler].
  ///
  /// [prefs], [db], and [imageCache] are injected for testability;
  /// [versionInfo] defaults to the real platform implementation.
  AppUpdateHandler({
    required this.prefs,
    required this.db,
    required this.imageCache,
    VersionInfoSource? versionInfo,
  }) : versionInfo = versionInfo ?? platformVersionInfo;

  /// The persisted-preference store.
  final SharedPreferences prefs;

  /// The database whose API-fetched products are cleared after an update.
  final DatabaseHelper db;

  /// The image cache cleared after an update.
  final ImageCacheService imageCache;

  /// Version source, injectable for tests.
  final VersionInfoSource versionInfo;

  /// Reads the installed version and persists it as the last-seen version.
  ///
  /// Returns true when the version changed since the last launch (the
  /// caller should flush caches post-frame), false otherwise.
  Future<bool> checkVersionChanged() async {
    final info = await versionInfo();
    final currentVersion = '${info.version}+${info.buildNumber}';
    final lastVersion = prefs.getString('app_version');
    await prefs.setString('app_version', currentVersion);
    if (lastVersion == currentVersion) {
      logInfo('Version unchanged ($currentVersion) — skipping cache flush');
      return false;
    }
    logInfo(
      'App updated from ${lastVersion ?? 'first install'} to $currentVersion',
    );
    return true;
  }

  /// Flags the "What's New" badge when the changelog content hash changes.
  ///
  /// Content-hash-driven so new Unreleased entries surface even when the
  /// version string has not changed between development builds. Returns
  /// true when the caller should show the changelog (the caller owns the
  /// one-shot "show pending" UI flag).
  Future<bool> updateChangelogFlag() async {
    final raw = await rootBundle.loadString('USER_CHANGELOG.md');
    final contentHash = raw.hashCode.toString();
    final lastSeenHash = prefs.getString('changelog_content_hash');
    final changed = lastSeenHash != null && lastSeenHash != contentHash;
    await prefs.setString('changelog_content_hash', contentHash);
    if (changed) {
      logInfo('Changelog content changed — flagged for display');
    }
    return changed;
  }

  /// Clears the image cache and API-fetched product records after an
  /// update, so stale data is re-fetched with fresh OFF data.
  ///
  /// Manual products entered by the user are preserved.
  Future<void> flushCaches() async {
    await imageCache.clearCache();
    await db.clearCachedProducts();
    logInfo('Caches flushed for app update');
  }
}
