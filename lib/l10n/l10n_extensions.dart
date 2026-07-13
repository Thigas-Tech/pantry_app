import 'package:pantry_app/l10n/app_localizations.dart';

/// Extension on [AppLocalizations] providing convenience methods for
/// formatting quantities, localizing units, locations, inventory names,
/// and theme modes.
extension AppLocalizationsX on AppLocalizations {
  /// Formats a quantity with a localized unit (e.g., "5 kg").
  String formatQuantityUnit(double? quantity, String? unit) {
    if (quantity == null || unit == null) return '';
    return '${quantity.toInt()} ${localizeUnit(unit)}';
  }

  /// Returns the localized string for a unit code.
  String localizeUnit(String unit) {
    switch (unit.toLowerCase()) {
      case 'pieces':
        return unitPieces;
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
