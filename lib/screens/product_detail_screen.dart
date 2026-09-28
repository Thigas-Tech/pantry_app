import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/l10n/l10n_extensions.dart';
import 'package:pantry_app/models/inventory_item.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/shopping_item.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/connectivity_provider.dart';
import 'package:pantry_app/providers/image_cache_provider.dart';
import 'package:pantry_app/providers/inventory_for_barcode_provider.dart';
import 'package:pantry_app/providers/notification_coordinator_provider.dart';
import 'package:pantry_app/providers/notification_service_provider.dart';
import 'package:pantry_app/providers/product_image_service_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/product_submission_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/providers/shopping_list_service_provider.dart';
import 'package:pantry_app/screens/add_to_inventory_screen.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/services/product_image_service.dart';
import 'package:pantry_app/utils/date_helpers.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';
import 'package:pantry_app/utils/quantity_parser.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/utils/unit_conversion.dart';
import 'package:pantry_app/utils/unit_resolver.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';
import 'package:pantry_app/widgets/nutrition_table.dart';
import 'package:pantry_app/widgets/product_photo_management.dart';
import 'package:pantry_app/widgets/product_submission_status.dart';
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
/// The screen is a [ConsumerStatefulWidget] because it manages inventory
/// operations and the image service lifecycle. The inventory list is
/// provided by [inventoryForBarcodeProvider]; after adding, editing, or
/// deleting an item the provider family is invalidated so the list
/// refreshes.
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
  /// The latest product snapshot. Starts from [ProductDetailScreen.product]
  /// and is refreshed from the local cache after a submission retry or when
  /// the submission notifier reports a terminal state for this barcode.
  late Product _product;

  /// The photo persistence service, captured in [initState] so it is safe to
  /// use from [dispose] (where [ref] is unavailable).
  late final ProductImageService _imageService;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _imageService = ref.read(productImageServiceProvider);
  }

  @override
  void dispose() {
    // Remove product photo files that were deleted while the screen was open
    // but whose physical file was kept so the user could undo.
    unawaited(
      _imageService.deleteOrphanedFiles(
        barcode: _product.barcode,
        referencedPaths: {
          if (_product.nutritionImagePath != null) _product.nutritionImagePath!,
          if (_product.ingredientsImagePath != null)
            _product.ingredientsImagePath!,
          if (_product.productImagePath != null) _product.productImagePath!,
        },
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).value ?? const Settings();
    final activeId = ref.watch(activeInventoryProvider).value ?? 1;
    final inventoryFuture = ref.watch(
      inventoryForBarcodeProvider((_product.barcode, activeId)).future,
    );

    // When a submission for this product reaches a terminal state (e.g. one
    // started from the add-product screen), refresh the displayed product so
    // the status chip updates without an app restart.
    ref.listen(productSubmissionProvider, (previous, next) {
      if (next != null && next.barcode == _product.barcode && next.isTerminal) {
        unawaited(_refreshProductFromDb());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: l10n.viewOnOpenFoodFacts,
            onPressed: () async {
              final url = Uri.parse(
                'https://world.openfoodfacts.org/product/${_product.barcode}',
              );
              logInfo('Opening OFF page for ${_product.barcode}');
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
            if (_product.imageUrl != null)
              Hero(
                tag: 'detail_${_product.barcode}',
                child: Consumer(
                  builder: (context, ref, _) {
                    final imagePath = ref.watch(
                      cachedImageProvider(
                        (_product.imageUrl!, _product.barcode),
                      ),
                    );
                    return imagePath.when(
                      data: (path) => path != null
                          ? _buildCachedProductImage(context, path)
                          : _buildNetworkProductImage(context),
                      loading: () => _buildNetworkProductImage(context),
                      error: (_, _) => _buildNetworkProductImage(context),
                    );
                  },
                ),
              ),
            _infoRow(l10n.barcodeLabel, _product.barcode),
            if (_product.languageCode !=
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
                    final repo = ref.read(productRepositoryProvider);
                    final isOnline = await ref.read(
                      hasConnectionProvider.future,
                    );
                    if (!isOnline) {
                      if (context.mounted) {
                        SnackbarHelper.showInfo(
                          context,
                          l10n.showInLanguageOffline(
                            currentLocale.toUpperCase(),
                          ),
                        );
                      }
                      return;
                    }
                    try {
                      final product = await repo.refreshProductLanguage(
                        _product.barcode,
                        languageCode: currentLocale,
                      );
                      if (context.mounted) {
                        setState(() => _product = product);
                        SnackbarHelper.showInfo(context, l10n.productUpdated);
                      }
                    } on FetchFailedException catch (e) {
                      logError(
                        'Failed to re-fetch product in $currentLocale: $e',
                      );
                      if (context.mounted) {
                        SnackbarHelper.showError(
                          context,
                          l10n.fetchProductFailed,
                        );
                      }
                    } on Exception catch (e) {
                      logError('Failed to switch product language: $e');
                      if (context.mounted) {
                        SnackbarHelper.showError(context, l10n.errorGeneric);
                      }
                    }
                  },
                ),
              ),
            if (_product.nutriscoreGrade != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 100),
                    NutriScoreBadge(
                      grade: _product.nutriscoreGrade,
                      size: 32,
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          NutriScoreBadge.isNotApplicable(
                            _product.nutriscoreGrade,
                          )
                          ? () {
                              final category = _formatCategory(
                                _product.nutriscoreNotApplicableCategory,
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
            if (_product.brand != null)
              _infoRow(l10n.brandLabel, _product.brand!),
            if (_product.category != null)
              _infoRow(l10n.categoryLabel, _product.category!),
            if (_product.source == 'manual') ...[
              ProductSubmissionStatus(
                product: _product,
                onRetry: _retrySubmission,
              ),
              const SizedBox(height: 8),
              ProductPhotoManagement(
                product: _product,
                onChanged: (updated) => setState(() => _product = updated),
              ),
              const SizedBox(height: 8),
            ],
            const Divider(),
            _infoRow(l10n.servingSize, _displayServingSize(l10n, settings)),

            // Nutrition table
            NutritionTable(product: _product),

            const Divider(),
            if (_product.ingredients != null)
              ExpansionTile(
                title: Text(l10n.ingredients),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(_product.ingredients!),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            const SizedBox(height: 16),

            // Inventory section header
            Text(
              l10n.yourInventory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // Inventory list (refreshed by invalidating
            // inventoryForBarcodeProvider after mutations)
            FutureBuilder<List<InventoryItem>>(
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
                  name: _product.name,
                  barcode: _product.barcode,
                );
                unawaited(
                  () async {
                    final activeId = await ref.read(
                      activeInventoryProvider.future,
                    );
                    await ref
                        .read(shoppingListServiceProvider)
                        .addShoppingItem(
                          item,
                          activeInventoryId: activeId,
                        );
                    invalidateShoppingList(ref);
                  }(),
                );
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

  /// Invalidates the cached inventory list for this product so the next
  /// build refetches it after a mutation.
  void _invalidateInventory() {
    final activeId = ref.read(activeInventoryProvider).value ?? 1;
    ref.invalidate(inventoryForBarcodeProvider((_product.barcode, activeId)));
  }

  /// Builds the product image from a locally cached WebP file at [path].
  Widget _buildCachedProductImage(BuildContext context, String path) {
    return ClipRect(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3,
        child: Image.file(
          File(path),
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 48),
        ),
      ),
    );
  }

  /// Builds the product image streamed from [Product.imageUrl] with a
  /// resolution-aware decode size.
  Widget _buildNetworkProductImage(BuildContext context) {
    return ClipRect(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 3,
        child: Image.network(
          _product.imageUrl!,
          height: 200,
          cacheWidth:
              (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
          cacheHeight: (200 * MediaQuery.devicePixelRatioOf(context)).round(),
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: ProgressIndicatorHelper.build(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 48),
        ),
      ),
    );
  }

  /// Formats the purchase date as dd/mm/yyyy.

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
        settings: ref.read(settingsProvider).value ?? const Settings(),
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

  /// Retries the Open Food Facts submission through
  /// [ProductSubmissionNotifier], then refreshes the displayed product from
  /// the local cache so the status updates without an app restart.
  Future<void> _retrySubmission() async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(productSubmissionProvider.notifier);
    final repo = ref.read(productRepositoryProvider);
    final fresh = await repo.getProductFromCache(_product.barcode) ?? _product;
    await notifier.submit(fresh);
    final refreshed = await repo.getProductFromCache(_product.barcode);
    if (!mounted) return;
    notifier.clear();
    setState(() {
      if (refreshed != null) _product = refreshed;
    });
    if ((refreshed ?? _product).submissionStatus ==
        productSubmissionSubmitted) {
      SnackbarHelper.showInfo(context, l10n.submissionSuccess);
    } else {
      SnackbarHelper.showError(context, l10n.submissionError);
    }
  }

  /// Re-reads the product for this screen's barcode from the local cache and
  /// updates the displayed snapshot.
  Future<void> _refreshProductFromDb() async {
    final repo = ref.read(productRepositoryProvider);
    final refreshed = await repo.getProductFromCache(_product.barcode);
    if (!mounted || refreshed == null) return;
    setState(() => _product = refreshed);
  }

  /// Returns the serving size to display, converting to the user's
  /// preferred unit system. Falls back to the localized not-available
  /// label when the product has no serving data.
  String _displayServingSize(AppLocalizations l10n, Settings settings) {
    // Try structured serving data first
    if (_product.servingQuantity != null &&
        _product.servingQuantity! > 0 &&
        _product.servingSize != null &&
        _product.servingSize!.isNotEmpty) {
      final parsed = parseServingQuantity(
        servingQuantity: _product.servingQuantity,
        servingSize: _product.servingSize,
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
    if (_product.servingSize != null) return _product.servingSize!;

    return l10n.notAvailable;
  }

  /// Builds a simple label-value row used for non-nutrition product information
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
  /// latest product-add date.
  Future<void> _rescheduleInactivityReminder() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      final settings = await ref.read(settingsProvider.future);
      await ref
          .read(notificationCoordinatorProvider)
          .rescheduleInactivityReminder(l10n: l10n, settings: settings);
    } on Exception catch (e) {
      logError('Failed to reschedule inactivity reminder: $e');
    }
  }

  /// Opens the [AddToInventoryScreen] for creating or editing an item.
  Future<void> _openAddEditScreen({InventoryItem? existing}) async {
    final activeId = await ref.read(activeInventoryProvider.future);
    if (!mounted) return;

    // Suggest an expiry date based on the product category.
    String? suggested;
    if (existing == null && _product.category != null) {
      final cat = _product.category!.toLowerCase();
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
          barcode: _product.barcode,
          existingItem: existing,
          suggestedExpiry: suggested,
          inventoryId: activeId,
          product: _product,
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
            '''Updated inventory item ${existing.id} (${_product.barcode}) — qty: ${result.quantity} ${result.unit}, loc: ${result.location}''',
          );
          await repo.updateInventoryItem(result);
          if (existing.id != null) {
            await notificationService.cancelReminders(existing.id!);
          }
          await notificationService.scheduleExpiryReminders(
            result,
            productName: _product.name,
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
            '''Added inventory item (${_product.barcode}) — qty: ${result.quantity} ${result.unit}, loc: ${result.location}''',
          );
          await repo.cacheProduct(_product);
          final newId = await repo.addOrMergeInventoryItem(result);
          final savedItem = result.copyWith(id: newId);
          await _rescheduleInactivityReminder();
          await notificationService.scheduleExpiryReminders(
            savedItem,
            productName: _product.name,
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
        _invalidateInventory();
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
        productName: _product.name,
        expiringSoonTitle: l10n.expiringSoon,
        buildExpiringSoonBody: l10n.expiresTomorrow,
        expiringTodayTitle: l10n.expiringToday,
        buildExpiringTodayBody: l10n.expiresToday,
        channelName: l10n.expiryChannelName,
        channelDescription: l10n.expiryChannelDescription,
      );
      logInfo('Quantity updated: ${item.barcode} — $newQuantity');
      _invalidateInventory();
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
          'Deleted inventory item ${item.id} (${_product.barcode})',
        );
        if (mounted) {
          SnackbarHelper.showUndo(context, l10n.itemRemoved, () async {
            try {
              final restoredId = await repo.addInventoryItem(item);
              logInfo('Undo delete: restored item $restoredId');
              final restoredItem = item.copyWith(id: restoredId);
              await notificationService.scheduleExpiryReminders(
                restoredItem,
                productName: _product.name,
                expiringSoonTitle: l10n.expiringSoon,
                buildExpiringSoonBody: l10n.expiresTomorrow,
                expiringTodayTitle: l10n.expiringToday,
                buildExpiringTodayBody: l10n.expiresToday,
                channelName: l10n.expiryChannelName,
                channelDescription: l10n.expiryChannelDescription,
              );
              if (mounted) {
                SnackbarHelper.showInfo(context, l10n.itemRestored);
                _invalidateInventory();
              }
            } on Exception catch (e) {
              logError('Failed to undo delete: $e');
            }
          });
        }
        _invalidateInventory();
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
