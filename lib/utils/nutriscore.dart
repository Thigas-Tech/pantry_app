import 'package:flutter/material.dart';

/// Canonical Nutri-Score colors per grade letter.
const _nutriscoreColors = {
  'a': Color(0xFF038141),
  'b': Color(0xFF85BB2F),
  'c': Color(0xFFFECB02),
  'd': Color(0xFFEE8200),
  'e': Color(0xFFE73F0B),
};

bool _isNotApplicable(String? grade) {
  return grade?.toLowerCase().trim() == 'not-applicable';
}

/// Returns the canonical Nutri-Score color for [grade], or `null` if invalid.
Color? nutriscoreColorForGrade(String? grade) {
  final g = grade?.toLowerCase().trim();
  if (g == null || g.isEmpty || g.length > 1) return null;
  return _nutriscoreColors[g];
}

/// Returns the canonical Nutri-Score color for a numeric average score.
///
/// 5 -> A (dark green), 4 -> B (light green), ..., 1 -> E (red).
/// The score is rounded to the nearest integer before mapping.
Color nutriscoreColorForNumeric(double averageScore) {
  final grade = averageScore.round().clamp(1, 5);
  return switch (grade) {
    5 => _nutriscoreColors['a']!,
    4 => _nutriscoreColors['b']!,
    3 => _nutriscoreColors['c']!,
    2 => _nutriscoreColors['d']!,
    _ => _nutriscoreColors['e']!,
  };
}

/// Converts a Nutri-Score grade letter to a numeric value for averaging.
///
/// `'a'` = 5, `'b'` = 4, ..., `'e'` = 1. Returns `null` for invalid or
/// not-applicable grades.
int? nutriscoreGradeToNumeric(String? grade) {
  if (_isNotApplicable(grade)) return null;
  return switch (grade?.toLowerCase()) {
    'a' => 5,
    'b' => 4,
    'c' => 3,
    'd' => 2,
    'e' => 1,
    _ => null,
  };
}

/// Converts a numeric Nutri-Score value to a grade letter.
///
/// 5 -> `'a'`, 4 -> `'b'`, ..., 1 -> `'e'`. Returns `null` for out-of-range
/// values.
String? nutriscoreNumericToGrade(int numeric) {
  return switch (numeric) {
    5 => 'a',
    4 => 'b',
    3 => 'c',
    2 => 'd',
    1 => 'e',
    _ => null,
  };
}

/// Converts a numeric average Nutri-Score to a display letter.
///
/// The score is rounded to the nearest integer: 5 -> `'A'`, 4 -> `'B'`, ...,
/// 1 -> `'E'`. Out-of-range values are clamped to the valid range.
String nutriscoreNumericToLetter(double averageScore) {
  final grade = averageScore.round().clamp(1, 5);
  return switch (grade) {
    5 => 'A',
    4 => 'B',
    3 => 'C',
    2 => 'D',
    _ => 'E',
  };
}

/// Returns `true` if [grade] is `'not-applicable'` (case-insensitive).
bool nutriscoreIsNotApplicable(String? grade) => _isNotApplicable(grade);
