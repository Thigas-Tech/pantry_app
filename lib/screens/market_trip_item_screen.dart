import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/market_trip_item_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/currency_service.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/product_package_size.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/price_entry_sheet.dart';

/// A lightweight confirmation screen shown for a market trip item.
///
/// Replaces the full product-detail screen in the trip flow so price and
/// expiry are asked exactly once per scanned (or produce-searched) product.
/// The screen shows the product, an optional price (pre-filled from the
/// latest tracked price) and an optional expiry date, then adds the product
/// to the trip as purchased through [marketTripItemControllerProvider].
///
/// The screen does not touch the price repository or the inventory tables:
/// the price is written to the shopping item and recorded into the price
/// history by the trip finish flow. It never shows the purchase-date picker
/// (the purchase date is always today) and never opens a pantry prompt.
class MarketTripItemScreen extends ConsumerStatefulWidget {
  /// Creates a [MarketTripItemScreen] for [product] in the trip scoped to
  /// [tripId].
  const MarketTripItemScreen({
    required this.product,
    required this.tripId,
    super.key,
  });

  /// The product to add to the trip.
  final Product product;

  /// The trip inventory that owns the shopping list.
  final int tripId;

  @override
  ConsumerState<MarketTripItemScreen> createState() =>
      _MarketTripItemScreenState();
}

class _MarketTripItemScreenState extends ConsumerState<MarketTripItemScreen> {
  Price? _enteredPrice;
  String? _expiryDate;
  bool _saving = false;

  Product get _product => widget.product;

  @override
  void initState() {
    super.initState();
    // Produce defaults to a 14-day expiry so fresh items are pre-filled with
    // a sensible shelf-life; the user can still change or clear it.
    if (_product.productType == ProductType.produce) {
      _expiryDate = defaultProduceExpiry().toIso8601String().substring(0, 10);
    }
  }

  /// Opens the price sheet (without the purchase-date field) for the item.
  ///
  /// The amount, currency, and store are pre-filled from the latest tracked
  /// price or from a previously entered price in this session. The tracked
  /// price is only pre-filled when price tracking is enabled.
  Future<void> _pickPrice(AppLocalizations l10n) async {
    final tracked = _trackedPrice;
    final package = productPackageSize(_product);
    final price = await PriceEntrySheet.show(
      context,
      barcode: _product.barcode,
      existingAmount: _enteredPrice?.price ?? tracked?.price,
      existingCurrency: _enteredPrice?.currency ?? tracked?.currency,
      existingStore: _enteredPrice?.store ?? tracked?.store,
      existingPackageQuantity: package?.quantity,
      existingPackageUnit: package?.unit,
      showDateField: false,
    );
    if (price != null && mounted) {
      setState(() => _enteredPrice = price);
    }
  }

  /// The latest tracked price for the item, or null when price tracking is
  /// disabled or no price has been recorded.
  Price? get _trackedPrice {
    final priceTrackingEnabled =
        ref.read(settingsProvider).value?.priceTrackingEnabled ?? false;
    if (!priceTrackingEnabled) return null;
    return ref
        .read(latestPriceProvider((_product.barcode, widget.tripId)))
        .value;
  }

