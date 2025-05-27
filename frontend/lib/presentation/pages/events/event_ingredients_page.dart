import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/ingredient_model.dart';
import '../../../presentation/providers/ingredient_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';

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
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (!mounted) return;
      print('Loading ingredients for event ${widget.eventId}');
      try {
        await ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients();
        if (!mounted) return;
        print('Ingredients loaded successfully');
      } catch (e) {
        if (!mounted) return;
        print('Error loading ingredients: $e');
      }
    });
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building EventIngredientsPage');
    final notifier = ref.watch(ingredientsStateProvider(widget.eventId).notifier);
    final ingredientsState = ref.watch(ingredientsStateProvider(widget.eventId));
    
    final List<IngredientModel> ingredients = ingredientsState == IngredientsState.loaded 
        ? notifier.ingredients 
        : <IngredientModel>[];
    
    print('Current state: $ingredientsState');
    print('Ingredients count: ${ingredients.length}');
    
    return ingredientsState == IngredientsState.loading
        ? const LoadingIndicator()
        : ingredientsState == IngredientsState.error
            ? ErrorMessage(
                message: ref.read(ingredientsStateProvider(widget.eventId).notifier).errorMessage ?? 
                         'Erreur lors du chargement des ingrédients',
                onRetry: () => ref.refresh(ingredientsStateProvider(widget.eventId)),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients();
                },
                child: _buildIngredientsList(ingredients),
              );
  }

  Widget _buildIngredientsList(List<IngredientModel> ingredients) {
    if (ingredients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 36, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Aucun ingrédient',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = ingredients[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        ingredient.emoji ?? '💶',
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            Text(
                              ingredient.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Payé par ${ingredient.assignments?.firstWhere(
                                (a) => a.status == 'purchased',
                                orElse: () => IngredientAssignmentModel(
                                  id: -1,
                                  ingredientId: ingredient.id,
                                  userId: -1,
                                  quantity: 0,
                                  status: '',
                                ),
                              ).user?.name ?? 'Non assigné'}',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                              ),
                            ),
                      ],
                    ),
                  ),
                  Text(
                    ingredient.actualPrice != null
                        ? NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(ingredient.actualPrice)
                        : '-',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ingredient.actualPrice != null ? Colors.black : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
