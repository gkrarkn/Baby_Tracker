// lib/recipes/recipe_favorites_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeFavoritesService extends ChangeNotifier {
  static const _key = 'favorite_recipe_ids';

  final Set<String> _favorites = {};

  Set<String> get favorites => _favorites;

  bool isFavorite(String recipeId) {
    return _favorites.contains(recipeId);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_key) ?? [];
    _favorites
      ..clear()
      ..addAll(stored);
    notifyListeners();
  }

  Future<void> toggle(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();

    if (_favorites.contains(recipeId)) {
      _favorites.remove(recipeId);
    } else {
      _favorites.add(recipeId);
    }

    await prefs.setStringList(_key, _favorites.toList());
    notifyListeners();
  }

  bool get hasFavorites => _favorites.isNotEmpty;
}
