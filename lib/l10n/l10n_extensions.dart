import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'package:pantry_app/l10n/app_localizations.dart';

/// Extension on [AppLocalizations] providing convenience methods for
/// formatting quantities, localizing units, locations, inventory names,
/// theme modes, and produce names.
extension AppLocalizationsX on AppLocalizations {
  /// Returns the localized name for a produce item.
  ///
  /// When the name has no matching ARB key, returns the input capitalized.
  String localizeProduceName(String name) {
    switch (name.toLowerCase().trim()) {
      case 'apple':
        return produceApple;
      case 'banana':
        return produceBanana;
      case 'orange':
        return produceOrange;
      case 'tomato':
        return produceTomato;
      case 'potato':
        return producePotato;
      case 'carrot':
        return produceCarrot;
      case 'onion':
        return produceOnion;
      case 'lettuce':
        return produceLettuce;
      default:
        if (name.isEmpty) return name;
        return name[0].toUpperCase() + name.substring(1);
    }
  }

  /// Formats a quantity with a localized unit (e.g., "5 kg").
  ///
  /// When [unit] is 'pieces', the display uses [unitSingular] for
  /// quantity 1 and [unitPlural] for all other quantities.
  String formatQuantityUnit(double? quantity, String? unit) {
    if (quantity == null || unit == null) return '';
    if (unit == 'pieces') {
      final label = quantity == 1 ? unitSingular : unitPlural;
      return '${quantity.toInt()} $label';
    }
    if (quantity == quantity.toInt()) {
      return '${quantity.toInt()} ${localizeUnit(unit)}';
    }
    return '$quantity ${localizeUnit(unit)}';
  }

