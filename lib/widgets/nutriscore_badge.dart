import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/nutriscore.dart';

/// Displays the Nutri-Score grade of a product as a coloured badge.
///
/// The grade should be one of 'a', 'b', 'c', 'd', or 'e'.
/// If the grade is null or invalid, nothing is rendered.
///
/// When the grade is 'not-applicable' a grey dashed badge is shown,
/// indicating that the Nutri-Score system does not apply to this product
/// category (e.g. food additives).
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

  /// The Nutri-Score grade ('a'–'e' or 'not-applicable').
  final String? grade;

  /// The width and height of the badge.
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isNotApplicable(grade)) {
      return Semantics(
        label: l10n.nutriscoreNotApplicableSemantics,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey.shade500,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '—',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.55,
              ),
            ),
          ),
        ),
      );
    }

    final color = _colorForGrade(grade);
    if (color == null) return const SizedBox.shrink();
    return Semantics(
      label: l10n.nutriscoreGradeSemantics(grade!.toUpperCase()),
      child: Container(
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
      ),
    );
  }

  /// Returns true if the [grade] is 'not-applicable'.
  static bool isNotApplicable(String? grade) {
    return nutriscoreIsNotApplicable(grade);
  }

  /// Returns the Nutri-Score colour for [grade], or null if invalid.
  static Color? _colorForGrade(String? grade) {
    return nutriscoreColorForGrade(grade);
  }

  /// Returns true if [grade] is 'not-applicable' (case‑insensitive).
  static bool _isNotApplicable(String? grade) {
    return nutriscoreIsNotApplicable(grade);
  }

  /// Converts a Nutri-Score grade to a numeric value for averaging.
  ///
  /// 'a' = 5, 'b' = 4, …, 'e' = 1. Returns null for invalid or
  /// not‑applicable grades.
  static int? toNumeric(String? grade) {
    return nutriscoreGradeToNumeric(grade);
  }
}
