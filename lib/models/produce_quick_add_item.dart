import 'package:flutter/material.dart';

/// Describes where a carousel item came from.
enum ProduceItemSource {
  /// User's frequent purchase history.
  personalized,

  /// Currently in-season suggestion.
  seasonal,

  /// Generic fallback default.
  fallback,
}

/// Data for a single produce quick-add carousel tile.
class ProduceQuickAddItem {
  /// Creates a [ProduceQuickAddItem].
  const ProduceQuickAddItem({
    required this.name,
    required this.displayName,
    required this.icon,
    this.weightHintG,
    required this.source,
  });

  /// Canonical lowercase produce key (e.g. 'apple').
  final String name;

  /// Capitalized display name (e.g. 'Apple').
  final String displayName;

  /// Material icon for this produce item.
  final IconData icon;

  /// Typical weight in grams of one unit (e.g. 182 for medium apple).
  ///
  /// Null if no serving preset is available.
  final double? weightHintG;

  /// Where this item came from (personalized, seasonal, fallback).
  final ProduceItemSource source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProduceQuickAddItem &&
          name == other.name &&
          displayName == other.displayName &&
          icon == other.icon &&
          weightHintG == other.weightHintG &&
          source == other.source;

  @override
  int get hashCode => Object.hash(name, displayName, icon, weightHintG, source);
}
