import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';

/// A reusable error display with an icon, message, and retry button.
///
/// Used by screens when a provider fails to load data.
class ErrorView extends StatelessWidget {
  /// Creates an [ErrorView].
  const ErrorView({required this.message, required this.onRetry, super.key});

  /// The error message to display.
  final String message;

  /// Called when the user taps the retry button.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }
}
