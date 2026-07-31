import 'package:flutter/material.dart';
import 'package:pantry_app/models/search_filter.dart';

/// A labeled dropdown that lets the user pick the active [SearchSource].
///
/// The three sources (Open Food Facts, USDA, and the user's pantry) are
/// rendered from the [offLabel], [usdaLabel], and [inventoryLabel] strings so
/// the caller controls localization. Selection changes are forwarded through
/// [onChanged]; deduplication (no-op when re-selecting the current source)
/// is left to the caller.
class SearchSourceSelector extends StatelessWidget {
  /// Creates a [SearchSourceSelector].
  ///
  /// [label] is shown before the dropdown. [value] is the currently selected
  /// [SearchSource]. [onChanged] receives the newly selected source.
  const SearchSourceSelector({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.offLabel,
    required this.usdaLabel,
    required this.inventoryLabel,
    super.key,
  });

  /// The text shown before the dropdown, typically the source label.
  final String label;

  /// The currently selected [SearchSource].
  final SearchSource value;

  /// Called with the newly selected [SearchSource].
  final ValueChanged<SearchSource> onChanged;

  /// The display name of the Open Food Facts source.
  final String offLabel;

  /// The display name of the USDA source.
  final String usdaLabel;

  /// The display name of the inventory source.
  final String inventoryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        DropdownButton<SearchSource>(
          value: value,
          underline: const SizedBox(),
          isDense: true,
          items: [
            DropdownMenuItem(
              value: SearchSource.off,
              child: Text(offLabel),
            ),
            DropdownMenuItem(
              value: SearchSource.usda,
              child: Text(usdaLabel),
            ),
            DropdownMenuItem(
              value: SearchSource.inventory,
              child: Text(inventoryLabel),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
        ),
      ],
    );
  }
}
