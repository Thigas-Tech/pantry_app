import 'package:flutter/material.dart';

/// Displays the Nutri-Score grade of a product as a coloured badge.
///
/// The grade should be one of `'a'`, `'b'`, `'c'`, `'d'`, or `'e'`.
/// If the grade is `null` or invalid, nothing is rendered.
///
/// Colours follow the official Nutri-Score palette:
/// - A: dark green (#038141)
/// - B: light green (#85BB2F)
/// - C: yellow (#FECB02)
/// - D: orange (#EE8200)
/// - E: red (#E73F0B)
class NutriScoreBadge extends StatelessWidget {
  /// Creates a [NutriScoreBadge] for the given [grade].
  const NutriScoreBadge({required this.grade, this.size = 28, super.key});

  /// The Nutri-Score grade (`'a'`–`'e'`).
  final String? grade;

  /// The width and height of the badge.
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _colorForGrade(grade);
    if (color == null) return const SizedBox.shrink();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          grade!.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.55,
          ),
        ),
      ),
    );
  }

  /// Returns the Nutri-Score colour for [grade], or `null` if invalid.
  static Color? _colorForGrade(String? grade) {
    final g = grade?.toLowerCase().trim();
    if (g == null || g.isEmpty || g.length > 1) return null;
    return switch (g) {
      'a' => const Color(0xFF038141),
      'b' => const Color(0xFF85BB2F),
      'c' => const Color(0xFFFECB02),
      'd' => const Color(0xFFEE8200),
      'e' => const Color(0xFFE73F0B),
      _ => null,
    };
  }

  /// Converts a Nutri-Score grade to a numeric value for averaging.
  ///
  /// `'a'` = 5, `'b'` = 4, …, `'e'` = 1. Returns `null` for invalid grades.
  static int? toNumeric(String? grade) {
    return switch (grade?.toLowerCase()) {
      'a' => 5,
      'b' => 4,
      'c' => 3,
      'd' => 2,
      'e' => 1,
      _ => null,
    };
  }
}
