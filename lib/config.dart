import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration.
///
/// Credentials are read from a .env file loaded by [DotEnv] for local
/// development only; the .env file is **not** a Flutter asset, so nothing
/// sensitive is bundled into release builds. Non-secret feature toggles
/// fall back to `--dart-define` build flags set by CI.
///
/// ## Security note
///
/// - The .env file is **never** committed to version control and **never**
///   shipped in an app artifact.
/// - Credential-backed features (OFF product submission, Open Prices,
///   USDA) are disabled when their credential is absent.
///
/// This class cannot be instantiated — all members are static.
class AppConfig {
  AppConfig._();

  /// The Open Food Facts user ID used for product submissions.
  ///
  /// Set to a non‑empty string in .env to enable product‑submission
  /// features. Leave empty to disable submissions.
  static String get offUserId => dotenv.env['OFF_USER_ID'] ?? '';

  /// The Open Food Facts password used for product submissions.
  ///
  /// Must be set alongside [offUserId]. Leave empty to disable submissions.
  static String get offPassword => dotenv.env['OFF_PASSWORD'] ?? '';

  /// A contact email address included in the User‑Agent header sent to
  /// Open Food Facts (required by their API terms).
  static String get contactEmail =>
      dotenv.env['CONTACT_EMAIL'] ?? 'pantry-app@example.com';

  /// Whether to use the Open Food Facts staging server (true) or the
  /// production server (false).
  static bool get useOffStaging {
    final env = dotenv.env['USE_OFF_STAGING'];
    if (env != null) return env.toLowerCase() == 'true';
    return const String.fromEnvironment('USE_OFF_STAGING') == 'true';
  }

  /// The Bearer token for the Open Prices API.
  ///
  /// Generate at https://prices.openfoodfacts.org/settings/tokens
  /// Leave empty to disable all Open Prices API features (local-only mode).
  static String get openPricesToken => dotenv.env['OPEN_PRICES_TOKEN'] ?? '';

  /// The Imgur Client-ID used for anonymous image uploads.
  ///
  /// Register at https://api.imgur.com/oauth2/addclient to obtain one.
  /// Leave empty to skip screenshot upload (issue still submits without
  /// images).
  static String get imgurClientId => dotenv.env['IMGUR_CLIENT_ID'] ?? '';

  /// The USDA FoodData Central API key.
  ///
  /// Register for free at https://fdc.nal.usda.gov/api-key-signup.html.
  /// Leave empty to disable USDA API fallback for produce searches.
  static String get usdaApiKey => dotenv.env['USDA_API_KEY'] ?? '';
}
