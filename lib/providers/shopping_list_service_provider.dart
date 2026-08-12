import 'package:pantry_app/providers/database_provider.dart';
import 'package:pantry_app/providers/product_repository_provider.dart';
import 'package:pantry_app/providers/shopping_list_provider.dart';
import 'package:pantry_app/services/shopping_list_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shopping_list_service_provider.g.dart';

/// Provides the singleton [ShoppingListService] used by screens.
///
/// Kept alive for the app lifetime; the service holds no per-inventory
/// state, so a single instance is safe.
@Riverpod(keepAlive: true)
ShoppingListService shoppingListService(Ref ref) {
  return ShoppingListService(
    ref.read(databaseProvider),
    ref.read(productRepositoryProvider),
    ref.read(photoServiceProvider),
  );
}
