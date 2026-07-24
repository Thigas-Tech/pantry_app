import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/settings_provider.dart';
import 'package:pantry_app/services/currency_service.dart';

/// Displays the cooking history for a specific recipe.
///
/// Shows a chronological list of "made" events with date, cost at time,
/// and number of ingredients used.
class RecipeHistoryScreen extends ConsumerStatefulWidget {
  /// Creates a [RecipeHistoryScreen] for the given [recipeId] and [recipeName].
  const RecipeHistoryScreen({
    required this.recipeId,
    required this.recipeName,
    super.key,
  });

  /// The id of the recipe whose history to display.
  final int recipeId;

  /// The recipe name shown in the app bar title.
  final String recipeName;

  @override
  ConsumerState<RecipeHistoryScreen> createState() =>
      _RecipeHistoryScreenState();
}

class _RecipeHistoryScreenState extends ConsumerState<RecipeHistoryScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final entries = await db.getRecipeHistory(widget.recipeId);
    if (!mounted) return;
    setState(() {
      _entries = entries
          .map(
            (e) => <String, dynamic>{
              'id': e.id,
              'made_at': e.madeAt,
              'cost_at_time': e.costAtTime,
              'ingredient_snapshot': e.ingredientSnapshot,
            },
          )
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final symbol = currencySymbolFor(settings.baseCurrency);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.recipeName} - ${l10n.history}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? Center(child: Text(l10n.noHistory))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _entries.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final madeAt = DateTime.fromMillisecondsSinceEpoch(
                    entry['made_at'] as int,
                  );
                  final cost =
                      (entry['cost_at_time'] as num?)?.toDouble() ?? 0.0;
                  final snapshot =
                      entry['ingredient_snapshot'] as String? ?? '[]';
                  final dateStr =
                      '${madeAt.day}/${madeAt.month}/${madeAt.year}';

                  return ListTile(
                    title: Text(dateStr),
                    subtitle: Text(
                      '${l10n.recipeCost}: $symbol${cost.toStringAsFixed(2)}',
                    ),
                    trailing: Text(
                      '${snapshot.split(',').length}'
                      ' ${l10n.ingredients.toLowerCase()}',
                    ),
                  );
                },
              ),
            ),
    );
  }
}
