import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/market_trip_item_provider.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

/// A lightweight confirmation screen shown for a market trip item.
///
/// Replaces the full product-detail screen in the trip flow so expiry is
/// asked exactly once per scanned product. The screen shows the product and
/// an optional expiry date, then adds the product to the trip as purchased
/// through [marketTripItemControllerProvider].
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
  String? _expiryDate;
  bool _saving = false;

  Product get _product => widget.product;

  @override
  void initState() {
    super.initState();
  }

  /// Picks an expiry date no earlier than today and stores it in ISO format.
  Future<void> _pickExpiry() async {
    final current = DateTime.tryParse(_expiryDate ?? '');
    final initial = current ?? DateTime.now().add(const Duration(days: 7));
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
  /// On failure a snackbar is shown and the screen stays open.
  Future<void> _confirm(AppLocalizations l10n) async {
    if (_saving) return;
    setState(() => _saving = true);
    final controller = ref.read(
      marketTripItemControllerProvider(widget.tripId).notifier,
    );
    try {
      await controller.addScannedProduct(
        _product,
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
    final title = _product.name;

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
