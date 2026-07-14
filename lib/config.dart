import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from a `.env` file at startup.
///
/// All sensitive values (API credentials, contact email, etc.) are read from
/// environment variables loaded by `flutter_dotenv`. A `.env.example` file is
/// provided as a template; copy it to `.env` and fill in real values.
///
/// ## Security note
///
/// - The `.env` file is **never** committed to version control.
/// - `.env.example` contains placeholder values and IS committed.
/// - These values are embedded in the app bundle at build time.
///
/// This class cannot be instantiated — all members are static.
class AppConfig {
  AppConfig._();

  /// The Open Food Facts user ID used for product submissions.
  ///
  /// Set to a non‑empty string in `.env` to enable product‑submission
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

  /// Whether to use the Open Food Facts staging server (`true`) or the
  /// production server (`false`).
  static bool get useOffStaging =>
      dotenv.env['USE_OFF_STAGING']?.toLowerCase() == 'true';

  /// The GitHub personal access token used for in-app feedback submissions.
  ///
  /// Must have `Issues: Read and write` permission on the repository
  /// specified by [githubOwner] and [githubRepo].
  static String get feedbackToken => dotenv.env['FEEDBACK_TOKEN'] ?? '';

  /// The GitHub repository owner for in-app feedback submissions.
  static String get githubOwner => dotenv.env['GITHUB_OWNER'] ?? 'Thigas-Tech';

  /// The GitHub repository name for in-app feedback submissions.
  static String get githubRepo => dotenv.env['GITHUB_REPO'] ?? 'pantry_app';

  /// Whether in-app feedback submission is enabled.
  static bool get feedbackEnabled =>
      (dotenv.env['FEEDBACK_ENABLED'] ?? 'true').toLowerCase() == 'true';

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
