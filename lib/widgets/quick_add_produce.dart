import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pantry_app/models/produce_quick_add_item.dart';

/// A horizontal scrollable list of produce item chips for quick adding.
///
/// Displays a section header with an optional info tooltip, followed by
/// a horizontally scrollable carousel of produce chips. Each chip shows
/// a Material icon, the produce display name, and an optional weight hint.
///
/// When [items] is empty, the [emptyMessage] is displayed instead.
class QuickAddProduce extends StatelessWidget {
  /// Creates a [QuickAddProduce] carousel.
  const QuickAddProduce({
    required this.items,
    required this.onProduceSelected,
    required this.sectionTitle,
    required this.infoTooltip,
    required this.emptyMessage,
    super.key,
  });

  /// The produce items to display in the carousel.
  final List<ProduceQuickAddItem> items;

  /// Called when the user taps a produce chip.
  final void Function(ProduceQuickAddItem item) onProduceSelected;

  /// Label shown above the carousel.
  final String sectionTitle;

  /// Tooltip text for the info icon next to the section title.
  final String infoTooltip;

  /// Message shown when [items] is empty.
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          if (items.isEmpty) _buildEmptyState() else _buildCarousel(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            sectionTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: infoTooltip,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        emptyMessage,
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return ActionChip(
            avatar: Icon(item.icon, size: 18),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    item.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.weightHintG != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    '~${item.weightHintG!.toInt()}g',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              onProduceSelected(item);
            },
          );
        },
      ),
    );
  }
}
