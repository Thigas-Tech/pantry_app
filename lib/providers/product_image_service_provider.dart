import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_app/services/product_image_service.dart';

/// Provides the single [ProductImageService] used by the add-product screen.
///
/// Tests override this provider with a service pointed at a temporary
/// directory so photo persistence is exercised without camera hardware or a
/// real application-documents directory.
final productImageServiceProvider = Provider<ProductImageService>(
  (ref) => ProductImageService(),
);
