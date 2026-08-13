import 'package:flutter/material.dart';

/// The visual shape of a progress indicator.
enum ProgressIndicatorType {
  /// A circular progress indicator (spinning ring).
  circular,

  /// A linear progress indicator (horizontal bar).
  linear,
}

/// Builds standardized [CircularProgressIndicator] and
/// [LinearProgressIndicator] widgets with consistent defaults.
///
/// Every method returns a widget that respects the current Material theme
/// colours when no explicit indicator colour is given.
///
/// ## Examples
///
///     // Small circular spinner (carousel chips):
///     ProgressIndicatorHelper.build(size: 16, strokeWidth: 2);
///
///     // Full-width linear bar (detail screen loading):
///     ProgressIndicatorHelper.build(type: ProgressIndicatorType.linear);
///
///     // Determinate linear with custom colour:
///     ProgressIndicatorHelper.build(
///       type: ProgressIndicatorType.linear,
///       value: 0.45,
///       color: Colors.green,
///       minHeight: 6,
///     );
class ProgressIndicatorHelper {
  const ProgressIndicatorHelper._();

  /// Default diameter for a circular indicator.
  static const double defaultSize = 36;

  /// Default stroke width for a circular indicator.
  static const double defaultStrokeWidth = 4;

  /// Default min-height for a linear indicator.
  static const double defaultMinHeight = 4;

  /// Builds a progress indicator widget.
  ///
  /// [type] — [ProgressIndicatorType.circular] (default) or
  /// [ProgressIndicatorType.linear].
  ///
  /// [value] — when non-null the indicator is determinate
  /// (showing the given progress between 0.0 and 1.0). When null
  /// the indicator is indeterminate (continuous animation).
  ///
  /// [size] — the diameter for circular indicators (default 36.0).
  /// Ignored for linear indicators.
  ///
  /// [strokeWidth] — the circular arc thickness (default 4.0).
  /// Ignored for linear indicators.
  ///
  /// [minHeight] — the linear bar minimum height (default 4.0).
  /// Ignored for circular indicators.
  ///
  /// [color] — when non-null overrides the theme's default colour
  /// for the indicator. Applied via [ProgressIndicator.color].
  ///
  /// [backgroundColor] — when non-null sets the track colour behind
  /// the indicator.
  static Widget build({
    ProgressIndicatorType type = ProgressIndicatorType.circular,
    double? value,
    double? size,
    double? strokeWidth,
    double? minHeight,
    Color? color,
    Color? backgroundColor,
  }) {
    switch (type) {
      case ProgressIndicatorType.circular:
        final diameter = size ?? defaultSize;
        return SizedBox(
          width: diameter,
          height: diameter,
          child: Center(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth ?? defaultStrokeWidth,
              color: color,
              backgroundColor: backgroundColor,
            ),
          ),
        );
      case ProgressIndicatorType.linear:
        return LinearProgressIndicator(
          value: value,
          minHeight: minHeight ?? defaultMinHeight,
          color: color,
          backgroundColor: backgroundColor,
        );
    }
  }
}
