/// The hemisphere used for seasonal produce calculations.
enum Hemisphere {
  /// Automatically detect from device locale country code.
  auto,

  /// Northern Hemisphere (spring Mar-May, summer Jun-Aug, etc.)
  northern,

  /// Southern Hemisphere (spring Sep-Nov, summer Dec-Feb, etc.)
  southern,
}
