import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/product_photo_cropper.dart';

/// Provides the [ProductPhotoCropper] used by the crop screen.
///
/// Tests override this provider with a fake cropper so widget tests can
/// verify the crop screen wiring without encoding real images.
final productPhotoCropperProvider = Provider<ProductPhotoCropper>(
  (ref) => ProductPhotoCropper(),
);
