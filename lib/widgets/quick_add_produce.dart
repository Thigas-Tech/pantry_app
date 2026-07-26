import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pantry_app/utils/progress_indicator_helper.dart';

/// A horizontal scrollable list of produce item chips for quick adding.
///
/// Each chip shows a produce name. Tapping a chip invokes
/// [onProduceSelected] with the produce name, and triggers haptic feedback.
/// Chips whose name is present in [loadingItems] display a small inline
/// spinner alongside the produce name and are disabled to prevent
/// duplicate taps while the product is being resolved.
class QuickAddProduce extends StatelessWidget {
  /// Creates a [QuickAddProduce] carousel.
  const QuickAddProduce({
    required this.items,
    required this.onProduceSelected,
    this.loadingItems = const {},
    super.key,
  });

  /// The list of produce names to display.
  final List<String> items;

  /// Called when the user taps a produce chip.
  final void Function(String name) onProduceSelected;

  /// The set of produce names currently being resolved.
  ///
  /// Chips with names in this set show a small inline spinner and are
  /// disabled to prevent duplicate taps.
  final Set<String> loadingItems;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final name = items[index];
          final isLoading = loadingItems.contains(name);
          return ActionChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading) ...[
                  ProgressIndicatorHelper.build(
                    size: 14,
                    strokeWidth: 2,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            onPressed: isLoading
                ? null
                : () {
                    unawaited(HapticFeedback.lightImpact());
                    onProduceSelected(name);
                  },
          );
        },
      ),
    );
  }
}
