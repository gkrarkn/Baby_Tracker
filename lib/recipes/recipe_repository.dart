import 'dart:convert';
import 'package:flutter/services.dart';
import 'recipe.dart';

class RecipeRepository {
  const RecipeRepository();

  Future<List<Recipe>> loadAll() async {
    final raw = await rootBundle.loadString('assets/recipes/recipes_tr.json');
    final decoded = json.decode(raw);

    final list = (decoded is Map && decoded['recipes'] is List)
        ? decoded['recipes'] as List
        : (decoded as List? ?? const []);

    return list.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Recipe>> forAge(int babyMonths) async {
    final all = await loadAll();
    final filtered = all.where((r) => babyMonths >= r.ageMinMonths).toList();

    filtered.sort((a, b) {
      final da = (babyMonths - a.ageMinMonths).abs();
      final db = (babyMonths - b.ageMinMonths).abs();
      final c = da.compareTo(db);
      return c != 0 ? c : a.prepTimeMin.compareTo(b.prepTimeMin);
    });

    return filtered;
  }
}
