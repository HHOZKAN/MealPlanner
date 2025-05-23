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
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients());
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsState = ref.watch(ingredientsStateProvider(widget.eventId));
    final ingredients = ref.watch(ingredientsStateProvider(widget.eventId).notifier).ingredients;
    
    return ingredientsState == IngredientsState.loading
        ? const LoadingIndicator()
        : ingredientsState == IngredientsState.error
            ? ErrorMessage(
                message: 'Erreur lors du chargement des ingrédients',
                onRetry: () => ref.refresh(ingredientsStateProvider(widget.eventId)),
              )
            : _buildIngredientsList(ingredients);
  }

  Widget _buildIngredientsList(List<IngredientModel> ingredients) {
    if (ingredients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun ingrédient',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Calculate totals
    final myExpenses = ingredients
        .where((i) => i.assignments?.any((a) => 
            a.userId == ref.read(currentUserProvider)?.id && 
            a.status == 'purchased') ?? false)
        .fold(0.0, (sum, i) => sum + (i.actualPrice ?? 0));

    final totalExpenses = ingredients
        .where((i) => i.status == 'purchased')
        .fold(0.0, (sum, i) => sum + (i.actualPrice ?? 0));

    return Column(
      children: [
        // Expenses Summary
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes dépenses',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(myExpenses)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dépenses totales',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(totalExpenses)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Ingredients List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ingredients.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];
              final assignment = ingredient.assignments?.firstWhere(
                (a) => a.userId == ref.read(currentUserProvider)?.id,
                orElse: () => IngredientAssignmentModel(
                  id: -1,
                  ingredientId: ingredient.id,
                  userId: -1,
                  quantity: 0,
                  status: '',
                ),
              );

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.euro, color: Colors.grey),
                ),
                title: Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
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
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                trailing: Text(
                  ingredient.actualPrice != null
                      ? NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(ingredient.actualPrice)
                      : '-',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ingredient.actualPrice != null ? Colors.black : Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
