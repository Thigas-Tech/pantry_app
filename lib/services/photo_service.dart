import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Service for capturing and managing price tag photos.
///
/// Photos are captured via the device camera or selected from the gallery,
/// then compressed and saved to a dedicated directory. Each photo is keyed
/// by shopping item ID so it can be located during delete or move-to-inventory
/// operations.
class PhotoService {
  /// Creates a [PhotoService].
  PhotoService({ImagePicker? picker, this.photoDirectory})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Directory where photos are stored, injected for testing.
  final Directory? photoDirectory;

  /// Opens the device camera and returns the path to the saved photo,
  /// or null if the user cancelled.
  Future<String?> capturePhoto(int itemId) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null) return null;
      return _savePhoto(file.path, itemId);
    } on Exception catch (e) {
      logError('Failed to capture photo: $e');
      return null;
    }
  }

  /// Opens the device gallery and returns the path to the saved photo,
  /// or null if the user cancelled.
  Future<String?> pickFromGallery(int itemId) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null) return null;
      return _savePhoto(file.path, itemId);
    } on Exception catch (e) {
      logError('Failed to pick photo from gallery: $e');
      return null;
    }
  }

  /// Saves the image at [sourcePath] to the photo cache directory and
  /// returns the destination path.
  Future<String> _savePhoto(String sourcePath, int itemId) async {
    final dir = await _photoDirectory();
    final destPath = join(dir.path, '$itemId.jpg');
    final sourceFile = File(sourcePath);
    await sourceFile.copy(destPath);
    logInfo('Photo saved for item $itemId at $destPath');
    return destPath;
  }

  /// Deletes the photo at [path] if it exists.
  Future<void> deletePhoto(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        logInfo('Photo deleted: $path');
      }
    } on Exception catch (e) {
      logError('Failed to delete photo $path: $e');
    }
  }

  /// Deletes the photo associated with the given shopping [itemId].
  Future<void> deletePhotoForItem(int itemId) async {
    final dir = await _photoDirectory();
    final path = join(dir.path, '$itemId.jpg');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      logInfo('Photo deleted for item $itemId');
    }
  }

  Future<Directory> _photoDirectory() async {
    if (photoDirectory != null) return photoDirectory!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(join(appDir.path, 'shopping_photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Deletes all cached price tag photos.
  Future<void> clearAllPhotos() async {
    try {
      final dir = await _photoDirectory();
      if (await dir.exists()) {
        final files = dir.listSync();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        logInfo('All price tag photos cleared');
      }
    } on Exception catch (e) {
      logError('Failed to clear price tag photos: $e');
    }
  }
}
