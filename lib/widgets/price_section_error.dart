import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';

/// The fallback shown when a product's price data cannot be loaded.
///
/// Renders the section title, a localized error message, and a retry action
/// so the price section never silently disappears on a provider failure.
class PriceSectionError extends StatelessWidget {
  /// Creates a [PriceSectionError].
  const PriceSectionError({required this.onRetry, super.key});

  /// Called when the user taps the retry button.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.prices, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l10n.errorGeneric, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 4),
        TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        const Divider(height: 24),
      ],
    );
  }
}
