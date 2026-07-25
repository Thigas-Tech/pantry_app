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

      final recipes = await dao.listAll(db);
      expect(recipes.length, 3);
      expect(recipes[0].name, 'Third');
      expect(recipes[1].name, 'Second');
      expect(recipes[2].name, 'First');
    });

    test('listAll returns empty list when no recipes', () async {
      final recipes = await dao.listAll(db);
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
}
