import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:pantry_app/utils/logger.dart';

/// Provides a reactive stream of internet connectivity status.
///
/// Uses `InternetConnectionChecker.instance` to monitor whether the
/// device has internet access. Emits `true` when connected, `false`
/// when offline, and `null` during initial loading.
final connectivityProvider = StreamProvider<bool>((ref) {
  return InternetConnectionChecker.instance.onStatusChange.map((status) {
    final online = status == InternetConnectionStatus.connected;
    if (online) {
      logInfo('Connectivity restored — device is online');
    } else {
      logWarning('Connectivity lost — device is offline');
    }
    return online;
  });
});
