import 'package:pantry_app/database/migrations/migration.dart';
import 'package:pantry_app/database/migrations/v10_categories_hierarchy.dart';
import 'package:pantry_app/database/migrations/v12_prices_table.dart';
import 'package:pantry_app/database/migrations/v13_shopping_list_table.dart';
import 'package:pantry_app/database/migrations/v14_inventory_date_added_index.dart';
import 'package:pantry_app/database/migrations/v15_language_code.dart';
import 'package:pantry_app/database/migrations/v16_product_submission_queue.dart';
import 'package:pantry_app/database/migrations/v17_search_text.dart';
import 'package:pantry_app/database/migrations/v18_shopping_list_price_fields.dart';
import 'package:pantry_app/database/migrations/v19_stores_table.dart';
import 'package:pantry_app/database/migrations/v1_initial_schema.dart';
import 'package:pantry_app/database/migrations/v20_backfill_inventory_id.dart';
import 'package:pantry_app/database/migrations/v21_plu_and_product_type.dart';
import 'package:pantry_app/database/migrations/v22_serving_weight_g.dart';
import 'package:pantry_app/database/migrations/v23_backfill_produce_category.dart';
import 'package:pantry_app/database/migrations/v25_recipes.dart';
import 'package:pantry_app/database/migrations/v26_recipe_history.dart';
import 'package:pantry_app/database/migrations/v27_skipped.dart';
import 'package:pantry_app/database/migrations/v28_normalize_produce_barcodes.dart';
import 'package:pantry_app/database/migrations/v29_inventory_unique_index.dart';
import 'package:pantry_app/database/migrations/v2_inventories.dart';
import 'package:pantry_app/database/migrations/v30_recipe_indexes_and_search.dart';
import 'package:pantry_app/database/migrations/v31_serving_quantity.dart';
import 'package:pantry_app/database/migrations/v32_scan_history.dart';
import 'package:pantry_app/database/migrations/v33_recipes_inventory.dart';
import 'package:pantry_app/database/migrations/v34_prices_inventory.dart';
import 'package:pantry_app/database/migrations/v35_additional_nutrients.dart';
import 'package:pantry_app/database/migrations/v36_nonunique_inventory_index.dart';
import 'package:pantry_app/database/migrations/v37_prices_package.dart';
import 'package:pantry_app/database/migrations/v38_index_optimizations.dart';
import 'package:pantry_app/database/migrations/v39_inventory_shopping_indexes.dart';
import 'package:pantry_app/database/migrations/v3_normalize_units.dart';
import 'package:pantry_app/database/migrations/v41_shopping_sort_order.dart';
import 'package:pantry_app/database/migrations/v42_remove_firebase_cache_meta.dart';
import 'package:pantry_app/database/migrations/v43_remove_recipe_shared_id.dart';
import 'package:pantry_app/database/migrations/v44_query_performance_indexes.dart';
import 'package:pantry_app/database/migrations/v45_shopping_expiry.dart';
import 'package:pantry_app/database/migrations/v4_nutriscore_grade.dart';
import 'package:pantry_app/database/migrations/v5_nutriscore_not_applicable.dart';
import 'package:pantry_app/database/migrations/v6_source_column.dart';
import 'package:pantry_app/database/migrations/v7_image_paths.dart';
import 'package:pantry_app/database/migrations/v8_submission_status.dart';
import 'package:pantry_app/database/migrations/v9_off_image_urls.dart';

/// Returns all known migrations sorted by version.
List<Migration> allMigrations() => [
  MigrationV1(),
  MigrationV2(),
  MigrationV3(),
  MigrationV4(),
  MigrationV5(),
  MigrationV6(),
  MigrationV7(),
  MigrationV8(),
  MigrationV9(),
  MigrationV10(),
  MigrationV12(),
  MigrationV13(),
  MigrationV14(),
  MigrationV15(),
  MigrationV16(),
  MigrationV17(),
  MigrationV18(),
  MigrationV19(),
  MigrationV20(),
  MigrationV21(),
  MigrationV22(),
  MigrationV23(),
  MigrationV25(),
  MigrationV26(),
  MigrationV27(),
  MigrationV28(),
  MigrationV29(),
  MigrationV30(),
  MigrationV31(),
  MigrationV32(),
  MigrationV33(),
  MigrationV34(),
  MigrationV35(),
  MigrationV36(),
  MigrationV37(),
  MigrationV38(),
  MigrationV39(),
  MigrationV41(),
  MigrationV42(),
  MigrationV43(),
  MigrationV44(),
  MigrationV45(),
];
