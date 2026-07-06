import 'package:flutter/material.dart';

/// A reusable placeholder that indicates a feature is under development.
///
/// Displays a configurable icon, a title, and an optional subtitle. Use
/// inline inside an existing layout or wrap with `ComingSoonScreen` for a
/// full-screen placeholder with an [AppBar].
///
/// ## Usage
///
/// ```dart
/// // Inline -- inside a [Column] or [ListView] child.
/// const ComingSoonView(title: 'Shopping list');
///
/// // Full screen -- with an AppBar.
/// ComingSoonScreen(title: 'Stats', subtitle: 'Available soon.');
/// ```
class ComingSoonView extends StatelessWidget {
  /// Creates a [ComingSoonView].
  const ComingSoonView({
    required this.title,
    this.subtitle,
    this.icon = Icons.construction,
    super.key,
  });

  /// The title displayed below the icon.
  final String title;

  /// An optional subtitle displayed below the title.
  final String? subtitle;

  /// The icon displayed above the title.
  ///
  /// Defaults to [Icons.construction].
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
