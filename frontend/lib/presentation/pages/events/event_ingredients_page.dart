// lib/presentation/pages/events/event_ingredients_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/ingredient_model.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/ingredient_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';
import 'add_ingredient_page.dart';
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
  void initState() {
    super.initState();
    // Charger les ingrédients au chargement de la page
    Future.microtask(() => ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final ingredientsState = ref.watch(ingredientsStateProvider(widget.eventId));
    final ingredients = ref.watch(ingredientsStateProvider(widget.eventId).notifier).ingredients;
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingrédients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients(),
          ),
        ],
      ),
      body: eventAsync.when(
        data: (event) {
          final isOrganizer = currentUser != null && event.organizerId == currentUser.id;
          
          return Column(
            children: [
              // En-tête avec le titre de l'événement
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.primaryContainer,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(event.date),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isOrganizer)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddIngredientPage(eventId: widget.eventId),
                            ),
                          ).then((_) {
                            // Rafraîchir les ingrédients après l'ajout
                            ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Liste des ingrédients
              Expanded(
                child: _buildIngredientsList(
                  context,
                  ingredientsState,
                  ingredients,
                  isOrganizer,
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorMessage(
          message: 'Erreur lors du chargement de l\'événement: $error',
          onRetry: () => ref.refresh(eventProvider(widget.eventId)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddIngredientPage(eventId: widget.eventId),
            ),
          ).then((_) {
            // Rafraîchir les ingrédients après l'ajout
            ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildIngredientsList(
    BuildContext context,
    IngredientsState state,
    List<IngredientModel> ingredients,
    bool isOrganizer,
  ) {
    final theme = Theme.of(context);
    final units = ref.watch(ingredientUnitsProvider);
    
    switch (state) {
      case IngredientsState.initial:
      case IngredientsState.loading:
        return const LoadingIndicator(message: 'Chargement des ingrédients...');
      
      case IngredientsState.error:
        return ErrorMessage(
          message: 'Erreur lors du chargement des ingrédients: ${ref.read(ingredientsStateProvider(widget.eventId).notifier).errorMessage}',
          onRetry: () => ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients(),
        );
      
      case IngredientsState.loaded:
        if (ingredients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aucun ingrédient',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajoutez des ingrédients pour votre événement',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddIngredientPage(eventId: widget.eventId),
                      ),
                    ).then((_) {
                      // Rafraîchir les ingrédients après l'ajout
                      ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un ingrédient'),
                ),
              ],
            ),
          );
        }
        
        // Trier les ingrédients par statut
        final neededIngredients = ingredients.where((i) => i.status == 'needed').toList();
        final assignedIngredients = ingredients.where((i) => i.status == 'assigned').toList();
        final purchasedIngredients = ingredients.where((i) => i.status == 'purchased').toList();
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ingrédients nécessaires
            if (neededIngredients.isNotEmpty) ...[
              _buildSectionHeader(context, 'Ingrédients nécessaires', Icons.shopping_cart_outlined, Colors.orange),
              ...neededIngredients.map((ingredient) => _buildIngredientCard(context, ingredient, units, isOrganizer)),
              const SizedBox(height: 16),
            ],
            
            // Ingrédients assignés
            if (assignedIngredients.isNotEmpty) ...[
              _buildSectionHeader(context, 'Ingrédients assignés', Icons.assignment_ind, Colors.blue),
              ...assignedIngredients.map((ingredient) => _buildIngredientCard(context, ingredient, units, isOrganizer)),
              const SizedBox(height: 16),
            ],
            
            // Ingrédients achetés
            if (purchasedIngredients.isNotEmpty) ...[
              _buildSectionHeader(context, 'Ingrédients achetés', Icons.check_circle, Colors.green),
              ...purchasedIngredients.map((ingredient) => _buildIngredientCard(context, ingredient, units, isOrganizer)),
            ],
          ],
        );
    }
  }
  
  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIngredientCard(
    BuildContext context,
    IngredientModel ingredient,
    Map<String, String> units,
    bool isOrganizer,
  ) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(currentUserProvider);
    
    // Déterminer la couleur en fonction du statut
    Color statusColor;
    IconData statusIcon;
    
    switch (ingredient.status) {
      case 'needed':
        statusColor = Colors.orange;
        statusIcon = Icons.shopping_cart_outlined;
        break;
      case 'assigned':
        statusColor = Colors.blue;
        statusIcon = Icons.assignment_ind;
        break;
      case 'purchased':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }
    
    // Vérifier si l'ingrédient est assigné à l'utilisateur courant
    bool isAssignedToCurrentUser = false;
    IngredientAssignmentModel? currentUserAssignment;
    
    if (currentUser != null && ingredient.assignments != null) {
      currentUserAssignment = ingredient.assignments!.firstWhere(
        (a) => a.userId == currentUser.id,
        orElse: () => IngredientAssignmentModel(
          id: -1,
          ingredientId: ingredient.id,
          userId: -1,
          quantity: 0,
          status: '',
        ),
      );
      
      isAssignedToCurrentUser = currentUserAssignment.id != -1;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IngredientDetailPage(
                eventId: widget.eventId,
                ingredientId: ingredient.id,
              ),
            ),
          ).then((_) {
            // Rafraîchir les ingrédients après modification
            ref.read(ingredientsStateProvider(widget.eventId).notifier).loadIngredients();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOrganizer)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteIngredientDialog(ingredient),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Quantité et unité
              Row(
                children: [
                  const Icon(Icons.scale, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${ingredient.quantity} ${units[ingredient.unit] ?? ingredient.unit}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Prix estimé
              if (ingredient.estimatedPrice != null)
                Row(
                  children: [
                    const Icon(Icons.euro, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Prix estimé: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(ingredient.estimatedPrice)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              
              // Prix réel (si acheté)
              if (ingredient.actualPrice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_bag, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Prix payé: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(ingredient.actualPrice)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Assignations
              if (ingredient.assignments != null && ingredient.assignments!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                
                Text(
                  'Assigné à:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                
                ...ingredient.assignments!.map((assignment) {
                  final isCurrentUser = currentUser != null && assignment.userId == currentUser.id;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: isCurrentUser ? theme.colorScheme.primary : Colors.grey,
                          child: assignment.user?.avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    assignment.user!.avatarUrl!,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 12),
                                  ),
                                )
                              : const Icon(Icons.person, color: Colors.white, size: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          assignment.user?.name ?? 'Utilisateur inconnu',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isCurrentUser ? FontWeight.bold : null,
                            color: isCurrentUser ? theme.colorScheme.primary : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${assignment.quantity} ${units[ingredient.unit] ?? ingredient.unit})',
                          style: theme.textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: assignment.status == 'purchased' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            assignment.status == 'purchased' ? 'Acheté' : 'En attente',
                            style: TextStyle(
                              color: assignment.status == 'purchased' ? Colors.green : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              
              // Actions
              if (ingredient.status == 'needed' && currentUser != null) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAssignDialog(ingredient),
                    icon: const Icon(Icons.assignment_ind),
                    label: const Text('Je m\'en occupe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
              
              // Action pour marquer comme acheté
              if (isAssignedToCurrentUser && currentUserAssignment!.status == 'pending') ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showMarkAsPurchasedDialog(ingredient, currentUserAssignment!),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Marquer comme acheté'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _showDeleteIngredientDialog(IngredientModel ingredient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'ingrédient'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${ingredient.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await ref.read(ingredientsStateProvider(widget.eventId).notifier).deleteIngredient(ingredient.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrédient supprimé avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _showAssignDialog(IngredientModel ingredient) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;
    
    double quantity = ingredient.quantity;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Je m\'occupe de cet ingrédient'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingrédient: ${ingredient.name}'),
                  const SizedBox(height: 16),
                  Text('Quantité disponible: ${ingredient.quantity} ${ref.read(ingredientUnitsProvider)[ingredient.unit] ?? ingredient.unit}'),
                  const SizedBox(height: 16),
                  Text('Combien voulez-vous prendre en charge ?'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: quantity,
                          min: 0,
                          max: ingredient.quantity,
                          divisions: ingredient.quantity.toInt(),
                          label: quantity.toString(),
                          onChanged: (value) {
                            setState(() {
                              quantity = value;
                            });
                          },
                        ),
                      ),
                      Text('$quantity ${ref.read(ingredientUnitsProvider)[ingredient.unit] ?? ingredient.unit}'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: quantity > 0 ? () => Navigator.pop(context, true) : null,
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (confirmed == true) {
      try {
        await ref.read(ingredientsStateProvider(widget.eventId).notifier).assignIngredient(
          ingredientId: ingredient.id,
          userId: currentUser.id,
          quantity: quantity,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrédient assigné avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _showMarkAsPurchasedDialog(IngredientModel ingredient, IngredientAssignmentModel assignment) async {
    final pricePaidController = TextEditingController();
    final storeNameController = TextEditingController();
    File? receiptImage;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Marquer comme acheté'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ingrédient: ${ingredient.name}'),
                    Text('Quantité: ${assignment.quantity} ${ref.read(ingredientUnitsProvider)[ingredient.unit] ?? ingredient.unit}'),
                    const SizedBox(height: 16),
                    
                    // Prix payé
                    TextFormField(
                      controller: pricePaidController,
                      decoration: const InputDecoration(
                        labelText: 'Prix payé',
                        hintText: 'Ex: 2.50',
                        prefixIcon: Icon(Icons.euro),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    
                    // Nom du magasin
                    TextFormField(
                      controller: storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Magasin (optionnel)',
                        hintText: 'Ex: Carrefour',
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Photo du ticket
                    const Text('Photo du ticket (optionnel)'),
                    const SizedBox(height: 8),
                    
                    if (receiptImage != null)
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              receiptImage!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                receiptImage = null;
                              });
                            },
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.camera);
                          
                          if (pickedFile != null) {
                            setState(() {
                              receiptImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Prendre une photo du ticket'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        );
      },
    );
    
    if (confirmed == true) {
      try {
        final pricePaid = pricePaidController.text.isNotEmpty 
            ? double.parse(pricePaidController.text) 
            : null;
        
        // Ici, vous devriez implémenter le code pour convertir l'image en base64
        // et l'envoyer au serveur
        String? receiptImageBase64;
        if (receiptImage != null) {
          // Conversion de l'image en base64
          // receiptImageBase64 = base64Encode(receiptImage!.readAsBytesSync());
          // Pour l'exemple, nous allons simplement utiliser le chemin de l'image
          receiptImageBase64 = receiptImage!.path;
        }
        
        await ref.read(ingredientsStateProvider(widget.eventId).notifier).updateAssignment(
          ingredientId: ingredient.id,
          assignmentId: assignment.id,
          status: 'purchased',
          pricePaid: pricePaid,
          storeName: storeNameController.text.trim(),
          receiptImage: receiptImageBase64,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrédient marqué comme acheté')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}