import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A horizontal scrollable list of produce item chips for quick adding.
///
/// Each chip shows a produce name. Tapping a chip invokes
/// [onProduceSelected] with the produce name, and triggers haptic feedback.
class QuickAddProduce extends StatelessWidget {
  /// Creates a [QuickAddProduce] carousel.
  const QuickAddProduce({
    required this.items,
    required this.onProduceSelected,
    super.key,
  });

  /// The list of produce names to display.
  final List<String> items;

  /// Called when the user taps a produce chip.
  final void Function(String name) onProduceSelected;

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
          return ActionChip(
            label: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              onProduceSelected(name);
            },
          );
        },
      ),
    );
  }
}
