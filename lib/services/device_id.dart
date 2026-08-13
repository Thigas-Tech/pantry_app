import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A stable, per-install identifier sent to the feedback proxy.
///
/// The server uses it (alongside the client IP) to enforce per-device
/// feedback rate limits. Persisted in SharedPreferences so it survives
/// restarts but changes on reinstall — it is an anti-spam handle, not a
/// privacy-sensitive value.
class DeviceId {
  DeviceId._();

  /// SharedPreferences key holding the generated id.
  static const String storageKey = 'device_id';

  /// Returns the persisted device id, generating and storing one on first
  /// use.
  static Future<String> get() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(storageKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(storageKey, id);
    }
    return id;
  }
}
