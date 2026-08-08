import 'package:pantry_app/config.dart';

/// Replaces sensitive configuration values (currently the Open Food Facts
/// password) inside [message] with a placeholder.
///
/// SDK exception messages and server error pages can echo request data back,
/// so logging them verbatim risks leaking credentials. Apply this helper to
/// every log message that embeds an exception string or an SDK status.
String redactSensitive(String message) {
  final password = AppConfig.offPassword;
  if (password.isEmpty) return message;
  return message.replaceAll(password, '[redacted]');
}
