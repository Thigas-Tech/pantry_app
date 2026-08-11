import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/widgets/price_mask.dart';

/// Displays the per-unit price of a [Price] (e.g. "R$ 0,83/unit") below
/// the flat package price.
///
/// Renders nothing when the price carries no usable package size, so cards
/// and history rows without packaging data are unchanged. The label is
/// wrapped in a [PriceMask] so privacy hiding applies to it as well.
class UnitPriceLabel extends ConsumerWidget {
  /// Creates a [UnitPriceLabel] for the given [price].
  const UnitPriceLabel({required this.price, this.style, super.key});

  /// The price observation whose package size drives the label.
  final Price price;

  /// Optional text style; defaults to the body-small theme style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(priceRepositoryProvider);
    final label = repo.unitPriceLabel(
      price,
      perPiece: l10n.pricePerPiece,
      perHundredGrams: l10n.pricePerHundredGrams,
      perKilogram: l10n.pricePerKilogram,
      perLiter: l10n.pricePerLiter,
      perHundredMilliliters: l10n.pricePerHundredMilliliters,
    );
    if (label == null) return const SizedBox.shrink();

    final effectiveStyle =
        style ??
        Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor);
    return PriceMask(
      formattedPrice: label,
      child: Text(label, style: effectiveStyle),
    );
  }
}
