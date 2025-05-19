import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/presentation/providers/auth_provider.dart';
import '../../data/models/ingredient_model.dart';
import '../../data/repositories/ingredient_repository.dart';

// Provider pour le repository d'ingrédients
final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return IngredientRepository(dioClient);
});

// Provider pour la liste des ingrédients d'un événement
final eventIngredientsProvider = FutureProvider.family<List<IngredientModel>, int>((ref, eventId) async {
  final ingredientRepository = ref.watch(ingredientRepositoryProvider);
  return ingredientRepository.getIngredients(eventId);
});

// Provider pour un ingrédient spécifique
final ingredientProvider = FutureProvider.family<IngredientModel, ({int eventId, int ingredientId})>((ref, params) async {
  final ingredientRepository = ref.watch(ingredientRepositoryProvider);
  return ingredientRepository.getIngredient(params.eventId, params.ingredientId);
});

// États possibles pour la gestion des ingrédients
enum IngredientsState {
  initial,
  loading,
  loaded,
  error,
}

// État pour la gestion des ingrédients
class IngredientsStateNotifier extends StateNotifier<IngredientsState> {
  final IngredientRepository _ingredientRepository;
  final int _eventId;
  List<IngredientModel> _ingredients = [];
  String? _errorMessage;
  
  IngredientsStateNotifier(this._ingredientRepository, this._eventId) : super(IngredientsState.initial);
  
  List<IngredientModel> get ingredients => _ingredients;
  String? get errorMessage => _errorMessage;
  
  Future<void> loadIngredients() async {
    try {
      state = IngredientsState.loading;
      _ingredients = await _ingredientRepository.getIngredients(_eventId);
      state = IngredientsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = IngredientsState.error;
    }
  }
  
  Future<void> createIngredient({
    required String name,
    required double quantity,
    required String unit,
    double? estimatedPrice,
    String? notes,
  }) async {
    try {
      state = IngredientsState.loading;
      final ingredient = await _ingredientRepository.createIngredient(
        eventId: _eventId,
        name: name,
        quantity: quantity,
        unit: unit,
        estimatedPrice: estimatedPrice,
        notes: notes,
      );
      _ingredients = [ingredient, ..._ingredients];
      state = IngredientsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = IngredientsState.error;
    }
  }
  
  Future<void> updateIngredient({
    required int ingredientId,
    String? name,
    double? quantity,
    String? unit,
    double? estimatedPrice,
    double? actualPrice,
    String? status,
    String? notes,
  }) async {
    try {
      state = IngredientsState.loading;
      final updatedIngredient = await _ingredientRepository.updateIngredient(
        eventId: _eventId,
        ingredientId: ingredientId,
        name: name,
        quantity: quantity,
        unit: unit,
        estimatedPrice: estimatedPrice,
        actualPrice: actualPrice,
        status: status,
        notes: notes,
      );
      _ingredients = _ingredients.map((ingredient) {
        if (ingredient.id == ingredientId) {
          return updatedIngredient;
        }
        return ingredient;
      }).toList();
      state = IngredientsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = IngredientsState.error;
    }
  }
  
  Future<void> deleteIngredient(int ingredientId) async {
    try {
      state = IngredientsState.loading;
      await _ingredientRepository.deleteIngredient(_eventId, ingredientId);
      _ingredients = _ingredients.where((ingredient) => ingredient.id != ingredientId).toList();
      state = IngredientsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = IngredientsState.error;
    }
  }
  
  Future<void> assignIngredient({
    required int ingredientId,
    required int userId,
    required double quantity,
  }) async {
    try {
      state = IngredientsState.loading;
      await _ingredientRepository.assignIngredient(
        eventId: _eventId,
        ingredientId: ingredientId,
        userId: userId,
        quantity: quantity,
      );
      
      // Recharger les ingrédients pour obtenir les assignations mises à jour
      _ingredients = await _ingredientRepository.getIngredients(_eventId);
      state = IngredientsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = IngredientsState.error;
    }
  }
  
  Future<void> updateAssignment({
    required int ingredientId,
    required int assignmentId,
    required String status,
    double? pricePaid,
    String? storeName,
    String? receiptImage,
  }) async {
    try {
      state = IngredientsState.loading;
      await _ingredientRepository.updateAssignment(
        eventId: _eventId,
        ingredientId: ingredientId,
        assignmentId: assignmentId,
        status: status,
        pricePaid: pricePaid,
        storeName: storeName,
        receiptImage: receiptImage,
      );
      
      // Recharger les ingrédients pour obtenir les assignations mises à jour
      _ingredients = await _ingredientRepository.getIngredients(_eventId);
      state = IngredientsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      state = IngredientsState.error;
    }
  }
}

// Provider pour l'état des ingrédients d'un événement
final ingredientsStateProvider = StateNotifierProvider.family<IngredientsStateNotifier, IngredientsState, int>((ref, eventId) {
  final ingredientRepository = ref.watch(ingredientRepositoryProvider);
  return IngredientsStateNotifier(ingredientRepository, eventId);
});

// Provider pour les assignations d'un ingrédient spécifique
final ingredientAssignmentsProvider = Provider.family<List<IngredientAssignmentModel>?, ({int eventId, int ingredientId})>((ref, params) {
  final ingredientsAsync = ref.watch(eventIngredientsProvider(params.eventId));
  
  return ingredientsAsync.when(
    data: (ingredients) {
      final ingredient = ingredients.firstWhere(
        (i) => i.id == params.ingredientId,
        orElse: () => throw Exception('Ingrédient non trouvé'),
      );
      return ingredient.assignments;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Constantes pour les unités d'ingrédients
final ingredientUnitsProvider = Provider<Map<String, String>>((ref) {
  return {
    'g': 'Grammes',
    'kg': 'Kilogrammes',
    'ml': 'Millilitres',
    'l': 'Litres',
    'unit': 'Unité(s)',
    'tbsp': 'Cuillère(s) à soupe',
    'tsp': 'Cuillère(s) à café',
    'cup': 'Tasse(s)',
    'pinch': 'Pincée(s)',
    'piece': 'Pièce(s)',
    'slice': 'Tranche(s)',
    'bunch': 'Botte(s)',
    'can': 'Boîte(s)',
    'bottle': 'Bouteille(s)',
    'package': 'Paquet(s)',
  };
});

// Constantes pour les statuts d'ingrédients
final ingredientStatusesProvider = Provider<Map<String, String>>((ref) {
  return {
    'needed': 'Nécessaire',
    'assigned': 'Assigné',
    'purchased': 'Acheté',
  };
});

// Constantes pour les statuts d'assignation
final assignmentStatusesProvider = Provider<Map<String, String>>((ref) {
  return {
    'pending': 'En attente',
    'purchased': 'Acheté',
  };
});