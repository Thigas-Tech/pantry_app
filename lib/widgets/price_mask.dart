import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/price_provider.dart';

/// Wraps a formatted price string and masks it when the user has enabled
/// price hiding for privacy.
///
/// When pricesHidden is true, the [child] is replaced with a fixed-width
/// bullet mask to avoid leaking the actual price length. When false, the
/// [child] is shown as-is.
class PriceMask extends ConsumerWidget {
  /// Creates a [PriceMask].
  const PriceMask({
    required this.formattedPrice,
    required this.child,
    super.key,
  });

  /// The fully-formatted price string (e.g. "R$ 15,90").
  final String formattedPrice;

  /// The widget to show when prices are not hidden.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(pricesHiddenProvider);
    if (hidden) {
      return Semantics(
        label: AppLocalizations.of(context)!.priceHidden,
        excludeSemantics: true,
        child: Text(
          String.fromCharCodes(List.filled(8, 0x2022)),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return child;
  }
}
