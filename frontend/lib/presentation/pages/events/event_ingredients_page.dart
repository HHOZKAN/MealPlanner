import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../presentation/providers/ingredient_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import 'ingredient_detail_page.dart';

class EventIngredientsPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventIngredientsPage({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  ConsumerState<EventIngredientsPage> createState() => _EventIngredientsPageState();
}

class _EventIngredientsPageState extends ConsumerState<EventIngredientsPage> {
  @override
  Widget build(BuildContext context) {
    final ingredientsState = ref.watch(ingredientsStateProvider(widget.eventId));
    final notifier = ref.watch(ingredientsStateProvider(widget.eventId).notifier);
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Builder(
        builder: (context) {
          switch (ingredientsState) {
            case IngredientsState.loading:
              return const Center(child: CircularProgressIndicator());
            
            case IngredientsState.loaded:
              final ingredients = notifier.ingredients;
              if (ingredients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_basket_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun ingrédient',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajoutez des ingrédients en utilisant le bouton +',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
                itemCount: ingredients.length,
                itemBuilder: (context, index) {
                  final ingredient = ingredients[index];
                  final isMyAssignment = ingredient.assignments?.any((a) => 
                    a.userId == currentUser?.id && a.status == 'assigned') ?? false;
                  final isPurchased = ingredient.status == 'purchased';
                  
                  // Style inspiré du dashboard EventCard
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white, // Fond blanc explicite pour la carte
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Fond blanc pour le container
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isMyAssignment 
                                ? const Color(0xFFFF5722).withOpacity(0.3)
                                : Colors.transparent,
                            width: isMyAssignment ? 1.5 : 0,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: const Color(0xFFF9F5F0), // Ajout du fond harmonisé
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (context) {
                                return FractionallySizedBox(
                                  heightFactor: 0.9,
                                  child: IngredientDetailPage(
                                    eventId: widget.eventId,
                                    ingredientId: ingredient.id,
                                  ),
                                );
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icône à gauche
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isPurchased 
                                        ? Colors.green.withOpacity(0.1)
                                        : const Color(0xFFFF5722).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isPurchased ? Icons.check_circle : Icons.shopping_cart_outlined,
                                      color: isPurchased ? Colors.green : const Color(0xFFFF5722),
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Texte et détails
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ingredient.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D3142), // Changé en couleur foncée pour être visible sur fond blanc
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ingredient.quantity != null
                                            ? '${ingredient.quantity} ${ingredient.unit ?? ''}'
                                            : 'Quantité non spécifiée',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (isMyAssignment && !isPurchased)
                                        Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8, 
                                            vertical: 2
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF5722).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'À acheter',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFFF5722),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Prix à droite
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      ingredient.actualPrice != null
                                          ? NumberFormat.currency(
                                              locale: 'fr_FR', 
                                              symbol: '€'
                                            ).format(ingredient.actualPrice)
                                          : ingredient.estimatedPrice != null
                                              ? '~${NumberFormat.currency(
                                                  locale: 'fr_FR', 
                                                  symbol: '€'
                                                ).format(ingredient.estimatedPrice)}'
                                              : '—',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isPurchased 
                                            ? Colors.green 
                                            : const Color(0xFF2D3142),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (ingredient.assignments != null && ingredient.assignments!.isNotEmpty)
                                      Text(
                                        'Qui achète : ${ingredient.assignments!.map((a) => a.user?.name ?? 'Inconnu').join(', ')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            
            case IngredientsState.error:
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur: ${notifier.errorMessage}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => notifier.loadIngredients(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            
            default:
              return const Center(child: Text('État inconnu'));
          }
        },
      ),
    );
  }
}