  /// Picks an expiry date no earlier than today and stores it in ISO format.
  Future<void> _pickExpiry() async {
    final current = DateTime.tryParse(_expiryDate ?? '');
    final initial =
        current ??
        (_product.productType == ProductType.produce
            ? defaultProduceExpiry()
            : DateTime.now().add(const Duration(days: 7)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && mounted) {
      setState(
        () => _expiryDate = picked.toIso8601String().substring(0, 10),
      );
    }
  }

  /// Adds the product to the trip as purchased and pops the screen.
  ///
  /// The price written is the one entered in this session, falling back to
  /// the latest tracked price when the user did not touch the field. On
  /// failure a snackbar is shown and the screen stays open.
  Future<void> _confirm(AppLocalizations l10n) async {
    if (_saving) return;
    setState(() => _saving = true);
    final controller = ref.read(
      marketTripItemControllerProvider(widget.tripId).notifier,
    );
    try {
      TripItemPriceInput? price;
      if (_enteredPrice case final Price entered) {
        price = TripItemPriceInput(
          amount: entered.price,
          currency: entered.currency,
          store: entered.store,
          packageQuantity: entered.packageQuantity,
          packageUnit: entered.packageUnit,
        );
      } else if (_trackedPrice case final Price tracked) {
        price = TripItemPriceInput(
          amount: tracked.price,
          currency: tracked.currency,
          store: tracked.store,
          packageQuantity: tracked.packageQuantity,
          packageUnit: tracked.packageUnit,
        );
      }
      await controller.addScannedProduct(
        _product,
        price: price,
        expiryDate: _expiryDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Exception catch (e) {
      logError('Failed to add trip item: $e');
      if (!mounted) return;
      SnackbarHelper.showError(context, l10n.errorGeneric);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Keep the autoDispose controller alive while this screen is mounted so
    // its Ref stays usable across the async add.
    ref.watch(marketTripItemControllerProvider(widget.tripId).notifier);
    final tracked = ref
        .watch(
          latestPriceProvider((_product.barcode, widget.tripId)),
        )
        .value;
    final activePrice =
        _enteredPrice ??
        ((ref.read(settingsProvider).value?.priceTrackingEnabled ?? false)
            ? tracked
            : null);
    final title = _product.productType == ProductType.produce
        ? l10n.localizeProduceName(_product.name)
        : _product.name;

    return PopScope(
      // Block the system back button while the add is being persisted so the
      // screen (and its autoDispose controller) cannot be disposed mid-write.
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _buildProductHeader(context, l10n),
              const SizedBox(height: 16),
              _priceTile(l10n, activePrice),
              _expiryTile(l10n),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : () => unawaited(_confirm(l10n)),
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(l10n.addToTrip),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the cached product image (or network image) and the barcode.
  Widget _buildProductHeader(BuildContext context, AppLocalizations l10n) {
    final url = _product.imageUrl;
    if (url == null) {
      return Text(_product.barcode);
    }
    return Consumer(
      builder: (context, ref, _) {
        final imagePath = ref
            .watch(cachedImageProvider((url, _product.barcode)))
            .value;
        final image = imagePath != null
            ? Image.file(
                File(imagePath),
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
              )
            : Image.network(
                url,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
              );
        return Column(
          children: [
            image,
            const SizedBox(height: 8),
            Text(
              '${l10n.barcodeLabel}: ${_product.barcode}',
              style:
                  Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        );
      },
    );
  }

  /// The price row with an add/edit affordance.
  Widget _priceTile(AppLocalizations l10n, Price? activePrice) {
    final priceText = activePrice == null
        ? null
        : '${currencySymbolFor(activePrice.currency)}'
              '${activePrice.price.toStringAsFixed(2)}';
    return ListTile(
      leading: const Icon(Icons.payments_outlined),
      title: Text(l10n.price),
      subtitle: Text(priceText ?? l10n.priceNotSet),
      trailing: TextButton(
        onPressed: () => unawaited(_pickPrice(l10n)),
        child: Text(priceText != null ? l10n.editPrice : l10n.enterPrice),
      ),
    );
  }

  /// The expiry row with add and clear affordances.
  Widget _expiryTile(AppLocalizations l10n) {
    return ListTile(
      leading: const Icon(Icons.event_outlined),
      title: Text(l10n.addExpiryDate),
      subtitle: Text(_expiryDate ?? l10n.noExpiry),
      trailing: _expiryDate == null
          ? TextButton(
              onPressed: () => unawaited(_pickExpiry()),
              child: Text(l10n.addExpiryDate),
            )
          : IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.noExpiry,
              onPressed: () => setState(() => _expiryDate = null),
            ),
    );
  }
}
