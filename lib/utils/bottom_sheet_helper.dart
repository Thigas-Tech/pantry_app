import 'package:flutter/material.dart';

/// Static helper for showing consistent modal bottom sheets across the app.
///
/// All sheets are scroll-controlled and use system-safe areas for proper
/// keyboard-avoidance and system-ui respect. Use [bottomInset] for the
/// standard bottom padding that accounts for the navigation bar and keyboard.
///
/// Example:
/// ```dart
/// final result = await BottomSheetHelper.show<int>(
///   context: context,
///   builder: (ctx) => Padding(
///     padding: EdgeInsets.only(bottom: BottomSheetHelper.bottomInset(ctx)),
///     child: Column(mainAxisSize: MainAxisSize.min, children: [...]),
///   ),
/// );
/// ```
class BottomSheetHelper {
  BottomSheetHelper._();

  /// Shows a modal bottom sheet with standard parameters.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool useSafeArea = true,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: useSafeArea,
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
      builder: builder,
    );
  }

  /// Combined bottom inset including the system navigation bar and the
  /// keyboard height. Use as the bottom padding of a sheet's outermost widget
  /// to prevent content from being hidden behind the keyboard.
  ///
  /// Returns `padding.bottom + viewInsets.bottom`.
  static double bottomInset(BuildContext context) {
    final media = MediaQuery.of(context);
    return media.padding.bottom + media.viewInsets.bottom;
  }
}
