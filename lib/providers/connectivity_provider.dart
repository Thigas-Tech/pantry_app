import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Debounces offline transitions on a connectivity status stream.
///
/// When the source stream emits [InternetConnectionStatus.disconnected],
/// this transformer does **not** immediately emit false. Instead, it
/// waits for [debounceDuration]. If the source emits
/// [InternetConnectionStatus.connected] before the timer elapses, the
/// offline event is suppressed entirely (the timer is cancelled).
///
/// Reconnection events (disconnected → connected) are emitted immediately
/// — there is no debounce on the upward transition.
///
/// The debounce window is reset on each successive disconnected event
/// while a timer is already running.
Stream<bool> debounceConnectivityStatus(
  Stream<InternetConnectionStatus> source, {
  Duration debounceDuration = const Duration(seconds: 3),
}) {
  Timer? timer;
  var lastEmitted = false;

  final controller = StreamController<bool>(
    onCancel: () {
      timer?.cancel();
      timer = null;
    },
  );

  final subscription = source.listen(
    (status) {
      final online = status == InternetConnectionStatus.connected;
      if (online) {
        if (timer != null) {
          timer!.cancel();
          timer = null;
        }
        if (!lastEmitted) {
          lastEmitted = true;
          logInfo('Connectivity restored — device is online');
          controller.add(true);
        }
      } else {
        if (timer != null) return;
        timer = Timer(debounceDuration, () {
          timer = null;
          lastEmitted = false;
          logWarning('Connectivity lost — device is offline');
          controller.add(false);
        });
      }
    },
    onError: (Object e) {
      logError('Connectivity status stream error: $e');
      controller.addError(e);
    },
    onDone: () {
      timer?.cancel();
      timer = null;
      unawaited(controller.close());
    },
  );

  controller.onCancel = () {
    unawaited(subscription.cancel());
    timer?.cancel();
    timer = null;
  };

  return controller.stream;
}

/// Provides a reactive stream of internet connectivity status.
///
/// Uses [InternetConnectionChecker.instance] to monitor whether the
/// device has internet access. Emits true when connected, false
/// when offline.
///
/// Unlike the default [StreamProvider] which starts as [AsyncLoading],
/// this implementation yields the initial connectivity state as the
/// first event so that downstream code never sees a null/loading state.
/// A 3-second timeout prevents slow DNS lookups from blocking the
/// initial emission.
///
/// Offline transitions are debounced for 3 seconds to suppress transient
/// network blips (DNS hiccups, mobile network handovers, slow server
/// responses).
@Riverpod(keepAlive: true)
Stream<bool> connectivity(Ref ref) async* {
  try {
    final initial = await InternetConnectionChecker.instance.hasConnection
        .timeout(const Duration(seconds: 3));
    yield initial;
  } on TimeoutException {
    logWarning('Initial connectivity check timed out — defaulting to offline');
    yield false;
  }
  yield* debounceConnectivityStatus(
    InternetConnectionChecker.instance.onStatusChange,
  );
}

/// Provides a one-shot connectivity check.
///
/// Unlike [connectivityProvider] (a stream), this resolves once and
/// is ideal for cache-flush flows and other places where you need a
/// simple true/false answer at a single point in time.
@Riverpod(keepAlive: true)
Future<bool> hasConnection(Ref ref) {
  return InternetConnectionChecker.instance.hasConnection;
}
