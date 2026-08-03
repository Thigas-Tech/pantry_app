import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/price.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/price_provider.dart';
import 'package:pantry_app/providers/price_repository_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/screens/add_to_inventory_screen.dart';
import 'package:pantry_app/screens/price_history_screen.dart';
import 'package:pantry_app/services/produce_serving_presets.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/quantity_parser.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/utils/unit_conversion.dart';
import 'package:pantry_app/utils/unit_resolver.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';
import 'package:pantry_app/widgets/nutrition_table.dart';
import 'package:pantry_app/widgets/price_entry_sheet.dart';
import 'package:pantry_app/widgets/price_mask.dart';
import 'package:pantry_app/widgets/price_visibility_toggle.dart';
import 'package:pantry_app/widgets/quantity_and_pantry_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

/// Displays full product details and the associated inventory entries
/// for the currently active pantry.
///
/// This screen is reached after scanning a known barcode or tapping an
/// inventory card on the home screen. It shows:
/// - Product image (if available), animated with a [Hero] transition.
/// - All nutritional information (per 100 g / 100 ml) presented in a styled
///   [Table] with alternating row colours.
/// - The ingredients list, collapsed by default.
/// - A list of existing inventory items for this product, scoped to the
///   active pantry (managed via [activeInventoryProvider]).
/// - An "Add to Inventory" button that opens the [AddToInventoryScreen]
///   and creates the item inside the active pantry.
/// - A button in the app bar that opens the product’s page on Open Food Facts.
///
/// ## State
///
/// The screen is a [ConsumerStatefulWidget] because it needs to rebuild the
/// inventory list after adding, editing, or deleting an item. A simple
/// counter _inventoryVersion is incremented after every mutation; it is
/// used as the [ValueKey] of the [FutureBuilder] so that the future is
/// re‑evaluated and the list refreshes.
///
/// ## Expiry suggestions
///
/// When adding a new item, the screen looks at the product’s [Product.category]
/// and suggests a default expiry date:
/// - **Dairy** → today + 7 days.
/// - **Bread** → today + 3 days.
/// - Other categories → no suggestion (user picks manually).
///
/// ## Notifications
///
/// After an item is created or updated,
/// expiry reminders are scheduled. When an item is
/// deleted, the corresponding reminders are cancelled.
class ProductDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [ProductDetailScreen] for the given [product].
  const ProductDetailScreen({required this.product, super.key});

  /// The product to display details for.
  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  /// Incremented after every inventory mutation to force the [FutureBuilder]
  /// to re‑fetch the inventory list.
  int _inventoryVersion = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final activeId = ref.watch<int>(activeInventoryProvider);
    final repo = ref.watch(productRepositoryProvider);
    final inventoryFuture = repo.getInventoryForBarcode(
      widget.product.barcode,
      inventoryId: activeId,
    );

    final priceTrackingEnabled = ref.watch(
      settingsProvider.select((s) => s.priceTrackingEnabled),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.productType == ProductType.produce
              ? l10n.localizeProduceName(widget.product.name)
              : widget.product.name,
        ),
        actions: [
          if (priceTrackingEnabled) const PriceVisibilityToggle(),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: l10n.viewOnOpenFoodFacts,
            onPressed: () async {
              final url = Uri.parse(
                'https://world.openfoodfacts.org/product/${widget.product.barcode}',
              );
              logInfo('Opening OFF page for ${widget.product.barcode}');
              if (await canLaunchUrl(url) && context.mounted) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
                logInfo('OFF page opened successfully');
              } else if (context.mounted) {
                logWarning('Failed to launch OFF page');
                SnackbarHelper.showError(context, l10n.couldNotOpenLink);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Product image wrapped in Hero, loaded from cache when possible.
            if (widget.product.imageUrl != null)
              Hero(
                tag: 'detail_${widget.product.barcode}',
                child: Consumer(
                  builder: (context, ref, _) {
                    final imageCache = ref.read(imageCacheProvider);
                    return FutureBuilder<String?>(
                      future: imageCache.cacheImage(
                        widget.product.imageUrl,
                        widget.product.barcode,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return ClipRect(
                            child: InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 3,
                              child: Image.file(
                                File(snapshot.data!),
                                height: 200,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 48),
                              ),
                            ),
                          );
                        }
                        return ClipRect(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 3,
                            child: Image.network(
                              widget.product.imageUrl!,
                              height: 200,
                              cacheWidth:
                                  (MediaQuery.sizeOf(context).width *
                                          MediaQuery.devicePixelRatioOf(
                                            context,
                                          ))
                                      .round(),
                              cacheHeight:
                                  (200 * MediaQuery.devicePixelRatioOf(context))
                                      .round(),
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: ProgressIndicatorHelper.build(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            _infoRow(l10n.barcodeLabel, widget.product.barcode),
            if (widget.product.languageCode !=
                Localizations.localeOf(context).languageCode)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ActionChip(
                  avatar: const Icon(Icons.language, size: 18),
                  label: Text(
                    l10n.showInLanguage(
                      Localizations.localeOf(
                        context,
                      ).languageCode.toUpperCase(),
                    ),
                  ),
                  onPressed: () async {
                    final currentLocale = Localizations.localeOf(
                      context,
                    ).languageCode;
                    try {
                      final product = await repo.getProduct(
                        widget.product.barcode,
                        languageCode: currentLocale,
                      );
                      if (context.mounted) {
                        await repo.cacheProduct(product);
                        if (!context.mounted) return;
                        setState(() {});
                        SnackbarHelper.showInfo(context, l10n.productUpdated);
                      }
                    } on Exception catch (e) {
                      logError('Failed to switch product language: $e');
                      if (context.mounted) {
                        SnackbarHelper.showError(context, e.toString());
                      }
                    }
                  },
                ),
              ),
            if (widget.product.nutriscoreGrade != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 100),
                    NutriScoreBadge(
                      grade: widget.product.nutriscoreGrade,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          NutriScoreBadge.isNotApplicable(
                            widget.product.nutriscoreGrade,
                          )
                          ? () {
                              final category = _formatCategory(
                                widget.product.nutriscoreNotApplicableCategory,
                              );
                              return category.isNotEmpty
                                  ? l10n.nutriscoreNotApplicable(category)
                                  : l10n.nutriscoreNotApplicableGeneric;
                            }()
                          : l10n.nutriscoreExplanation,
                      child: Icon(
                        Icons.help_outline,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.product.brand != null)
              _infoRow(l10n.brandLabel, widget.product.brand!),
            if (widget.product.category != null)
              _infoRow(l10n.categoryLabel, widget.product.category!),
            if (widget.product.source == 'manual') _buildSubmissionStatus(l10n),
            const Divider(),
            _infoRow(l10n.servingSize, _displayServingSize(l10n, settings)),

            // Nutrition table
            NutritionTable(product: widget.product),

            const Divider(),
            if (widget.product.ingredients != null)
              ExpansionTile(
                title: Text(l10n.ingredients),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(widget.product.ingredients!),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Price section
            _buildPriceSection(context, l10n),
            const SizedBox(height: 16),

            // Inventory section header
            Text(
              l10n.yourInventory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Inventory list (rebuilds when _inventoryVersion changes)
            FutureBuilder<List<InventoryItem>>(
              key: ValueKey(_inventoryVersion),
              future: inventoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: ProgressIndicatorHelper.build());
                }
                if (snapshot.hasError) {
                  logError('Error fetching inventory: ${snapshot.error}');
                  return Center(
                    child: Text(l10n.failedToLoadInventoryItems),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Text(l10n.noItemsInPantry);
                }
                return Column(
                  children: items.map(_buildInventoryTile).toList(),
                );
              },
            ),
            const SizedBox(height: 16),

            // Add to Inventory button
            ElevatedButton.icon(
              onPressed: _openAddEditScreen,
              icon: const Icon(Icons.add),
              label: Text(l10n.addToInventory),
            ),
            const SizedBox(height: 8),

            // Add to shopping list button
            OutlinedButton.icon(
              onPressed: () {
                final item = ShoppingItem(
                  name: widget.product.name,
                  barcode: widget.product.barcode,
                );
                unawaited(addShoppingItem(ref, item));
                SnackbarHelper.showInfo(
                  context,
                  l10n.addToShoppingList,
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(l10n.addToShoppingList),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the price section with latest price, add/edit, and history.
  Widget _buildPriceSection(BuildContext context, AppLocalizations l10n) {
    final barcode = widget.product.barcode;
    final priceAsync = ref.watch(latestPriceProvider(barcode));

    return priceAsync.when(
      data: (price) {
        if (price != null) {
          return _buildPriceData(context, l10n, price);
        }
        return _buildNoPriceData(context, l10n);
      },
      loading: () => const SizedBox(height: 48),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildPriceData(
    BuildContext context,
    AppLocalizations l10n,
    Price price,
  ) {
    final formattedPrice = ref
        .read(priceRepositoryProvider)
        .formatPrice(
          price.price,
          price.currency,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.prices, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        PriceMask(
          formattedPrice: formattedPrice,
          child: Text(
            formattedPrice,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (price.store != null)
          Text(
            price.store!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _editPrice(context, price),
              icon: const Icon(Icons.edit, size: 18),
              label: Text(l10n.editPrice),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _openPriceHistory(context),
              icon: const Icon(Icons.history, size: 18),
              label: Text(l10n.priceHistory),
            ),
          ],
        ),
        const Divider(height: 24),
      ],
    );
  }

  Widget _buildNoPriceData(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.prices, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          l10n.noPrices,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _addPrice(context),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.addPrice),
        ),
        const Divider(height: 24),
      ],
    );
  }

  Future<void> _addPrice(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final price = await PriceEntrySheet.show(
      context,
      barcode: widget.product.barcode,
    );
    if (price != null) {
      try {
        await ref.read(productRepositoryProvider).cacheProduct(widget.product);
        await ref.read(priceRepositoryProvider).addPrice(price);
        if (!context.mounted) return;
        ref
          ..invalidate(latestPriceProvider(widget.product.barcode))
          ..invalidate(priceHistoryProvider(widget.product.barcode));

        if (price.datePurchased != null &&
            price.store != null &&
            price.store!.isNotEmpty) {
          final repo = ref.read(productRepositoryProvider);
          final activeId = ref.read(activeInventoryProvider);
          final existingItems = await repo.getInventoryForBarcode(
            widget.product.barcode,
            inventoryId: activeId,
          );
          if (context.mounted && existingItems.isEmpty) {
            final result = await QuantityAndPantrySheet.show(context);
            if (result != null && context.mounted) {
              final item = InventoryItem(
                barcode: widget.product.barcode,
                inventoryId: result.inventoryId,
                quantity: result.quantity,
              );
              await repo.cacheProduct(widget.product);
              final newId = await repo.addInventoryItem(item);
              final savedItem = item.copyWith(id: newId);
              final notificationService = ref.read(
                notificationServiceProvider,
              );
              await notificationService.scheduleExpiryReminders(
                savedItem,
                productName: widget.product.name,
                expiringSoonTitle: l10n.expiringSoon,
                buildExpiringSoonBody: l10n.expiresTomorrow,
                expiringTodayTitle: l10n.expiringToday,
                buildExpiringTodayBody: l10n.expiresToday,
                channelName: l10n.expiryChannelName,
                channelDescription: l10n.expiryChannelDescription,
              );
              await _rescheduleInactivityReminder();
              if (context.mounted) {
                SnackbarHelper.showInfo(context, l10n.itemAdded);
              }
            } else if (context.mounted) {
              SnackbarHelper.showInfo(context, l10n.addToPantrySkipped);
            }
          } else if (context.mounted) {
            SnackbarHelper.showInfo(context, l10n.priceAdded);
          }
        } else if (context.mounted) {
          SnackbarHelper.showInfo(context, l10n.priceAdded);
        }
      } on Exception catch (e) {
        logError('Failed to add price: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _editPrice(BuildContext context, Price price) async {
    final l10n = AppLocalizations.of(context)!;
    final updated = await PriceEntrySheet.show(
      context,
      barcode: widget.product.barcode,
      existingPrice: price,
    );
    if (updated != null) {
      try {
        await ref.read(priceRepositoryProvider).updatePrice(updated);
        if (context.mounted) {
          SnackbarHelper.showInfo(context, l10n.priceUpdated);
          ref
            ..invalidate(latestPriceProvider(widget.product.barcode))
            ..invalidate(priceHistoryProvider(widget.product.barcode));
        }
      } on Exception catch (e) {
        logError('Failed to update price: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, e.toString());
        }
      }
    }
  }

  Future<void> _openPriceHistory(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PriceHistoryScreen(
          barcode: widget.product.barcode,
          productName: widget.product.name,
        ),
      ),
    );
  }

  /// Builds an [_InventoryTile] for the given [item].
  Widget _buildInventoryTile(InventoryItem item) {
    return Dismissible(
      key: ValueKey('prod-detail-inv-${item.id ?? item.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item),
      child: _InventoryTile(
        item: item,
        settings: ref.read(settingsProvider),
        onEdit: () => _openAddEditScreen(existing: item),
        onDelete: () => _deleteItem(item),
        onQuantityChanged: (newQty) => _updateQuantity(item, newQty),
      ),
    );
  }

  /// Formats an API-style category tag for human display.
  ///
  /// Strips the language prefix (e.g. en:) and replaces hyphens with
  /// spaces so that 'en:food-additives' becomes 'food additives'.
  static String _formatCategory(String? tag) {
    if (tag == null || tag.isEmpty) return '';
    final withoutPrefix = tag.contains(':') ? tag.split(':').last : tag;
    return withoutPrefix.replaceAll('-', ' ');
  }

  /// Builds a chip showing the OFF submission status for manual products.
  Widget _buildSubmissionStatus(AppLocalizations l10n) {
    final status = widget.product.submissionStatus;
    final chip = switch (status) {
      productSubmissionSubmitted => Chip(
        avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
        label: Text(l10n.submissionSubmitted),
      ),
      productSubmissionFailed => Chip(
        avatar: const Icon(Icons.error, size: 18, color: Colors.red),
        label: Text(l10n.submissionFailed),
        deleteIcon: const Icon(Icons.refresh, size: 18),
        onDeleted: _retrySubmission,
      ),
      productSubmissionPending => Chip(
        avatar: ProgressIndicatorHelper.build(size: 16, strokeWidth: 2),
        label: Text(l10n.submissionPending),
      ),
      _ => Chip(
        avatar: const Icon(Icons.cloud_upload, size: 18, color: Colors.grey),
        label: Text(l10n.submissionNotSubmitted),
        deleteIcon: const Icon(Icons.refresh, size: 18),
        onDeleted: _retrySubmission,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: chip,
    );
  }

  Future<void> _retrySubmission() async {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.read(productSubmissionServiceProvider);
    final result = await service.submitProduct(widget.product);
    if (mounted) {
      if (result.submissionStatus == productSubmissionSubmitted) {
        SnackbarHelper.showInfo(context, l10n.submissionSuccess);
      } else {
        SnackbarHelper.showError(context, l10n.submissionError);
      }
    }
  }

  /// Returns the serving size to display, using preset data for produce items
  /// that lack a serving size, or "100 g" when no preset is available.
  /// Converts to the user's preferred unit system.
  String _displayServingSize(AppLocalizations l10n, Settings settings) {
    // Try structured serving data first
    if (widget.product.servingQuantity != null &&
        widget.product.servingQuantity! > 0 &&
        widget.product.servingSize != null &&
        widget.product.servingSize!.isNotEmpty) {
      final parsed = QuantityParser.parseServing(
        servingQuantity: widget.product.servingQuantity,
        servingSize: widget.product.servingSize,
      );
      if (parsed != null) {
        final system = UnitResolver.systemFor(
          settings: settings,
          context: UnitContext.servingSize,
        );
        if (system == UnitSystem.imperial) {
          final converted = UnitConverter.displayUnit(
            parsed.amount,
            parsed.unit,
            UnitSystem.imperial,
            weightPref: settings.preferredWeightUnit,
            volumePref: settings.preferredVolumeUnit,
          );
          return '${converted.quantity} ${converted.unit}';
        }
        return '${parsed.amount} ${parsed.unit}';
      }
    }

    // Fallback to raw servingSize string for display only
    if (widget.product.servingSize != null) return widget.product.servingSize!;

    if (widget.product.productType == ProductType.produce) {
      final presets = ProduceServingPresets.forName(widget.product.name);
      if (presets != null) {
        final medium = presets['Medium'];
        if (medium != null) {
          final system = UnitResolver.systemFor(
            settings: settings,
            context: UnitContext.servingSize,
          );
          if (system == UnitSystem.imperial) {
            final converted = UnitConverter.displayUnit(
              medium,
              'g',
              UnitSystem.imperial,
              weightPref: settings.preferredWeightUnit,
            );
            return '1 ${l10n.servingMedium.toLowerCase()}'
                ' (${converted.quantity} ${converted.unit})';
          }
          return '1 ${l10n.servingMedium.toLowerCase()} (${medium.toInt()} g)';
        }
      }
      return '100 g';
    }
    return 'N/A';
  }

  /// Builds a simple label‑value row used for non‑nutrition product information
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:')),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Cancels any pending inactivity reminder and re-schedules based on the
  /// latest product-add date from the database.
  Future<void> _rescheduleInactivityReminder() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.cancelInactivityReminder();
      final db = ref.read(databaseProvider);
      final lastAddDateEpoch = await db.getLastAddDate();
      final settings = ref.read(settingsProvider);
      await notificationService.scheduleInactivityReminder(
        lastAddDateEpoch: lastAddDateEpoch,
        thresholdDays: settings.inactivityThresholdDays,
        title: l10n.inactivityReminderTitle,
        buildBody: l10n.inactivityReminderBody,
        channelName: l10n.inactivityReminderChannelName,
        channelDescription: l10n.inactivityReminderChannelDescription,
        notificationsEnabled: settings.notificationsEnabled,
      );
    } on Exception catch (e) {
      logError('Failed to reschedule inactivity reminder: $e');
    }
  }

  /// Opens the [AddToInventoryScreen] for creating or editing an item.
  Future<void> _openAddEditScreen({InventoryItem? existing}) async {
    final activeId = ref.read<int>(activeInventoryProvider);

    // Suggest an expiry date based on the product category.
    String? suggested;
    if (existing == null && widget.product.category != null) {
      final cat = widget.product.category!.toLowerCase();
      if (cat.contains('dairy')) {
        suggested = DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String()
            .substring(0, 10);
      } else if (cat.contains('bread')) {
        suggested = DateTime.now()
            .add(const Duration(days: 3))
            .toIso8601String()
            .substring(0, 10);
      }
    }

    final result = await Navigator.of(context).push<InventoryItem>(
      MaterialPageRoute(
        builder: (_) => AddToInventoryScreen(
          barcode: widget.product.barcode,
          existingItem: existing,
          suggestedExpiry: suggested,
          inventoryId: activeId,
          productType: widget.product.productType,
          produceName: widget.product.name,
          product: widget.product,
        ),
      ),
    );

    if (result != null && mounted) {
      final l10n = AppLocalizations.of(context)!;
      final repo = ref.read(productRepositoryProvider);
      final notificationService = ref.read(notificationServiceProvider);
      try {
        if (existing != null) {
          logInfo(
            '''Updated inventory item ${existing.id} (${widget.product.barcode}) — qty: ${result.quantity} ${result.unit}, loc: ${result.location}''',
          );
          await repo.updateInventoryItem(result);
          if (existing.id != null) {
            await notificationService.cancelReminders(existing.id!);
          }
          await notificationService.scheduleExpiryReminders(
            result,
            productName: widget.product.name,
            expiringSoonTitle: l10n.expiringSoon,
            buildExpiringSoonBody: l10n.expiresTomorrow,
            expiringTodayTitle: l10n.expiringToday,
            buildExpiringTodayBody: l10n.expiresToday,
            channelName: l10n.expiryChannelName,
            channelDescription: l10n.expiryChannelDescription,
          );
          if (mounted) {
            SnackbarHelper.showInfo(context, l10n.itemUpdated);
          }
        } else {
          logInfo(
            '''Added inventory item (${widget.product.barcode}) — qty: ${result.quantity} ${result.unit}, loc: ${result.location}''',
          );
          await repo.cacheProduct(widget.product);
          final newId = await repo.addInventoryItem(result);
          final savedItem = result.copyWith(id: newId);
          await _rescheduleInactivityReminder();
          await notificationService.scheduleExpiryReminders(
            savedItem,
            productName: widget.product.name,
            expiringSoonTitle: l10n.expiringSoon,
            buildExpiringSoonBody: l10n.expiresTomorrow,
            expiringTodayTitle: l10n.expiringToday,
            buildExpiringTodayBody: l10n.expiresToday,
            channelName: l10n.expiryChannelName,
            channelDescription: l10n.expiryChannelDescription,
          );
          if (mounted) {
            SnackbarHelper.showInfo(context, l10n.itemAdded);
          }
        }
        setState(() => _inventoryVersion++);
      } on Exception catch (e) {
        logError('Inventory operation failed: $e');
        if (mounted) {
          SnackbarHelper.showError(context, l10n.saveFailed);
        }
      }
    }
  }

  /// Updates the quantity of [item] to [newQuantity], stores it, and
  /// re-schedules expiry reminders.
  Future<void> _updateQuantity(
    InventoryItem item,
    double newQuantity,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(productRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);
    final updated = item.copyWith(quantity: newQuantity);
    try {
      await repo.updateInventoryItem(updated);
      await notificationService.scheduleExpiryReminders(
        updated,
        productName: widget.product.name,
        expiringSoonTitle: l10n.expiringSoon,
        buildExpiringSoonBody: l10n.expiresTomorrow,
        expiringTodayTitle: l10n.expiringToday,
        buildExpiringTodayBody: l10n.expiresToday,
        channelName: l10n.expiryChannelName,
        channelDescription: l10n.expiryChannelDescription,
      );
      logInfo('Quantity updated: ${item.barcode} — $newQuantity');
      setState(() => _inventoryVersion++);
    } on Exception catch (e) {
      logError('Failed to update quantity: $e');
      if (mounted) {
        SnackbarHelper.showError(context, l10n.saveFailed);
      }
    }
  }

  /// Asks for confirmation and then deletes the given inventory [item].
  Future<void> _deleteItem(InventoryItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteItemTitle),
        content: Text(l10n.deleteItemContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final repo = ref.read(productRepositoryProvider);
      final notificationService = ref.read(notificationServiceProvider);
      try {
        if (item.id != null) {
          await repo.deleteInventoryItem(item.id!);
          await notificationService.cancelReminders(item.id!);
        }
        logInfo(
          'Deleted inventory item ${item.id} (${widget.product.barcode})',
        );
        if (mounted) {
          SnackbarHelper.showUndo(context, l10n.itemRemoved, () async {
            try {
              final restoredId = await repo.addInventoryItem(item);
              logInfo('Undo delete: restored item $restoredId');
              final restoredItem = item.copyWith(id: restoredId);
              await notificationService.scheduleExpiryReminders(
                restoredItem,
                productName: widget.product.name,
                expiringSoonTitle: l10n.expiringSoon,
                buildExpiringSoonBody: l10n.expiresTomorrow,
                expiringTodayTitle: l10n.expiringToday,
                buildExpiringTodayBody: l10n.expiresToday,
                channelName: l10n.expiryChannelName,
                channelDescription: l10n.expiryChannelDescription,
              );
              if (mounted) {
                SnackbarHelper.showInfo(context, l10n.itemRestored);
                setState(() => _inventoryVersion++);
              }
            } on Exception catch (e) {
              logError('Failed to undo delete: $e');
            }
          });
        }
        setState(() => _inventoryVersion++);
      } on Exception catch (e) {
        logError('Failed to delete item: $e');
        if (mounted) {
          SnackbarHelper.showError(context, l10n.deleteFailed);
        }
      }
    }
  }
}

/// A single row in the inventory list.
///
/// Displays an icon that varies by storage location (coloured red if expired,
/// orange otherwise), the quantity/unit/location, the expiry date, and edit /
/// delete buttons.
class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.item,
    required this.settings,
    required this.onEdit,
    required this.onDelete,
    required this.onQuantityChanged,
  });

  /// The inventory item to display.
  final InventoryItem item;

  /// Current settings for unit conversion.
  final Settings settings;

  /// Called when the user taps the edit button.
  final VoidCallback onEdit;

  /// Called when the user taps the delete button.
  final VoidCallback onDelete;

  /// Called when the user adjusts the quantity.
  final ValueChanged<double> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemIsExpired = isExpired(item.expiryDate);
    final inventorySystem = UnitResolver.systemFor(
      settings: settings,
      context: UnitContext.inventory,
    );
    final display = UnitConverter.displayUnit(
      item.quantity,
      item.unit,
      inventorySystem,
      weightPref: settings.preferredWeightUnit,
      volumePref: settings.preferredVolumeUnit,
    );
    return ListTile(
      leading: Icon(
        _iconForLocation(item.location),
        color: itemIsExpired ? Colors.red : Colors.orange,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: () {
              final newQty = item.quantity - 1;
              if (newQty <= 0) {
                onDelete();
              } else {
                onQuantityChanged(newQty);
              }
            },
          ),
          GestureDetector(
            onTap: () => _showQuantityDialog(context),
            child: Text(
              l10n.formatQuantityUnit(
                display.quantity,
                l10n.localizeUnit(display.unit),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: () => onQuantityChanged(item.quantity + 1),
          ),
        ],
      ),
      subtitle: (() {
        final expirySuffix = item.expiryDate != null
            ? '  ·  ${l10n.expiryPrefix}: ${item.expiryDate}'
            : '';
        return Text('${l10n.localizeLocation(item.location)}$expirySuffix');
      })(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
    );
  }

  void _showQuantityDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: item.quantity.toString(),
    );
    final future = showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.quantityLabel),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value != null) {
                Navigator.pop(ctx, value);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    unawaited(
      future.then((value) {
        if (value != null) {
          if (value <= 0) {
            onDelete();
          } else {
            onQuantityChanged(value);
          }
        }
      }),
    );
  }

  /// Returns an appropriate icon for the given storage [location].
  IconData _iconForLocation(String location) {
    switch (location.toLowerCase()) {
      case 'pantry':
        return Icons.kitchen;
      case 'fridge':
        return Icons.local_drink;
      case 'freezer':
        return Icons.ac_unit;
      default:
        return Icons.help_outline;
    }
  }
}
