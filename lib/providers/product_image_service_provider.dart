import 'package:pantry_app/services/product_image_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_image_service_provider.g.dart';

/// Provides the single [ProductImageService] used by the add-product screen.
///
/// Tests override this provider with a service pointed at a temporary
/// directory so photo persistence is exercised without camera hardware or a
/// real application-documents directory.
@Riverpod(keepAlive: true)
ProductImageService productImageService(Ref ref) {
  return ProductImageService();
}
