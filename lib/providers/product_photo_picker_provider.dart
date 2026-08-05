import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/product_photo_picker.dart';

/// Provides the single [ProductPhotoPicker] used by the add-product screen.
///
/// Tests override this provider with a mock to avoid invoking the real
/// camera or gallery pickers.
final productPhotoPickerProvider = Provider<ProductPhotoPicker>(
  (ref) => ProductPhotoPicker(),
);
