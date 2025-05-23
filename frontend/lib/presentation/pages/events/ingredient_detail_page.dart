import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/ingredient_model.dart';
import '../../../presentation/providers/ingredient_provider.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';

class IngredientDetailPage extends ConsumerStatefulWidget {
  final int eventId;
  final int ingredientId;
  
  const IngredientDetailPage({
    Key? key,
    required this.eventId,
    required this.ingredientId,
  }) : super(key: key);

  @override
  ConsumerState<IngredientDetailPage> createState() => _IngredientDetailPageState();
}

class _IngredientDetailPageState extends ConsumerState<IngredientDetailPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _notesController;
  
  String? _selectedUnit;
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _quantityController = TextEditingController();
    _priceController = TextEditingController();
    _notesController = TextEditingController();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _initControllers(IngredientModel ingredient) {
    _nameController.text = ingredient.name;
    _quantityController.text = ingredient.quantity.toString();
    _priceController.text = ingredient.estimatedPrice?.toString() ?? '';
    _notesController.text = ingredient.notes ?? '';
    _selectedUnit = ingredient.unit;
  }
  
  Future<void> _updateIngredient(IngredientModel ingredient) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        final quantity = double.parse(_quantityController.text);
        final price = _priceController.text.isNotEmpty 
            ? double.parse(_priceController.text) 
            : null;
        
        await ref.read(ingredientsStateProvider(widget.eventId).notifier).updateIngredient(
          ingredientId: ingredient.id,
          name: _nameController.text.trim(),
          quantity: quantity,
          unit: _selectedUnit,
          estimatedPrice: price,
          notes: _notesController.text.trim(),
        );
        
        // Rafraîchir les données
        ref.refresh(ingredientProvider((eventId: widget.eventId, ingredientId: widget.ingredientId)));
        
        if (mounted) {
          setState(() {
            _isEditing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrédient mis à jour avec succès')),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _assignIngredient(IngredientModel ingredient) async {
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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      try {
        await ref.read(ingredientsStateProvider(widget.eventId).notifier).assignIngredient(
          ingredientId: ingredient.id,
          userId: currentUser.id,
          quantity: quantity,
        );
        
        // Rafraîchir les données
        ref.refresh(ingredientProvider((eventId: widget.eventId, ingredientId: widget.ingredientId)));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrédient assigné avec succès')),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  Future<void> _markAsPurchased(IngredientModel ingredient, IngredientAssignmentModel assignment) async {
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
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
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
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
        
        // Rafraîchir les données
        ref.refresh(ingredientProvider((eventId: widget.eventId, ingredientId: widget.ingredientId)));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrédient marqué comme acheté')),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingredientAsync = ref.watch(ingredientProvider((eventId: widget.eventId, ingredientId: widget.ingredientId)));
    final currentUser = ref.watch(currentUserProvider);
    final units = ref.watch(ingredientUnitsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'ingrédient'),
        actions: [
          ingredientAsync.when(
            data: (ingredient) {
              final isOrganizer = currentUser != null && ingredient.addedBy == currentUser.id;
              
              return isOrganizer
                  ? IconButton(
                      icon: Icon(_isEditing ? Icons.check : Icons.edit),
                      onPressed: () {
                        if (_isEditing) {
                          _updateIngredient(ingredient);
                        } else {
                          setState(() {
                            _isEditing = true;
                            _initControllers(ingredient);
                          });
                        }
                      },
                    )
                  : const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ingredientAsync.when(
        data: (ingredient) {
          // Initialiser les contrôleurs si ce n'est pas déjà fait
          if (!_isEditing) {
            _initControllers(ingredient);
          }
          
          final currentUser = ref.read(currentUserProvider);
          
          IngredientAssignmentModel? currentUserAssignment;
          if (currentUser != null && ingredient.assignments != null) {
            try {
              currentUserAssignment = ingredient.assignments!.firstWhere(
                (a) => a.userId == currentUser.id,
              );
            } catch (e) {
              // L'utilisateur n'a pas d'assignation
              currentUserAssignment = null;
            }
          }
          
          final isAssignedToCurrentUser = currentUserAssignment != null;
          final isPendingAssignment = isAssignedToCurrentUser && currentUserAssignment.status == 'pending';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _isEditing
                ? _buildEditForm(ingredient, units, theme)
                : _buildDetailView(ingredient, units, theme, currentUserAssignment),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorMessage(
          message: 'Erreur lors du chargement de l\'ingrédient: $error',
          onRetry: () => ref.refresh(ingredientProvider((eventId: widget.eventId, ingredientId: widget.ingredientId))),
        ),
      ),
    );
  }
  
  Widget _buildEditForm(IngredientModel ingredient, Map<String, String> units, ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message d'erreur
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          
          // Nom de l'ingrédient
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom de l\'ingrédient',
              prefixIcon: Icon(Icons.shopping_cart),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Quantité et unité
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quantité
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantité',
                    prefixIcon: Icon(Icons.scale),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une quantité';
                    }
                    final quantity = double.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Quantité invalide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Unité
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unité',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  items: units.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUnit = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Prix estimé
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Prix estimé (optionnel)',
              prefixIcon: Icon(Icons.euro),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 16),
          
          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _isEditing = false;
                            _initControllers(ingredient);
                          });
                        },
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _updateIngredient(ingredient),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailView(
    IngredientModel ingredient,
    Map<String, String> units,
    ThemeData theme,
    IngredientAssignmentModel? currentUserAssignment,
  ) {
    final currentUser = ref.read(currentUserProvider);
    final isAssignedToCurrentUser = currentUserAssignment != null;
    final isPendingAssignment = isAssignedToCurrentUser && currentUserAssignment.status == 'pending';
    
    // Déterminer la couleur en fonction du statut
    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    
    switch (ingredient.status) {
      case 'needed':
        statusColor = Colors.orange;
        statusIcon = Icons.shopping_cart_outlined;
        statusLabel = 'Nécessaire';
        break;
      case 'assigned':
        statusColor = Colors.blue;
        statusIcon = Icons.assignment_ind;
        statusLabel = 'Assigné';
        break;
      case 'purchased':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = 'Acheté';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusLabel = ingredient.status;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message d'erreur
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        
        // En-tête avec le statut
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Nom de l'ingrédient
        Text(
          ingredient.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Informations principales
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantité et unité
                Row(
                  children: [
                    const Icon(Icons.scale, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      'Quantité: ${ingredient.quantity} ${units[ingredient.unit] ?? ingredient.unit}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Prix estimé
                if (ingredient.estimatedPrice != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.euro, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'Prix estimé: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(ingredient.estimatedPrice)}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Prix réel (si acheté)
                if (ingredient.actualPrice != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        'Prix payé: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(ingredient.actualPrice)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Ajouté par
                if (ingredient.addedByUser != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'Ajouté par: ${ingredient.addedByUser!.name}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Notes
                if (ingredient.notes != null && ingredient.notes!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notes: ${ingredient.notes}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Assignations
        if (ingredient.assignments != null && ingredient.assignments!.isNotEmpty) ...[
          Text(
            'Assignations',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ingredient.assignments!.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final assignment = ingredient.assignments![index];
                final isCurrentUser = currentUser != null && assignment.userId == currentUser.id;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentUser ? theme.colorScheme.primary : Colors.grey,
                    child: assignment.user?.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              assignment.user!.avatarUrl!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    assignment.user?.name ?? 'Utilisateur inconnu',
                    style: TextStyle(
                      fontWeight: isCurrentUser ? FontWeight.bold : null,
                      color: isCurrentUser ? theme.colorScheme.primary : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${assignment.quantity} ${units[ingredient.unit] ?? ingredient.unit}'),
                      if (assignment.pricePaid != null)
                        Text(
                          'Prix payé: ${NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(assignment.pricePaid)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      if (assignment.storeName != null && assignment.storeName!.isNotEmpty)
                        Text('Magasin: ${assignment.storeName}'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        // Actions
        if (ingredient.status == 'needed' && currentUser != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _assignIngredient(ingredient),
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
        if (isPendingAssignment) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _markAsPurchased(ingredient, currentUserAssignment),
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
    );
  }
}