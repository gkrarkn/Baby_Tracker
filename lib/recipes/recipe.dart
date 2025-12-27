class Recipe {
  final String id;
  final String title;
  final int ageMinMonths;
  final int prepTimeMin;
  final List<String> tags;
  final List<String> allergens;
  final List<String> ingredients;
  final List<String> steps;
  final String? nutritionNote;
  final String? imageAsset;

  const Recipe({
    required this.id,
    required this.title,
    required this.ageMinMonths,
    required this.prepTimeMin,
    required this.tags,
    required this.allergens,
    required this.ingredients,
    required this.steps,
    this.nutritionNote,
    this.imageAsset,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    List<String> list(String key) =>
        (json[key] as List? ?? const []).map((e) => e.toString()).toList();

    return Recipe(
      id: json['id'].toString(),
      title: json['title'].toString(),
      ageMinMonths: (json['ageMinMonths'] as num?)?.toInt() ?? 6,
      prepTimeMin: (json['prepTimeMin'] as num?)?.toInt() ?? 10,
      tags: list('tags'),
      allergens: list('allergens'),
      ingredients: list('ingredients'),
      steps: list('steps'),
      nutritionNote: json['nutritionNote']?.toString(),
      imageAsset: json['imageAsset']?.toString(),
    );
  }
}
