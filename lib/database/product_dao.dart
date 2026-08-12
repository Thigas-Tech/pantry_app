import 'dart:convert';

import 'package:pantry_app/database/database_helper.dart';
import 'package:pantry_app/models/product.dart';
import 'package:pantry_app/models/product_nutrient.dart';
import 'package:pantry_app/models/product_type.dart';
import 'package:pantry_app/utils/logger.dart';
import 'package:pantry_app/utils/search_utils.dart';
import 'package:sqflite/sqflite.dart';

/// Data-access layer for the products table.
///
/// All methods receive a [Database] instance so they can be used
/// independently of [DatabaseHelper] in tests.
class ProductDao {
  /// Creates a [ProductDao].
  const ProductDao();

  /// Decodes the additional_nutrients JSON column into a nutrient list.
  ///
  /// Returns an empty list when the column is null, empty, or holds corrupt
  /// JSON so a malformed row never crashes a product read.
  /// Decodes the additional_nutrients JSON column into nutrient objects.
  ///
  /// Returns an empty list for null, blank, non-list, or corrupt JSON and
  /// skips entries whose shape does not match [ProductNutrient] so a single
  /// bad row never breaks the whole product.
  static List<ProductNutrient> decodeAdditionalNutrients(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .where(
            (entry) =>
                entry['offTag'] is String &&
                entry['value'] is num &&
                entry['unit'] is String,
          )
          .map(ProductNutrient.fromJson)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  /// Converts a [Product] to a map for database insertion.
  Map<String, dynamic> toMap(Product p) => {
    'barcode': p.barcode,
    'name': p.name,
    'brand': p.brand,
    'image_url': p.imageUrl,
    'category': p.category,
    'ingredients': p.ingredients,
    'serving_size': p.servingSize,
    'serving_quantity': p.servingQuantity,
    'quantity': p.quantity,
    'product_quantity': p.productQuantity,
    'energy_kcal': p.energyKcal,
    'protein_g': p.proteinG,
    'carbs_g': p.carbsG,
    'fat_g': p.fatG,
    'fiber_g': p.fiberG,
    'salt_g': p.saltG,
    'additional_nutrients': p.additionalNutrients.isNotEmpty
        ? jsonEncode(p.additionalNutrients.map((n) => n.toJson()).toList())
        : null,
    'last_synced': p.lastSynced,
    'nutriscore_grade': p.nutriscoreGrade,
    'nutriscore_not_applicable_category': p.nutriscoreNotApplicableCategory,
    'source': p.source,
    'nutrition_image_path': p.nutritionImagePath,
    'ingredients_image_path': p.ingredientsImagePath,
    'product_image_path': p.productImagePath,
    'submission_status': p.submissionStatus,
    'off_nutrition_image_url': p.offNutritionImageUrl,
    'off_ingredients_image_url': p.offIngredientsImageUrl,
    'off_product_image_url': p.offProductImageUrl,
    'categories_hierarchy': p.categoriesHierarchy != null
        ? jsonEncode(p.categoriesHierarchy)
        : null,
    'language_code': p.languageCode,
    'plu_code': p.pluCode,
    'product_type': p.productType.name,
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
    servingQuantity: (map['serving_quantity'] as num?)?.toDouble(),
    quantity: map['quantity'] as String?,
    productQuantity: (map['product_quantity'] as num?)?.toDouble(),
    energyKcal: (map['energy_kcal'] as num?)?.toDouble(),
    proteinG: (map['protein_g'] as num?)?.toDouble(),
    carbsG: (map['carbs_g'] as num?)?.toDouble(),
    fatG: (map['fat_g'] as num?)?.toDouble(),
    fiberG: (map['fiber_g'] as num?)?.toDouble(),
    saltG: (map['salt_g'] as num?)?.toDouble(),
    additionalNutrients: decodeAdditionalNutrients(
      map['additional_nutrients'] as String?,
    ),
    lastSynced: map['last_synced'] as int?,
    nutriscoreGrade: map['nutriscore_grade'] as String?,
    nutriscoreNotApplicableCategory:
        map['nutriscore_not_applicable_category'] as String?,
    source: map['source'] as String? ?? 'api',
    nutritionImagePath: map['nutrition_image_path'] as String?,
    ingredientsImagePath: map['ingredients_image_path'] as String?,
    productImagePath: map['product_image_path'] as String?,
    submissionStatus:
        map['submission_status'] as String? ?? productSubmissionNotSubmitted,
    offNutritionImageUrl: map['off_nutrition_image_url'] as String?,
    offIngredientsImageUrl: map['off_ingredients_image_url'] as String?,
    offProductImageUrl: map['off_product_image_url'] as String?,
    categoriesHierarchy: map['categories_hierarchy'] != null
        ? (jsonDecode(map['categories_hierarchy'] as String) as List<dynamic>)
              .cast<String>()
        : null,
    languageCode: (map['language_code'] as String?) ?? 'en',
    pluCode: map['plu_code'] as String?,
    productType: map['product_type'] != null
        ? ProductType.values.firstWhere(
            (t) => t.name == map['product_type'],
            orElse: () => ProductType.barcoded,
          )
        : ProductType.barcoded,
  );

  /// Inserts a product into the local cache (upsert).
  ///
  /// Throws [ArgumentError] if [db] is null or [product.barcode] is empty.
  Future<void> insert(Database db, Product product) async {
    if (db == null) {
      throw ArgumentError('db must not be null');
    }
    if (product.barcode == null || product.barcode!.isEmpty) {
      throw ArgumentError('product barcode must not be empty');
    }
    logInfo('Inserting product: ${product.barcode} — ${product.name}');
    try {
      final map = toMap(product);
      map['search_text'] = buildSearchText(product);
      await db.insert(
        'products',
        map,
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
  /// Returns null if no product with the given barcode exists.
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

  /// Searches the products table by name or barcode.
  ///
  /// The search is accent- and case-insensitive because both the query
  /// and the stored search_text column are normalized identically.
  ///
  /// **Filtering**: uses LIKE '%escaped%' on the indexed search_text
  /// column to quickly narrow candidates.
  ///
  /// Throws [ArgumentError] if [query] is empty or null.
  Future<List<Product>> search(
    Database db,
    String query, {
    int limit = 30,
  }) async {
    if (query == null || query.isEmpty) {
      throw ArgumentError('search query must not be empty');
    }
    final normalizedQuery = normalizeForSearch(query);
    if (normalizedQuery.isEmpty) return <Product>[];

    try {
      // Escape special SQLite LIKE characters.
      final escaped = normalizedQuery
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_');

      // Fast substring filter.
      final rows = await db.query(
        'products',
        where: r"search_text LIKE ? ESCAPE '\'",
        whereArgs: ['%$escaped%'],
        orderBy: 'name ASC',
        limit: limit,
      );

      final products = rows.map(fromMap).toList();
      logInfo('Search for "$query" returned ${products.length} results');
      return products;
    } on Exception catch (e) {
      logError('Error searching products for "$query": $e');
      rethrow;
    }
  }

  /// Deletes all cached products from the table.
  Future<void> clear(Database db) async {
    await db.delete('products');
    logInfo('All cached products deleted');
  }

  /// Returns products with the given [source] value.
  ///
  /// Used to retrieve only API‑fetched products for cache refresh.
  Future<List<Product>> getBySource(Database db, String source) async {
    final result = await db.query(
      'products',
      where: 'source = ?',
      whereArgs: [source],
    );
    return result.map(fromMap).toList();
  }

  /// Deletes products with the given [source] value.
  ///
  /// Called by [DatabaseHelper.clearCachedProducts] to remove only
  /// API‑fetched products while preserving user‑entered records.
  Future<void> deleteBySource(Database db, String source) async {
    final count = await db.delete(
      'products',
      where: 'source = ?',
      whereArgs: [source],
    );
    logInfo('Deleted $count products with source "$source"');
  }

  /// Returns counts of products grouped by Nutri-Score grade.
  ///
  /// Only API-sourced products with a non-null Nutri-Score are included.
  /// The returned map uses grade strings as keys (e.g. 'a', 'b').
  Future<Map<String, int>> nutriscoreDistribution(Database db) async {
    final rows = await db.rawQuery('''
      SELECT nutriscore_grade, COUNT(*) as cnt
      FROM products
      WHERE nutriscore_grade IS NOT NULL AND source = 'api'
      GROUP BY nutriscore_grade
    ''');
    return {
      for (final r in rows)
        r['nutriscore_grade'] as String? ?? '': r['cnt'] as int? ?? 0,
    };
  }

  /// Returns the top N categories with product counts.
  Future<List<Map<String, dynamic>>> categoryDistribution(
    Database db, {
    int limit = 10,
  }) {
    return db.rawQuery(
      '''
      SELECT category, COUNT(*) as cnt
      FROM products
      WHERE category IS NOT NULL
      GROUP BY category
      ORDER BY cnt DESC
      LIMIT ?
    ''',
      [limit],
    );
  }

  /// Returns counts of products grouped by source (api / manual).
  Future<Map<String, int>> sourceDistribution(Database db) async {
    final rows = await db.rawQuery('''
      SELECT source, COUNT(*) as cnt
      FROM products
      GROUP BY source
    ''');
    return {
      for (final r in rows) r['source'] as String? ?? '': r['cnt'] as int? ?? 0,
    };
  }

  /// Returns counts of local photos attached to products.
  ///
  /// The returned map has keys total, nutrition, ingredients,
  /// product.
  Future<Map<String, int>> photoCompleteness(Database db) async {
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN nutrition_image_path IS NOT NULL THEN 1 ELSE 0 END)
          as nutrition,
        SUM(CASE WHEN ingredients_image_path IS NOT NULL THEN 1 ELSE 0 END)
          as ingredients,
        SUM(CASE WHEN product_image_path IS NOT NULL THEN 1 ELSE 0 END)
          as product
      FROM products
    ''');
    final r = rows.first;
    return {
      'total': r['total'] as int? ?? 0,
      'nutrition': r['nutrition'] as int? ?? 0,
      'ingredients': r['ingredients'] as int? ?? 0,
      'product': r['product'] as int? ?? 0,
    };
  }

  /// Returns counts of OFF photo URLs available for products.
  ///
  /// Only products with source = 'api' are counted (manual products are
  /// never on OFF). The returned map uses the same keys as
  /// [photoCompleteness].
  Future<Map<String, int>> offPhotoCompleteness(Database db) async {
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) as total,
        SUM(CASE WHEN off_nutrition_image_url IS NOT NULL
              AND off_nutrition_image_url != '' THEN 1 ELSE 0 END)
          as nutrition,
        SUM(CASE WHEN off_ingredients_image_url IS NOT NULL
              AND off_ingredients_image_url != '' THEN 1 ELSE 0 END)
          as ingredients,
        SUM(CASE WHEN off_product_image_url IS NOT NULL
              AND off_product_image_url != '' THEN 1 ELSE 0 END)
          as product
      FROM products
      WHERE source = 'api'
    ''');
    final r = rows.first;
    return {
      'total': r['total'] as int? ?? 0,
      'nutrition': r['nutrition'] as int? ?? 0,
      'ingredients': r['ingredients'] as int? ?? 0,
      'product': r['product'] as int? ?? 0,
    };
  }

  /// Returns all product rows with category and hierarchy for grouping.
  Future<List<Map<String, dynamic>>> productsWithCategories(
    Database db,
  ) {
    return db.rawQuery('''
      SELECT category, categories_hierarchy
      FROM products
      WHERE category IS NOT NULL
    ''');
  }
}
