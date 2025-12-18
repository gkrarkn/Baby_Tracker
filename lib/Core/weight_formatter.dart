class WeightFormatter {
  /// 750  -> "750 g"
  /// 3250 -> "3,25 kg"
  static String format(int grams) {
    if (grams < 1000) {
      return '$grams g';
    }

    final kg = grams / 1000.0;
    final str = kg.toStringAsFixed(2).replaceAll('.', ',');
    return '$str kg';
  }
}
