import 'package:flutter/material.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/utils/bottom_sheet_helper.dart';

/// The source of a product photo.
enum PhotoSource {
  /// Take a new photo with the camera.
  camera,

  /// Choose an existing photo from the gallery.
  gallery,
}

/// Shows a bottom sheet asking where the product photo should come from.
///
/// Returns [PhotoSource.camera], [PhotoSource.gallery], or null when the
/// user cancels.
Future<PhotoSource?> showPhotoSourceChooser(BuildContext context) {
  return BottomSheetHelper.show<PhotoSource>(
    context: context,
    builder: (ctx) => const _PhotoSourceChooser(),
  );
}

class _PhotoSourceChooser extends StatelessWidget {
  const _PhotoSourceChooser();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.choosePhotoSourceTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.photoSourceCamera),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.photoSourceGallery),
              onTap: () => Navigator.of(context).pop(PhotoSource.gallery),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
