/// A recipe suggestion returned by a recipe API.
///
/// Represents a single candidate recipe matched against the user's
/// inventory. Phase 1 uses TheMealDB, so the fields mirror its meal
/// payload: a display [name] and a stable API [idMeal] used to avoid
/// suggesting the same recipe twice in a row.
class RecipeSuggestion {
  /// Creates a [RecipeSuggestion].
  const RecipeSuggestion({required this.name, required this.idMeal});

  /// The display name of the recipe (for example "Chicken Handi").
  final String name;

  /// The stable recipe identifier returned by the recipe API.
  final String idMeal;
}
