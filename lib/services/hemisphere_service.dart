import 'package:pantry_app/models/hemisphere.dart';

/// Detects hemisphere from device country code and resolves
/// manual overrides.
class HemisphereService {
  HemisphereService._();

  /// ISO 3166-1 alpha-2 country codes for Southern Hemisphere countries.
  static const southernCountries = <String>{
    'AO',
    'AR',
    'AU',
    'BO',
    'BW',
    'BR',
    'CL',
    'EC',
    'ID',
    'LS',
    'MG',
    'MW',
    'MZ',
    'NA',
    'NZ',
    'PE',
    'PG',
    'PY',
    'SZ',
    'TL',
    'UY',
    'ZA',
    'ZM',
    'ZW',
  };

  /// Determines hemisphere from an ISO 3166-1 alpha-2 country code.
  ///
  /// Returns [Hemisphere.southern] if [countryCode] is in
  /// [southernCountries]. Returns [Hemisphere.northern] for all other
  /// values (including null and empty).
  static Hemisphere detectFromCountryCode(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) {
      return Hemisphere.northern;
    }
    return southernCountries.contains(countryCode.toUpperCase())
        ? Hemisphere.southern
        : Hemisphere.northern;
  }

  /// Resolves the effective hemisphere given a manual [override] and
  /// optional [countryCode].
  ///
  /// If [override] is [Hemisphere.auto], uses [detectFromCountryCode].
  /// Otherwise returns [override] directly.
  static Hemisphere resolveEffectiveHemisphere(
    Hemisphere override,
    String? countryCode,
  ) {
    if (override == Hemisphere.auto) {
      return detectFromCountryCode(countryCode);
    }
    return override;
  }
}
