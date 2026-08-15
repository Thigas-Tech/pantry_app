import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration.
///
/// Credentials are read from a .env file loaded by [DotEnv] for local
/// development, or injected at build time via `--dart-define-from-file=.env`
/// for device and release builds (the CI release workflow recreates .env from
/// GitHub secrets). The .env file is **never** committed to version control
/// and **never** shipped as a plaintext Flutter asset; injected values are
/// compiled into the binary instead.
///
/// ## Credential model
///
/// - The USDA FoodData Central key is a public client key (sent in every
///   request URL), so embedding it is standard practice.
/// - The Open Food Facts user/password follow the SDK's supported "global
///   user for your app" model (see the openfoodfacts-dart account guide):
///   one dedicated app account carries submissions. Prefer a dedicated
///   account over a personal one.
/// - Credential-backed features (OFF product submission, Open Prices,
///   USDA) are disabled when their credential is absent, so a build made
///   without the flags degrades gracefully instead of failing.
///
/// This class cannot be instantiated — all members are static.
class AppConfig {
  AppConfig._();

  /// The Open Food Facts user ID used for product submissions.
  ///
  /// Read from the `OFF_USER_ID` dart-define at build time, falling back to
  /// .env for local development. Leave empty to disable submissions.
  static String get offUserId {
    const fromEnv = String.fromEnvironment('OFF_USER_ID');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['OFF_USER_ID'] ?? '';
  }

  /// The Open Food Facts password used for product submissions.
  ///
  /// Read from the `OFF_PASSWORD` dart-define at build time, falling back to
  /// .env for local development. Must be set alongside [offUserId].
  static String get offPassword {
    const fromEnv = String.fromEnvironment('OFF_PASSWORD');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['OFF_PASSWORD'] ?? '';
  }

  /// A contact email address included in the User‑Agent header sent to
  /// Open Food Facts (required by their API terms).
  static String get contactEmail {
    const fromEnv = String.fromEnvironment('CONTACT_EMAIL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['CONTACT_EMAIL'] ?? 'pantry-app@example.com';
  }

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
  /// Read from the `USDA_API_KEY` dart-define at build time, falling back to
  /// .env for local development. Leave empty to disable USDA produce
  /// searches and serving-size enrichment.
  static String get usdaApiKey {
    const fromEnv = String.fromEnvironment('USDA_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['USDA_API_KEY'] ?? '';
  }
}
