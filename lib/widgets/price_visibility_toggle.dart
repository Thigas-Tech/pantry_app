import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/price_mask.dart';

/// An eye icon button that toggles price visibility.
///
/// Reads from [pricesHiddenProvider] and writes to [settingsProvider].
/// When tapped, all [PriceMask] widgets react instantly.
class PriceVisibilityToggle extends ConsumerWidget {
  /// Creates a [PriceVisibilityToggle].
  const PriceVisibilityToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(pricesHiddenProvider);
    final l10n = AppLocalizations.of(context)!;

    return IconButton(
      icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
      tooltip: hidden ? l10n.showPrices : l10n.hidePrices,
      onPressed: () {
        ref.read(settingsProvider.notifier).setPricesHidden(value: !hidden);
        SnackbarHelper.showInfo(
          context,
          hidden ? l10n.pricesVisible : l10n.pricesHidden,
        );
      },
    );
  }
}
