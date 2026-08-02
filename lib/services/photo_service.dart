import 'dart:io';

import 'package:pantry_app/utils/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing price tag photos keyed by shopping item ID.
///
/// Photos are saved to a dedicated directory and located by item ID during
/// delete or move-to-inventory operations.
class PhotoService {
  /// Creates a [PhotoService].
  PhotoService({this.photoDirectory});

  /// Directory where photos are stored, injected for testing.
  final Directory? photoDirectory;

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
}
