import 'package:flutter/material.dart';

/// An inviting empty‑state illustration shown when the pantry has no items.
///
/// Displays a large kitchen icon, a title, a subtitle, and a button that
/// triggers the scanning flow. This widget can be replaced later with a
// ignore: comment_references
/// [Lottie] animation or a custom illustration without changing the home
/// screen code.
class EmptyPantry extends StatelessWidget {
  /// Creates an [EmptyPantry] widget.
  const EmptyPantry({required this.onScan, super.key});

  /// Callback invoked when the user taps the scan button.
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.kitchen, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Your pantry is empty',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('Tap the button below to scan your first product'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan a barcode'),
            ),
          ],
        ),
      ),
    );
  }
}
