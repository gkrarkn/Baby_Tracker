import 'package:flutter/material.dart';

import '../recipe.dart';
import '../recipe_repository.dart';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerRow(context),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recipes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, i) {
                  final r = recipes[i];
                  final unlocked = isPremium || i < freeUnlockedCount;

                  return _RecipeCard(
                    recipe: r,
                    locked: !unlocked,
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
                },
              ),

              if (!isPremium) ...[
                const SizedBox(height: 12),
                _premiumCta(context),
              ],
            ],
          ),
        );
      },
    );
  }

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

  Widget _headerRow(BuildContext context) {
    return Row(
      children: [
        Text(
          'Tarifler',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          '$babyMonths. ay için',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool locked;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.locked,
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
              Row(
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
                  if (locked) const Icon(Icons.lock, size: 18),
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
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
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
