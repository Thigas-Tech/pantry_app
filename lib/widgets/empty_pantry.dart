import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';

/// An inviting empty‑state illustration shown when the pantry has no items.
///
/// Displays a large kitchen icon, a title, a subtitle, and a button that
/// triggers the scanning flow. This widget can be replaced later with a
/// Lottie animation or a custom illustration without changing the home
/// screen code.
class EmptyPantry extends StatelessWidget {
  /// Creates an [EmptyPantry] widget.
  const EmptyPantry({required this.onScan, super.key});

  /// Callback invoked when the user taps the scan button.
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.kitchen, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              l10n.emptyPantryTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(l10n.emptyPantrySubtitle),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(l10n.scanFirstProduct),
            ),
          ],
        ),
      ),
    );
  }
}
