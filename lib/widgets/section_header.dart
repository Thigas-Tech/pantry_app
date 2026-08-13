import 'package:flutter/material.dart';

/// A header row shown above each expiry group on the home screen.
class SectionHeader extends StatelessWidget {
  /// Creates a [SectionHeader] with [title] and [icon].
  const SectionHeader({
    required this.title,
    required this.icon,
    super.key,
  });

  /// The section title (localized).
  final String title;

  /// The leading icon for the section.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
