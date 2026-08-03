import 'package:flutter_test/flutter_test.dart';
import 'package:pantry_app/database/recipe_dao.dart';
import 'package:pantry_app/models/recipe.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late RecipeDao dao;

  setUp(() async {
    dao = const RecipeDao();
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await dao.createTable(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RecipeDao', () {
    test('createTable creates the table', () async {
      final id = await dao.insert(
        db,
        const Recipe(name: 'Test Recipe'),
      );
      expect(id, isNonNegative);
    });

    test('insert returns id and sets timestamps', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = await dao.insert(
        db,
        const Recipe(name: 'Soup'),
      );

      expect(id, greaterThan(0));
      final recipe = await dao.get(db, id);
      expect(recipe, isNotNull);
      expect(recipe!.name, 'Soup');
      expect(recipe.createdAt, lessThanOrEqualTo(now));
      expect(recipe.updatedAt, lessThanOrEqualTo(now));
    });

    test('get returns null for non-existent id', () async {
      final recipe = await dao.get(db, 999);
      expect(recipe, isNull);
    });

    test('get returns correct recipe', () async {
      final id = await dao.insert(
        db,
        const Recipe(
          name: 'Pasta',
          instructions: 'Boil water. Cook pasta.',
        ),
      );

      final recipe = await dao.get(db, id);
      expect(recipe, isNotNull);
      expect(recipe!.name, 'Pasta');
      expect(recipe.instructions, 'Boil water. Cook pasta.');
      expect(recipe.id, id);
    });

    test('listAll returns recipes ordered by updated_at DESC', () async {
      await dao.insert(
        db,
        const Recipe(name: 'First', updatedAt: 100),
      );
      await dao.insert(
        db,
        const Recipe(name: 'Second', updatedAt: 200),
      );
      await dao.insert(
        db,
        const Recipe(name: 'Third', updatedAt: 300),
      );

      final recipes = await dao.listAll(db, 1);
      expect(recipes.length, 3);
      expect(recipes[0].name, 'Third');
      expect(recipes[1].name, 'Second');
      expect(recipes[2].name, 'First');
    });

    test('listAll returns empty list when no recipes', () async {
      final recipes = await dao.listAll(db, 1);
      expect(recipes, isEmpty);
    });

    test('update preserves createdAt and bumps updatedAt', () async {
      final id = await dao.insert(
        db,
        const Recipe(
          name: 'Salad',
          instructions: 'Chop veggies.',
          createdAt: 100,
          updatedAt: 100,
        ),
      );

      await dao.update(
        db,
        Recipe(
          id: id,
          name: 'Caesar Salad',
          instructions: 'Chop veggies. Add dressing.',
          createdAt: 100,
          // updatedAt should be overwritten by the DAO
        ),
      );

      final recipe = await dao.get(db, id);
      expect(recipe!.name, 'Caesar Salad');
      expect(recipe.instructions, 'Chop veggies. Add dressing.');
      expect(recipe.createdAt, 100);
      expect(recipe.updatedAt, greaterThan(100));
    });

    test('delete removes the recipe', () async {
      final id = await dao.insert(
        db,
        const Recipe(name: 'Soup'),
      );
      await dao.delete(db, id);

      final recipe = await dao.get(db, id);
      expect(recipe, isNull);
    });

    test('count returns correct total', () async {
      expect(await dao.count(db), 0);

      await dao.insert(db, const Recipe(name: 'A'));
      expect(await dao.count(db), 1);

      await dao.insert(db, const Recipe(name: 'B'));
      expect(await dao.count(db), 2);
    });

    test('delete returns 0 for non-existent id', () async {
      final affected = await dao.delete(db, 999);
      expect(affected, 0);
    });
  });

  group('RecipeDao inventory scoping', () {
    test('createTable includes inventory_id column', () async {
      final cols = await db.rawQuery("PRAGMA table_info('recipes')");
      expect(cols.map((c) => c['name']), contains('inventory_id'));
    });

    test('toMap writes inventory_id', () {
      final map = dao.toMap(const Recipe(name: 'Soup', inventoryId: 2));
      expect(map['inventory_id'], 2);
    });

    test('fromMap reads inventory_id with default 1', () {
      final recipe = dao.fromMap({
        'id': 1,
        'name': 'Soup',
        'instructions': '',
        'servings': 2,
        'image_path': '',
        'created_at': 100,
        'updated_at': 200,
        'inventory_id': 2,
      });
      expect(recipe.inventoryId, 2);

      final fallback = dao.fromMap({
        'id': 2,
        'name': 'Broth',
        'instructions': '',
        'servings': 1,
        'image_path': '',
        'created_at': 100,
        'updated_at': 200,
      });
      expect(fallback.inventoryId, 1);
    });

    test('insert persists inventory_id', () async {
      final id = await dao.insert(
        db,
        const Recipe(name: 'Soup', inventoryId: 2),
      );
      final recipe = await dao.get(db, id);
      expect(recipe!.inventoryId, 2);
    });

    test('listAll filters recipes by inventory', () async {
      await dao.insert(
        db,
        const Recipe(name: 'A', updatedAt: 100),
      );
      await dao.insert(
        db,
        const Recipe(name: 'B', inventoryId: 2, updatedAt: 200),
      );
      await dao.insert(
        db,
        const Recipe(name: 'C', inventoryId: 2, updatedAt: 300),
      );

      final inv1 = await dao.listAll(db, 1);
      final inv2 = await dao.listAll(db, 2);

      expect(inv1.map((r) => r.name), ['A']);
      expect(inv2.map((r) => r.name), ['C', 'B']);
    });

    test('update preserves existing inventory_id', () async {
      final id = await dao.insert(
        db,
        const Recipe(name: 'A', inventoryId: 2),
      );
      await dao.update(
        db,
        Recipe(id: id, name: 'A2'),
      );

      final recipe = await dao.get(db, id);
      expect(recipe!.name, 'A2');
      expect(recipe.inventoryId, 2);
    });
  });
}
