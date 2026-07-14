import 'package:flutter/services.dart';

/// A [TextInputFormatter] that implements a POS-style price calculator.
///
/// Always displays the amount with 2 decimal places. Each typed digit shifts
/// the value left (cents), and backspace shifts right.
///
/// Example:
///   Initial: `0.00`
///   Type `1` => `0.01`
///   Type `5` => `0.15`
///   Type `0` => `1.50`
///   Backspace => `0.15`
class PriceCalculatorFormatter extends TextInputFormatter {
  /// Creates a formatter that uses [separator] between integer and fraction.
  PriceCalculatorFormatter(this.separator);

  /// The decimal separator character (`.` or `,`).
  final String separator;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return TextEditingValue(
        text: '0${separator}00',
        selection: const TextSelection.collapsed(offset: 4),
      );
    }
    final padded = digits.padLeft(3, '0');
    final intPart = int.parse(
      padded.substring(0, padded.length - 2),
    ).toString();
    final fracPart = padded.substring(padded.length - 2);
    final formatted = '$intPart$separator$fracPart';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
