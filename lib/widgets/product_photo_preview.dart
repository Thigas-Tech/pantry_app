import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';

/// The action a user chose in [ProductPhotoPreview].
enum PhotoPreviewAction {
  /// The user dismissed the preview without changing anything.
  close,

  /// The user wants to take a new photo with the camera.
  retake,

  /// The user wants to pick another photo from a source chooser.
  replace,

  /// The user wants to remove the photo.
  delete,
}

/// A full-screen preview of a product photo with retake, replace, and
/// delete actions.
///
/// Pops the route with a [PhotoPreviewAction] describing what the user
/// chose. Every action is available through visible buttons so no custom
/// gesture is required.
class ProductPhotoPreview extends StatelessWidget {
  /// Creates a [ProductPhotoPreview] for the given [image] and [label].
  const ProductPhotoPreview({
    required this.image,
    required this.label,
    super.key,
  });

  /// The photo to display.
  final File image;

  /// A human-readable name for the photo slot, e.g. "Nutrition table".
  final String label;

  void _pop(BuildContext context, PhotoPreviewAction action) {
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(label),
        leading: Semantics(
          button: true,
          label: l10n.close,
          excludeSemantics: true,
          child: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.close,
            onPressed: () => _pop(context, PhotoPreviewAction.close),
          ),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            image,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image,
              color: Colors.white70,
              size: 64,
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pop(context, PhotoPreviewAction.retake),
                  icon: const Icon(Icons.photo_camera),
                  label: Text(l10n.retakePhoto),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pop(context, PhotoPreviewAction.replace),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l10n.replacePhoto),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pop(context, PhotoPreviewAction.delete),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deletePhoto),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
