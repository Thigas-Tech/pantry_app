import 'package:flutter/material.dart';

import 'package:pantry_app/widgets/nutriscore_badge.dart';

/// A tappable card that displays the active pantry name, average Nutri-Score
/// badge, and a dropdown indicator icon.
///
/// Replaces the plain [PopupMenuButton] icon in the home screen AppBar.
/// On tap, the caller should open a selection sheet with the inventory list.
class InventorySwitcherCard extends StatelessWidget {
  /// Creates an [InventorySwitcherCard].
  const InventorySwitcherCard({
    required this.onTap,
    required this.name,
    required this.nutriscoreGrade,
    this.isLoading = false,
    super.key,
  });

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// The active pantry name, or null if no inventory exists.
  final String? name;

  /// The average Nutri-Score grade ('a'-'e'), or null if no products
  /// have Nutri-Score data.
  final String? nutriscoreGrade;

  /// When true, shows a placeholder border card without content while
  /// providers resolve.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return SizedBox(
        height: 36,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (name == null) {
      return _SwitcherContainer(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz, size: 18, color: theme.colorScheme.outline),
          ],
        ),
      );
    }

    return _SwitcherContainer(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              name!,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (nutriscoreGrade != null) ...[
            const SizedBox(width: 8),
            NutriScoreBadge(grade: nutriscoreGrade, size: 20),
          ],
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

class _SwitcherContainer extends StatelessWidget {
  const _SwitcherContainer({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }
}
