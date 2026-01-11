import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../recipe.dart';
import '../recipe_repository.dart';
import '../recipe_favorites_service.dart';

class RecipesSection extends StatelessWidget {
  final int babyMonths;
  final bool isPremium;
  final int freeUnlockedCount;
  final VoidCallback onUpgradeTap;

  const RecipesSection({
    super.key,
    required this.babyMonths,
    required this.isPremium,
    required this.onUpgradeTap,
    this.freeUnlockedCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<RecipeFavoritesService>();

    return FutureBuilder<List<Recipe>>(
      future: const RecipeRepository().forAge(babyMonths),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final recipes = snap.data ?? const <Recipe>[];
        if (recipes.isEmpty) {
          return _sectionShell(
            context,
            child: const Text('Bu yaş aralığı için tarif bulunamadı.'),
          );
        }

        return _sectionShell(
          context,
          child: CustomScrollView(
            // RecipesSection çoğunlukla zaten scroll içinde (bottom sheet scroll).
            // O yüzden burada kendi scroll’ını kapatıyoruz:
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _headerRow(context, favorites)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverGrid(
                delegate: SliverChildBuilderDelegate((context, i) {
                  final r = recipes[i];
                  final unlocked = isPremium || i < freeUnlockedCount;

                  return _RecipeCard(
                    recipe: r,
                    locked: !unlocked,
                    isFavorite: favorites.isFavorite(r.id),
                    onFavoriteTap: () => favorites.toggle(r.id),
                    onTap: () {
                      if (!unlocked) {
                        onUpgradeTap();
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailPage(recipe: r),
                        ),
                      );
                    },
                  );
                }, childCount: recipes.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  // Daha güvenli: chip’ler artınca patlamasın diye biraz daha uzun kart
                  childAspectRatio: 0.82,
                ),
              ),

              if (!isPremium) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(child: _premiumCta(context)),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------- HEADER ----------------

  Widget _headerRow(BuildContext context, RecipeFavoritesService favorites) {
    return Row(
      children: [
        Text(
          'Tarifler',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),

        if (favorites.hasFavorites)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openFavoritesSheet(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 18, color: Colors.amber),
                  SizedBox(width: 6),
                  Text(
                    'Favorilerim',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(width: 10),
        Text(
          '$babyMonths. ay',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------- FAVORITES SHEET ----------------

  void _openFavoritesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => _FavoriteRecipesSheet(babyMonths: babyMonths),
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget _sectionShell(BuildContext context, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }

  Widget _premiumCta(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Daha fazla tarif için Premium’a geç.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: onUpgradeTap, child: const Text('Premium')),
        ],
      ),
    );
  }
}

// ================= RECIPE CARD =================

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool locked;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.locked,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  // Favori: IconButton tıklanınca kart tap’ini bozmadan çalışır
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : Colors.grey,
                      size: 20,
                    ),
                    onPressed: onFavoriteTap,
                  ),

                  if (locked) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.lock, size: 18),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              Text(
                '⏱ ~${recipe.prepTimeMin} dk • ${recipe.ageMinMonths}+ ay',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 10),

              // Alt kısım: chip’ler uzasa bile overflow yapmasın
              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: recipe.tags.take(2).map((t) {
                      return Chip(
                        label: Text(
                          t,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= FAVORITES BOTTOM SHEET =================

class _FavoriteRecipesSheet extends StatelessWidget {
  final int babyMonths;
  const _FavoriteRecipesSheet({required this.babyMonths});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<RecipeFavoritesService>();

    // Daha iyi UX: sheet küçük kalmasın, tam ekrana yakın açılsın.
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text(
                      'Favori Tariflerim',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kapat'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: FutureBuilder<List<Recipe>>(
                    future: const RecipeRepository().forAge(babyMonths),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final all = snap.data ?? const <Recipe>[];
                      final favIds = favorites.favorites;

                      // Favoriler sadece bu age list’inden değil; genel de tutuyor olabilir.
                      // Bu sheet “mevcut ay tarifleri içindeki favoriler” mantığıyla filtreli.
                      final favRecipes = all
                          .where((r) => favIds.contains(r.id))
                          .toList();

                      if (favRecipes.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz favori tarif eklemediniz.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      // Burada da overflow yaşamamak için sliver grid kullanıyoruz.
                      return CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverGrid(
                            delegate: SliverChildBuilderDelegate((context, i) {
                              final r = favRecipes[i];
                              return _RecipeCard(
                                recipe: r,
                                locked: false,
                                isFavorite: true,
                                onFavoriteTap: () => favorites.toggle(r.id),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RecipeDetailPage(recipe: r),
                                    ),
                                  );
                                },
                              );
                            }, childCount: favRecipes.length),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.82,
                                ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================= DETAIL PAGE =================

class RecipeDetailPage extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Uygun yaş: ${recipe.ageMinMonths}+ ay • Süre: ~${recipe.prepTimeMin} dk',
          ),
          const SizedBox(height: 16),
          Text('Malzemeler', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final x in recipe.ingredients)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $x'),
            ),
          const SizedBox(height: 16),
          Text('Hazırlanış', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (int i = 0; i < recipe.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${i + 1}. ${recipe.steps[i]}'),
            ),
          if (recipe.nutritionNote != null) ...[
            const SizedBox(height: 16),
            Text('Not', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(recipe.nutritionNote!),
          ],
        ],
      ),
    );
  }
}
