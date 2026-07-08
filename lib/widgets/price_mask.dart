import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/providers/price_provider.dart';

/// Wraps a formatted price string and masks it when the user has enabled
/// price hiding for privacy.
///
/// When pricesHidden is true, the [child] is replaced with a string of
/// asterisks of the same visible length. When false, the [child] is shown
/// as-is.
///
/// Usage:
/// ```dart
/// PriceMask(
///   formattedPrice: repo.formatPrice(price, currency),
///   child: Text(formattedPrice, style: ...),
/// )
/// ```
class PriceMask extends ConsumerWidget {
  /// Creates a [PriceMask].
  const PriceMask({
    required this.formattedPrice,
    required this.child,
    super.key,
  });

  /// The fully-formatted price string (e.g. `"R$ 15,90"`).
  final String formattedPrice;

  /// The widget to show when prices are not hidden.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(pricesHiddenProvider);
    if (hidden) {
      final mask = String.fromCharCodes(
        List.filled(formattedPrice.length, 0x2022),
      );
      return Text(
        mask,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return child;
  }
}
