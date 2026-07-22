import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';

/// Placeholder shown when the active inventory has no items.
///
/// Displays a prompt to scan or add the first product.
class EmptyPantry extends StatelessWidget {
  /// Creates an [EmptyPantry] with a callback to open the action sheet.
  const EmptyPantry({required this.onScan, super.key});

  /// Called when the user taps the scan-first-product button.
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
              icon: const Icon(Icons.add),
              label: Text(l10n.scanFirstProduct),
            ),
          ],
        ),
      ),
    );
  }
}
