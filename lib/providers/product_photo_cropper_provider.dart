import 'package:pantry_app/services/product_photo_cropper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_photo_cropper_provider.g.dart';

/// Provides the [ProductPhotoCropper] used by the crop screen.
///
/// Tests override this provider with a fake cropper so widget tests can
/// verify the crop screen wiring without encoding real images.
@Riverpod(keepAlive: true)
ProductPhotoCropper productPhotoCropper(Ref ref) {
  return ProductPhotoCropper();
}
