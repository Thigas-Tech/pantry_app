// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier that exposes the recent-scan history and its mutations.
///
/// The history is a bounded list of the latest successful scans (capped by
/// [ScanHistoryDao.defaultKeepCount]). Recording is delegated here so that
/// the scanner and the UI share a single refresh path.

@ProviderFor(ScanHistory)
final scanHistoryProvider = ScanHistoryProvider._();

/// Notifier that exposes the recent-scan history and its mutations.
///
/// The history is a bounded list of the latest successful scans (capped by
/// [ScanHistoryDao.defaultKeepCount]). Recording is delegated here so that
/// the scanner and the UI share a single refresh path.
final class ScanHistoryProvider
    extends $AsyncNotifierProvider<ScanHistory, List<ScanHistoryEntry>> {
  /// Notifier that exposes the recent-scan history and its mutations.
  ///
  /// The history is a bounded list of the latest successful scans (capped by
  /// [ScanHistoryDao.defaultKeepCount]). Recording is delegated here so that
  /// the scanner and the UI share a single refresh path.
  ScanHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanHistoryHash();

  @$internal
  @override
  ScanHistory create() => ScanHistory();
}

String _$scanHistoryHash() => r'8de12c00d7664a66652e66c8b82ab52151ce8c5f';

/// Notifier that exposes the recent-scan history and its mutations.
///
/// The history is a bounded list of the latest successful scans (capped by
/// [ScanHistoryDao.defaultKeepCount]). Recording is delegated here so that
/// the scanner and the UI share a single refresh path.

abstract class _$ScanHistory extends $AsyncNotifier<List<ScanHistoryEntry>> {
  FutureOr<List<ScanHistoryEntry>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<ScanHistoryEntry>>, List<ScanHistoryEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ScanHistoryEntry>>,
                List<ScanHistoryEntry>
              >,
              AsyncValue<List<ScanHistoryEntry>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
