import 'package:flutter/material.dart';
import 'package:pantry_app/widgets/coming_soon_view.dart';

/// A full-screen placeholder for features not yet implemented.
///
/// Wraps [ComingSoonView] in a [Scaffold] with an [AppBar] so it can be
/// used directly as a navigation target (e.g. a tab in a [PageView]).
///
/// A full-screen placeholder for features that are not yet implemented.
class ComingSoonScreen extends StatelessWidget {
  /// Creates a [ComingSoonScreen].
  ///
  /// [title] is shown in both the [AppBar] and the body. [subtitle] and
  /// [icon] are forwarded to [ComingSoonView].
  const ComingSoonScreen({
    required this.title,
    this.subtitle,
    this.icon = Icons.construction,
    super.key,
  });

  /// The title shown in the [AppBar] and in the [ComingSoonView] body.
  final String title;

  /// An optional subtitle shown below the title in the body.
  final String? subtitle;

  /// The icon displayed above the title.
  ///
  /// Defaults to [Icons.construction].
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ComingSoonView(title: title, subtitle: subtitle, icon: icon),
    );
  }
}
