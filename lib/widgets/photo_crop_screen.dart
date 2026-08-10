import 'dart:io';

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/l10n/app_localizations.dart';
import 'package:pantry_app/providers/product_photo_cropper_provider.dart';
import 'package:pantry_app/services/product_photo_cropper.dart';
import 'package:pantry_app/utils/snackbar_helper.dart';

/// Pushes [PhotoCropScreen] for [inputFile] and returns the cropped file.
///
/// Returns null when the user closes the screen without applying, in which
/// case the caller keeps the original photo.
Future<File?> showPhotoCropScreen(
  BuildContext context, {
  required File inputFile,
  required String label,
}) {
  return Navigator.of(context).push<File>(
    MaterialPageRoute<File>(
      fullscreenDialog: true,
      builder: (_) => PhotoCropScreen(inputFile: inputFile, label: label),
    ),
  );
}

/// A full-screen crop and rotation editor for a product photo.
///
/// Shows the photo behind a [CropImage] grid with rotate-left and rotate-right
/// controls. Applying runs [ProductPhotoCropper.crop] with the current crop
/// rectangle and rotation and pops the resulting file; closing pops null
/// without touching the source file, so cropping is non-destructive.
///
/// The crop rectangle is rejected when either predicted output side is below
/// [ProductPhotoCropper.minimumDimension] so a too-small crop can never be
/// committed. On apply failure the screen stays open with an error snackbar.
class PhotoCropScreen extends ConsumerStatefulWidget {
  /// Creates a [PhotoCropScreen] for the given [inputFile] and [label].
  const PhotoCropScreen({
    required this.inputFile,
    required this.label,
    super.key,
  });

  /// The photo to crop. It is never modified by this screen.
  final File inputFile;

  /// A human-readable name for the photo slot, e.g. "Nutrition table".
  final String label;

  @override
  ConsumerState<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends ConsumerState<PhotoCropScreen> {
  late final CropController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CropController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.of(context).pop();
  }

  /// Crops the photo with the current crop rectangle and rotation and pops
  /// the result, or keeps the screen open with a warning when the crop is too
  /// small or the cropper fails.
  Future<void> _apply() async {
    final l10n = AppLocalizations.of(context)!;
    final image = _controller.getImage();
    if (image == null) return;
    final sideways = _controller.rotation.isSideways;
    final cropWidth =
        _controller.crop.width * (sideways ? image.height : image.width);
    final cropHeight =
        _controller.crop.height * (sideways ? image.width : image.height);
    if (cropWidth < ProductPhotoCropper.minimumDimension ||
        cropHeight < ProductPhotoCropper.minimumDimension) {
      SnackbarHelper.showWarning(context, l10n.cropTooSmall);
      return;
    }
    final cropper = ref.read(productPhotoCropperProvider);
    final result = await cropper.crop(
      sourcePath: widget.inputFile.path,
      cropRect: _controller.crop,
      rotation: _controller.rotation,
    );
    if (!mounted) return;
    if (result == null) {
      SnackbarHelper.showWarning(context, l10n.cropFailed);
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.label),
        leading: Semantics(
          button: true,
          label: l10n.close,
          excludeSemantics: true,
          child: IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.close,
            onPressed: _close,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _rotateButton(
                    tooltip: l10n.rotateLeft,
                    icon: Icons.rotate_left,
                    onPressed: _controller.rotateLeft,
                  ),
                  _rotateButton(
                    tooltip: l10n.rotateRight,
                    icon: Icons.rotate_right,
                    onPressed: _controller.rotateRight,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CropImage(
                  controller: _controller,
                  image: Image.file(widget.inputFile),
                  gridCornerSize: 36,
                  touchSize: 48,
                  paddingSize: 12,
                  alwaysMove: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.crop),
                  label: Text(l10n.applyCrop),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rotateButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
