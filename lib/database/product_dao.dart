import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the `products` table.
///
/// All methods receive a [Database] instance so they can be used
/// independently of `DatabaseHelper` in tests.
class ProductDao {
  /// Creates a [ProductDao].
  const ProductDao();

  /// Converts a [Product] to a map for database insertion.
  Map<String, dynamic> toMap(Product p) => {
    'barcode': p.barcode,
    'name': p.name,
    'brand': p.brand,
    'image_url': p.imageUrl,
    'category': p.category,
    'ingredients': p.ingredients,
    'serving_size': p.servingSize,
    'energy_kcal': p.energyKcal,
    'protein_g': p.proteinG,
    'carbs_g': p.carbsG,
    'fat_g': p.fatG,
    'fiber_g': p.fiberG,
    'salt_g': p.saltG,
    'last_synced': p.lastSynced,
    'nutriscore_grade': p.nutriscoreGrade,
  };

  /// Converts a database row map into a [Product].
  Product fromMap(Map<String, dynamic> map) => Product(
    barcode: map['barcode'] as String,
    name: map['name'] as String,
    brand: map['brand'] as String?,
    imageUrl: map['image_url'] as String?,
    category: map['category'] as String?,
    ingredients: map['ingredients'] as String?,
    servingSize: map['serving_size'] as String?,
    energyKcal: (map['energy_kcal'] as num?)?.toDouble(),
    proteinG: (map['protein_g'] as num?)?.toDouble(),
    carbsG: (map['carbs_g'] as num?)?.toDouble(),
    fatG: (map['fat_g'] as num?)?.toDouble(),
    fiberG: (map['fiber_g'] as num?)?.toDouble(),
    saltG: (map['salt_g'] as num?)?.toDouble(),
    lastSynced: map['last_synced'] as int?,
    nutriscoreGrade: map['nutriscore_grade'] as String?,
  );

  /// Inserts a product into the local cache (upsert).
  Future<void> insert(Database db, Product product) async {
    logInfo('Inserting product: ${product.barcode} — ${product.name}');
    try {
      await db.insert(
        'products',
        toMap(product),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      logInfo('Product ${product.barcode} inserted/updated');
    } on Exception catch (e) {
      logError('Failed to insert product ${product.barcode}: $e');
      rethrow;
    }
  }

  /// Looks up a single product by its barcode.
  ///
  /// Returns `null` if no product with the given barcode exists.
  Future<Product?> get(Database db, String barcode) async {
    try {
      final result = await db.query(
        'products',
        where: 'barcode = ?',
        whereArgs: [barcode],
      );
      if (result.isEmpty) {
        logInfo('Product $barcode not found in cache');
        return null;
      }
      logInfo('Product $barcode found in cache');
      return fromMap(result.first);
    } on Exception catch (e) {
      logError('Error looking up product $barcode: $e');
      rethrow;
    }
  }

  /// Returns the total number of cached product records.
  Future<int> count(Database db) async {
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;
  }

  /// Returns all cached products.
  Future<List<Product>> all(Database db) async {
    final result = await db.query('products');
    return result.map(fromMap).toList();
  }

  /// Deletes all cached products from the table.
  Future<void> clear(Database db) async {
    await db.delete('products');
    logInfo('All cached products deleted');
  }
}
