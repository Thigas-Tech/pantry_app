import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/models/scan_history_entry.dart';

/// A horizontal strip of the most recent successful scans.
///
/// Each entry shows the scanned product's image, its name, and a quick-add
/// button that adds the item directly to the active inventory. Tapping the
/// card body opens the product detail screen via [onTapEntry].
class RecentScansSection extends ConsumerWidget {
  /// Creates a [RecentScansSection].
  ///
  /// [entries] are shown newest first. [onQuickAdd] fires when the user taps
  /// a quick-add button, and [onTapEntry] when the user taps a card body.
  const RecentScansSection({
    required this.entries,
    required this.onQuickAdd,
    required this.onTapEntry,
    super.key,
  });

  /// The scan history entries to display, newest first.
  final List<ScanHistoryEntry> entries;

  /// Called when the user taps the quick-add button on an entry.
  final void Function(ScanHistoryEntry entry) onQuickAdd;

  /// Called when the user taps an entry's card body.
  final void Function(ScanHistoryEntry entry) onTapEntry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, l10n),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                _entryCard(context, l10n, entries[index]),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.recentScans,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(
    BuildContext context,
    AppLocalizations l10n,
    ScanHistoryEntry entry,
  ) {
    return SizedBox(
      width: 116,
      child: Card(
        elevation: 1,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTapEntry(entry),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _image(context, entry)),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: l10n.quickAdd,
                    onPressed: () => onQuickAdd(entry),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _image(BuildContext context, ScanHistoryEntry entry) {
    final url = entry.imageUrl;
    if (url == null) return _fallback();
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        cacheWidth: (56 * ratio).round(),
        cacheHeight: (56 * ratio).round(),
        fit: BoxFit.cover,
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _fallback();
        },
        errorBuilder: (_, _, _) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }
}
