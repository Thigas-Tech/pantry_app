import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pantry_app/utils/logger.dart';

/// Provides a reactive stream of internet connectivity status.
///
/// Uses [InternetConnectionChecker.instance] to monitor whether the
/// device has internet access. Emits `true` when connected, `false`
/// when offline.
///
/// Unlike the default [StreamProvider] which starts as [AsyncLoading],
/// this implementation yields the initial connectivity state as the
/// first event so that downstream code never sees a null/loading state.
/// A 3-second timeout prevents slow DNS lookups from blocking the
/// initial emission.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  try {
    final initial = await InternetConnectionChecker.instance.hasConnection
        .timeout(const Duration(seconds: 3));
    yield initial;
  } on TimeoutException {
    logWarning('Initial connectivity check timed out — defaulting to offline');
    yield false;
  }
  yield* InternetConnectionChecker.instance.onStatusChange.map((status) {
    final online = status == InternetConnectionStatus.connected;
    if (online) {
      logInfo('Connectivity restored — device is online');
    } else {
      logWarning('Connectivity lost — device is offline');
    }
    return online;
  });
});

/// Provides a one-shot connectivity check.
///
/// Unlike [connectivityProvider] (a stream), this resolves once and
/// is ideal for cache-flush flows and other places where you need a
/// simple true/false answer at a single point in time.
final hasConnectionProvider = FutureProvider<bool>((ref) {
  return InternetConnectionChecker.instance.hasConnection;
});
