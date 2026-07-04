import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/inventory_with_product.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/providers/active_inventory_provider.dart';
import 'package:pantry_app/providers/inventory_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/screens/add_product_screen.dart';
import 'package:pantry_app/screens/manage_inventories_screen.dart';
import 'package:pantry_app/screens/product_detail_screen.dart';
import 'package:pantry_app/screens/scanner_screen.dart';
import 'package:pantry_app/screens/settings_screen.dart';
import 'package:pantry_app/screens/stats_screen.dart';
import 'package:pantry_app/services/exceptions.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';
import 'package:pantry_app/widgets/empty_pantry.dart';
import 'package:pantry_app/widgets/error_view.dart';
import 'package:pantry_app/widgets/inventory_card.dart';
import 'package:pantry_app/widgets/nutriscore_badge.dart';
import 'package:url_launcher/url_launcher.dart';

/// The main dashboard of the app.
///
/// Shows inventory grouped by expiry status and provides barcode scanning.
class HomeScreen extends ConsumerWidget {
  /// Creates a [HomeScreen] widget.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final inventoryAsync = ref.watch(inventoryWithProductProvider);
    final inventoriesAsync = ref.watch(inventoryListProvider);
    final activeId = ref.watch<int>(activeInventoryProvider);
    final settings = ref.watch(settingsProvider);
    final averageNutriscore = ref.watch(averageNutriscoreProvider);

    var appBarTitle = l10n.myPantry;
    inventoriesAsync.whenData((list) {
      for (final inv in list) {
        if (inv['id'] == activeId) {
          appBarTitle = inv['name'] as String;
          break;
        }
      }
    });

    // Always show the inventory switcher with "Create" at the bottom.
    final switcher = inventoriesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (list) => PopupMenuButton<String>(
        icon: const Icon(Icons.swap_horiz),
        tooltip: l10n.switchPantry,
        onSelected: (value) {
          if (value == '__manage__') {
            unawaited(
              Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => const ManageInventoriesScreen(),
                ),
              ),
            );
          } else if (value == '__create__') {
            unawaited(_showCreatePantryDialog(context, ref));
          } else {
            final id = int.tryParse(value);
            if (id != null) {
              logInfo('Switched to inventory $id');
              ref.read(activeInventoryProvider.notifier).value = id;
            }
          }
        },
        itemBuilder: (_) => [
          for (final inv in list)
            PopupMenuItem<String>(
              value: '${inv['id']}',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inv['name'] as String,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if ((inv['id'] as int) == activeId)
                    const Icon(Icons.check, size: 18, color: Colors.teal),
                ],
              ),
            ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: '__create__',
            child: Row(
              children: [
                const Icon(Icons.add, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.createNewPantry)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: '__manage__',
            child: Row(
              children: [
                const Icon(Icons.folder, size: 18),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.manageInventories)),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(appBarTitle, overflow: TextOverflow.ellipsis)),
            if (averageNutriscore.value != null) ...[
              const SizedBox(width: 8),
              NutriScoreBadge(
                grade: averageNutriscore.value,
                size: 24,
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          switcher,
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: l10n.pantryStats,
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () async {
              logInfo('Settings button pressed');
              await Navigator.of(context).push<void>(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              ref.invalidate(inventoryWithProductProvider);
            },
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          logError('Failed to load inventory: $err');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              SnackbarHelper.showError(context, l10n.inventoryLoadFailed);
            }
          });
          return ErrorView(
            message: l10n.inventoryLoadFailed,
            onRetry: () => ref.invalidate(inventoryWithProductProvider),
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return EmptyPantry(onScan: () => _scanBarcode(context, ref));
          }
          return _InventoryList(
            items: items,
            onScan: () => _scanBarcode(context, ref),
            expiringSoonDays: settings.expiringSoonDays,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _scanBarcode(context, ref),
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Future<void> _showCreatePantryDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newPantry),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.nameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      final repo = ref.read(productRepositoryProvider);
      try {
        await repo.createInventory(name);
        logInfo('Created inventory "$name"');
        ref.invalidate(inventoryListProvider);
        if (context.mounted) {
          SnackbarHelper.showInfo(context, l10n.inventoryCreated(name));
        }
      } on Exception catch (e) {
        logError('Failed to create inventory: $e');
        if (context.mounted) {
          SnackbarHelper.showError(context, l10n.couldNotCreateInventory);
        }
      }
    }
  }

  Future<void> _scanBarcode(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    logInfo('Barcode scanned: $barcode');
    if (barcode == null || !context.mounted) return;

    final repo = ref.read(productRepositoryProvider);

    try {
      final product = await repo.getProduct(barcode);
      logInfo('Product found: ${product.name}');
      if (context.mounted) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
        ref.invalidate(inventoryWithProductProvider);
      }
    } on ProductNotFoundException {
      logWarning('Product not found for $barcode');
      if (context.mounted) {
        _showProductNotFoundSheet(context, ref, barcode);
      }
    } on FetchFailedException {
      logWarning('Network error fetching $barcode');
      if (context.mounted) {
        SnackbarHelper.showError(context, l10n.networkError);
      }
    }
  }

  void _showProductNotFoundSheet(
    BuildContext context,
    WidgetRef ref,
    String barcode,
  ) {
    final l10n = AppLocalizations.of(context)!;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.productNotFound,
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(l10n.productNotFoundHint, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                if (context.mounted) {
                  final result = await Navigator.of(context).push<Product>(
                    MaterialPageRoute(
                      builder: (_) => AddProductScreen(barcode: barcode),
                    ),
                  );
                  if (result != null && context.mounted) {
                    final repo = ref.read(productRepositoryProvider);
                    await repo.cacheProduct(result);
                    if (context.mounted) {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductDetailScreen(product: result),
                        ),
                      );
                      ref.invalidate(inventoryWithProductProvider);
                    }
                  }
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addManually),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (context.mounted) {
                  const storeUrl =
                      'https://play.google.com/store/apps/details?id=org.openfoodfacts.scanner&hl=en&pli=1';
                  final uri = Uri.parse(storeUrl);
                  final canLaunch = await canLaunchUrl(uri);
                  if (canLaunch && context.mounted) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else if (context.mounted) {
                    SnackbarHelper.showError(
                      context,
                      l10n.couldNotOpenPlayStore,
                    );
                  }
                }
              },
              child: Text(l10n.contributeToOpenFoodFacts),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _InventoryList extends ConsumerStatefulWidget {
  const _InventoryList({
    required this.items,
    required this.onScan,
    required this.expiringSoonDays,
  });

  final List<InventoryWithProduct> items;
  final VoidCallback onScan;
  final int expiringSoonDays;

  @override
  ConsumerState<_InventoryList> createState() => _InventoryListState();
}

