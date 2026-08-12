import 'package:pantry_app/services/product_photo_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_photo_picker_provider.g.dart';

/// Provides the single [ProductPhotoPicker] used by the add-product screen.
///
/// Tests override this provider with a mock to avoid invoking the real
/// camera or gallery pickers.
@Riverpod(keepAlive: true)
ProductPhotoPicker productPhotoPicker(Ref ref) {
  return ProductPhotoPicker();
}
