import 'dart:math';

import 'recipe.dart';

class RecipeRotationService {
  /// Aynı yaş için tarifleri belirli periyotlarla döndürür
  /// - all: repository’den gelen tüm tarifler
  /// - maxCount: ekranda gösterilecek kart sayısı
  static List<Recipe> selectRecipes({
    required List<Recipe> all,
    required int ageInMonths,
    int maxCount = 6,
  }) {
    if (all.isEmpty) return const [];

    // Haftalık seed (aynı hafta aynı sonuç)
    final now = DateTime.now();
    final weekSeed = now.year * 100 + _weekNumber(now);
    final rnd = Random(weekSeed + ageInMonths);

    final shuffled = List<Recipe>.from(all)..shuffle(rnd);

    return shuffled.take(maxCount).toList();
  }

  static int _weekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final days = date.difference(firstDayOfYear).inDays;
    return (days / 7).floor() + 1;
  }
}