class _InventoryListState extends ConsumerState<_InventoryList> {
  String _searchQuery = '';
  List<InventoryWithProduct>? _cachedFiltered;
  List<InventoryWithProduct>? _cachedExpired;
  List<InventoryWithProduct>? _cachedExpiringSoon;
  List<InventoryWithProduct>? _cachedGood;
  int? _cachedItemHash;
  String? _cachedSearchQuery;
  int? _cachedThreshold;

  void _invalidateCache() {
    _cachedFiltered = null;
    _cachedExpired = null;
    _cachedExpiringSoon = null;
    _cachedGood = null;
    _cachedItemHash = null;
    _cachedSearchQuery = null;
    _cachedThreshold = null;
  }

  bool get _cacheValid =>
      _cachedItemHash != null &&
      _cachedItemHash == widget.items.hashCode &&
      _cachedSearchQuery == _searchQuery &&
      _cachedThreshold == widget.expiringSoonDays;

  List<InventoryWithProduct> get _filtered {
    if (_cacheValid && _cachedFiltered != null) return _cachedFiltered!;
    if (_searchQuery.isEmpty) {
      _cachedFiltered = widget.items;
    } else {
      final q = _searchQuery.toLowerCase();
      _cachedFiltered = widget.items.where((item) {
        return (item.productName?.toLowerCase().contains(q) ?? false) ||
            item.barcode.toLowerCase().contains(q);
      }).toList();
    }
    _cachedItemHash = widget.items.hashCode;
    _cachedSearchQuery = _searchQuery;
    _cachedThreshold = widget.expiringSoonDays;
    _cachedExpired = null;
    _cachedExpiringSoon = null;
    _cachedGood = null;
    return _cachedFiltered!;
  }

  List<InventoryWithProduct> get _expired {
    if (_cacheValid && _cachedExpired != null) return _cachedExpired!;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    _cachedExpired = _filtered.where((i) {
      if (i.expiryDate == null) return false;
      final date = DateTime.tryParse(i.expiryDate!);
      if (date == null) return false;
      return date.isBefore(todayStart);
    }).toList();
    return _cachedExpired!;
  }

  List<InventoryWithProduct> get _expiringSoon {
    if (_cacheValid && _cachedExpiringSoon != null) {
      return _cachedExpiringSoon!;
    }
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final threshold = todayStart.add(Duration(days: widget.expiringSoonDays));
    _cachedExpiringSoon = _filtered.where((i) {
      if (i.expiryDate == null) return false;
      final date = DateTime.tryParse(i.expiryDate!);
      if (date == null) return false;
      return !date.isBefore(todayStart) && date.isBefore(threshold);
    }).toList();
    return _cachedExpiringSoon!;
  }

  List<InventoryWithProduct> get _good {
    if (_cacheValid && _cachedGood != null) return _cachedGood!;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final threshold = todayStart.add(Duration(days: widget.expiringSoonDays));
    _cachedGood = _filtered.where((i) {
      if (i.expiryDate == null) return true;
      final date = DateTime.tryParse(i.expiryDate!);
      if (date == null) return true;
      return !date.isBefore(threshold);
    }).toList();
    return _cachedGood!;
  }

  @override
  void didUpdateWidget(covariant _InventoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.expiringSoonDays != widget.expiringSoonDays) {
      _invalidateCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(inventoryWithProductProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (_expired.isNotEmpty) ...[
                  _sectionHeader(
                    l10n.expired,
                    Colors.red,
                    Icons.error_outline,
                  ),
                  ..._expired.map((item) => InventoryCard(item: item)),
                ],
                if (_expiringSoon.isNotEmpty) ...[
                  _sectionHeader(
                    l10n.expiringSoon,
                    Colors.orange,
                    Icons.warning_amber,
                  ),
                  ..._expiringSoon.map((item) => InventoryCard(item: item)),
                ],
                if (_good.isNotEmpty) ...[
                  _sectionHeader(
                    l10n.good,
                    Colors.green,
                    Icons.check_circle_outline,
                  ),
                  ..._good.map((item) => InventoryCard(item: item)),
                ],
                if (_filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.noItemsMatch)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