  /// Returns the localized string for a unit code.
  String localizeUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'pieces':
        return unitSingular;
      case 'g':
      case 'grams':
        return unitGrams;
      case 'kg':
      case 'kgs':
        return unitKg;
      case 'ml':
        return unitMl;
      case 'l':
      case 'liter':
      case 'liters':
        return unitLiter;
      default:
        return unit;
    }
  }

  /// Returns the localized name for an [off.Nutrient].
  ///
  /// Covers the curated set offered by the nutrition editor and displayed by
  /// the nutrition table. Unknown nutrients fall back to the SDK tag.
  String localizeNutrient(off.Nutrient nutrient) {
    switch (nutrient) {
      case off.Nutrient.saturatedFat:
        return nutrientSaturatedFat;
      case off.Nutrient.monounsaturatedFat:
        return nutrientMonounsaturatedFat;
      case off.Nutrient.polyunsaturatedFat:
        return nutrientPolyunsaturatedFat;
      case off.Nutrient.transFat:
        return nutrientTransFat;
      case off.Nutrient.cholesterol:
        return nutrientCholesterol;
      case off.Nutrient.omega3:
        return nutrientOmega3;
      case off.Nutrient.omega6:
        return nutrientOmega6;
      case off.Nutrient.sugars:
        return nutrientSugars;
      case off.Nutrient.addedSugars:
        return nutrientAddedSugars;
      case off.Nutrient.starch:
        return nutrientStarch;
      case off.Nutrient.sugarAlcohol:
        return nutrientSugarAlcohol;
      case off.Nutrient.solubleFiber:
        return nutrientSolubleFiber;
      case off.Nutrient.insolubleFiber:
        return nutrientInsolubleFiber;
      case off.Nutrient.sodium:
        return nutrientSodium;
      case off.Nutrient.potassium:
        return nutrientPotassium;
      case off.Nutrient.calcium:
        return nutrientCalcium;
      case off.Nutrient.iron:
        return nutrientIron;
      case off.Nutrient.magnesium:
        return nutrientMagnesium;
      case off.Nutrient.phosphorus:
        return nutrientPhosphorus;
      case off.Nutrient.zinc:
        return nutrientZinc;
      case off.Nutrient.copper:
        return nutrientCopper;
      case off.Nutrient.manganese:
        return nutrientManganese;
      case off.Nutrient.selenium:
        return nutrientSelenium;
      case off.Nutrient.chromium:
        return nutrientChromium;
      case off.Nutrient.molybdenum:
        return nutrientMolybdenum;
      case off.Nutrient.fluoride:
        return nutrientFluoride;
      case off.Nutrient.iodine:
        return nutrientIodine;
      case off.Nutrient.chloride:
        return nutrientChloride;
      case off.Nutrient.vitaminA:
        return nutrientVitaminA;
      case off.Nutrient.vitaminC:
        return nutrientVitaminC;
      case off.Nutrient.vitaminD:
        return nutrientVitaminD;
      case off.Nutrient.vitaminE:
        return nutrientVitaminE;
      case off.Nutrient.vitaminK:
        return nutrientVitaminK;
      case off.Nutrient.vitaminB1:
        return nutrientVitaminB1;
      case off.Nutrient.vitaminB2:
        return nutrientVitaminB2;
      case off.Nutrient.vitaminPP:
        return nutrientVitaminPP;
      case off.Nutrient.vitaminB6:
        return nutrientVitaminB6;
      case off.Nutrient.vitaminB9:
        return nutrientVitaminB9;
      case off.Nutrient.vitaminB12:
        return nutrientVitaminB12;
      case off.Nutrient.biotin:
        return nutrientBiotin;
      case off.Nutrient.pantothenicAcid:
        return nutrientPantothenicAcid;
      case off.Nutrient.choline:
        return nutrientCholine;
      case off.Nutrient.caffeine:
        return nutrientCaffeine;
      case off.Nutrient.alcohol:
        return nutrientAlcohol;
      case off.Nutrient.cocoa:
        return nutrientCocoa;
      case off.Nutrient.fruitsVegetablesNuts:
        return nutrientFruitsVegetablesNuts;
      case _:
        return nutrient.offTag;
    }
  }

  /// Returns the localized string for a location code.
  String localizeLocation(String location) {
    switch (location.toLowerCase()) {
      case 'pantry':
        return locationPantry;
      case 'fridge':
      case 'refrigerator':
        return locationFridge;
      case 'freezer':
        return locationFreezer;
      default:
        return location;
    }
  }

  /// Returns the display name for an inventory, localizing the default names.
  String displayInventoryName(String name) {
    if (name == 'Home' || name == 'Casa') {
      return defaultInventoryName;
    }
    return name;
  }

  /// Returns the localized name for a theme mode name.
  String localizeThemeMode(String modeName) {
    switch (modeName) {
      case 'system':
        return themeModeSystem;
      case 'light':
        return themeModeLight;
      case 'dark':
        return themeModeDark;
      default:
        return modeName;
    }
  }

  /// Returns the localized name for a product category.
  String localizeCategory(String category) {
    switch (category) {
      case 'Dairy':
        return categoryDairy;
      case 'Milks':
        return categoryMilks;
      case 'Milk':
        return categoryMilk;
      case 'Yogurts':
        return categoryYogurts;
      case 'Cheeses':
        return categoryCheeses;
      case 'Eggs and their products':
        return categoryEggsAndProducts;
      case 'Meats':
        return categoryMeats;
      case 'Fishes and seafoods':
        return categoryFishesAndSeafoods;
      case 'Beverages':
        return categoryBeverages;
      case 'Alcoholic beverages':
        return categoryAlcoholicBeverages;
      case 'Breads':
        return categoryBreads;
      case 'Cereals and potatoes':
        return categoryCerealsAndPotatoes;
      case 'Fruits and vegetables based foods':
        return categoryFruitsAndVegetables;
      case 'Confectioneries':
        return categoryConfectioneries;
      case 'Sugary snacks':
        return categorySugarySnacks;
      case 'Salty snacks':
        return categorySaltySnacks;
      case 'Fats':
        return categoryFats;
      case 'Sauces':
        return categorySauces;
      case 'Soups':
        return categorySoups;
      case 'Prepared meals':
        return categoryPreparedMeals;
      case 'Frozen foods':
        return categoryFrozenFoods;
      case 'Desserts':
        return categoryDesserts;
      case 'Pastries':
        return categoryPastries;
      case 'Biscuits and cakes':
        return categoryBiscuitsAndCakes;
      case 'Pizzas':
        return categoryPizzas;
      case 'Sandwiches':
        return categorySandwiches;
      case 'Baby foods':
        return categoryBabyFoods;
      case 'Dietary foods':
        return categoryDietaryFoods;
      case 'Spices and herbs':
        return categorySpicesAndHerbs;
      case 'Nuts and their products':
        return categoryNutsAndProducts;
      case 'Plant based foods':
        return categoryPlantBasedFoods;
      case 'Legumes and their products':
        return categoryLegumesAndProducts;
      case 'Coffees':
        return categoryCoffees;
      case 'Teas':
        return categoryTeas;
      case 'Chocolate products':
        return categoryChocolateProducts;
      case 'Ice creams':
        return categoryIceCreams;
      case 'Fruit juices':
        return categoryFruitJuices;
      case 'Sodas':
        return categorySodas;
      case 'Waters':
        return categoryWaters;
      case 'Meat and their products':
        return categoryMeatAndProducts;
      case 'Breakfasts':
        return categoryBreakfasts;
      case 'Bread':
        return categoryBread;
      case 'Cakes':
        return categoryCakes;
      case 'Cereals':
        return categoryCereals;
      case 'Chocolate':
        return categoryChocolate;
      case 'Condiments':
        return categoryCondiments;
      case 'Eggs':
        return categoryEggs;
      case 'Fish':
        return categoryFish;
      case 'Fruit':
        return categoryFruit;
      case 'Fruits':
        return categoryFruits;
      case 'Grains':
        return categoryGrains;
      case 'Hot beverages':
        return categoryHotBeverages;
      case 'Legumes':
        return categoryLegumes;
      case 'Oils':
        return categoryOils;
      case 'Pasta':
        return categoryPasta;
      case 'Poultry':
        return categoryPoultry;
      case 'Seeds':
        return categorySeeds;
      case 'Snacks':
        return categorySnacks;
      case 'Spreads':
        return categorySpreads;
      case 'Sweet spreads':
        return categorySweetSpreads;
      case 'Vegetables':
        return categoryVegetables;
      case 'Biscuits and crackers':
        return categoryBiscuitsAndCrackers;
      case 'Legume oils':
        return categoryLegumeOils;
      case 'Uht milks':
        return categoryUhtMilks;
      case 'Canned sardines':
        return categoryCannedSardines;
      case 'Cereal flours':
        return categoryCerealFlours;
      case 'Cereal starches':
        return categoryCerealStarches;
      case 'Cereals and their products':
        return categoryCerealsAndProducts;
      case 'Dairies':
        return categoryDairies;
      case 'Instant beverages':
        return categoryInstantBeverages;
      case 'Milkfat':
        return categoryMilkfat;
      case 'Starches':
        return categoryStarches;
      default:
        return category;
    }
  }
}
