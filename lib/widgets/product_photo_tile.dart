import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';

/// A tile for a product photo slot in the add-product form.
///
/// Shows an empty "Add photo" affordance when [image] is null, or the
/// photo thumbnail plus a delete button when an [image] is attached.
/// Tapping the tile (when filled) invokes [onTap] to open the preview.
class ProductPhotoTile extends StatelessWidget {
  /// Creates a [ProductPhotoTile] for the given [label] and [image].
  const ProductPhotoTile({
    required this.label,
    required this.onAdd,
    required this.onTap,
    required this.onDelete,
    this.image,
    super.key,
  });

  /// A human-readable name for the photo slot, e.g. "Nutrition table".
  final String label;

  /// The attached photo, or null for an empty slot.
  final File? image;

  /// Called when the user chooses to add a photo to an empty slot.
  final VoidCallback onAdd;

  /// Called when the user taps a filled tile to open the preview.
  final VoidCallback onTap;

  /// Called when the user removes the attached photo.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (image == null) {
      return _buildEmpty(context, l10n);
    }
    return _buildFilled(context, l10n);
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations l10n) {
    final actionLabel = l10n.photoSlotAction(l10n.addPhotoSlot, label);
    return ListTile(
      leading: const Icon(Icons.camera_alt),
      title: Text(label),
      trailing: Semantics(
        button: true,
        label: actionLabel,
        excludeSemantics: true,
        child: IconButton(
          icon: const Icon(Icons.add_a_photo),
          tooltip: actionLabel,
          onPressed: onAdd,
        ),
      ),
    );
  }

  Widget _buildFilled(BuildContext context, AppLocalizations l10n) {
    final previewLabel = l10n.photoSlotAction(l10n.previewPhoto, label);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: previewLabel,
            excludeSemantics: true,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.file(
                          image!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(label)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.deletePhoto,
            onPressed: onDelete,
          ),
        ),
      ],
    );
  }
}
