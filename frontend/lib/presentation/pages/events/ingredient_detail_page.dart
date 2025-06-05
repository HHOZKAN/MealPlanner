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

  // Add this field to track selected participants
  final Set<int> _selectedParticipants = {};

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
    
    // Initialize selected participants from existing assignments
    _selectedParticipants.clear();
    if (ingredient.assignments != null) {
      for (var assignment in ingredient.assignments!) {
        if (assignment.status != 'purchased') {
          _selectedParticipants.add(assignment.userId);
        }
      }
    }
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
        
       
        String? receiptImageBase64;
        if (receiptImage != null) {
 
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
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ingredientAsync.when(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Text(
                  ingredient.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 24),
                
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
                
                // Quantité et unité
                Text(
                  'Détails de l\'ingrédient',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Quantité
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _quantityController,
                          style: const TextStyle(color: Color(0xFF2D3142)),
                          decoration: InputDecoration(
                            labelText: 'Quantité',
                            labelStyle: const TextStyle(color: Color(0xFF2D3142)),
                            prefixIcon: const Icon(Icons.scale, color: Color(0xFFFF5722)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFFFF5722)),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Unité
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: InputDecoration(
                            labelText: 'Unité',
                            labelStyle: const TextStyle(color: Color(0xFF2D3142)),
                            prefixIcon: const Icon(Icons.straighten, color: Color(0xFFFF5722)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Color(0xFFFF5722)),
                            ),
                          ),
                          items: units.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(
                                entry.value,
                                style: const TextStyle(color: Color(0xFF2D3142)),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedUnit = value;
                              });
                            }
                          },
                          dropdownColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Qui achète
                Text(
                  'Qui achète ?',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final participantsAsync = ref.watch(eventParticipantsProvider(widget.eventId));
                      final eventAsync = ref.watch(eventProvider(widget.eventId));
                      
                      return participantsAsync.when(
                        data: (participants) {
                          // Créer une liste combinée avec l'organisateur et les participants
                          final List<Map<String, dynamic>> allUsers = [];
                          
                          // Ajouter l'organisateur
                          eventAsync.whenData((event) {
                            if (event.organizer != null) {
                              allUsers.add({
                                'id': event.organizer!.id,
                                'name': event.organizer!.name,
                                'isOrganizer': true,
                              });
                            }
                          });
                          
                          // Ajouter les participants (en évitant les doublons avec l'organisateur)
                          for (final participant in participants) {
                            if (participant.user != null && !allUsers.any((u) => u['id'] == participant.user!.id)) {
                              allUsers.add({
                                'id': participant.user!.id,
                                'name': participant.user!.name,
                                'isOrganizer': false,
                              });
                            }
                          }
                          
                          if (allUsers.isEmpty) {
                            return const Text(
                              'Aucun participant disponible',
                              style: TextStyle(color: Color(0xFF2D3142)),
                            );
                          }
                          
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allUsers.map((user) {
                              final isSelected = _selectedParticipants.contains(user['id']);
                              return FilterChip(
                                label: Text(user['name']),
                                selected: isSelected,
                                backgroundColor: Colors.white,
                                selectedColor: const Color(0xFFFF5722).withOpacity(0.1),
                                labelStyle: TextStyle(
                                  color: isSelected ? const Color(0xFFFF5722) : const Color(0xFF2D3142),
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFFFF5722) : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                onSelected: (selected) async {
                                  if (selected) {
                                    setState(() {
                                      _selectedParticipants.add(user['id']);
                                    });
                                    try {
                                      final notifier = ref.read(ingredientsStateProvider(widget.eventId).notifier);
                                      await notifier.assignIngredient(
                                        ingredientId: widget.ingredientId,
                                        userId: user['id'],
                                        quantity: double.parse(_quantityController.text),
                                      );
                                      ref.refresh(ingredientProvider((eventId: widget.eventId, ingredientId: widget.ingredientId)));
                                    } catch (e) {
                                      setState(() {
                                        _selectedParticipants.remove(user['id']);
                                        _errorMessage = e.toString();
                                      });
                                    }
                                  } else {
                                    final existingAssignments = ingredient.assignments ?? [];
                                    final assignment = existingAssignments.firstWhere(
                                      (a) => a.userId == user['id'] && a.status != 'purchased',
                                      orElse: () => throw Exception('Assignment not found'),
                                    );
                                    
                                    try {
                                      setState(() {
                                        _selectedParticipants.remove(user['id']);
                                      });
                                      final notifier = ref.read(ingredientsStateProvider(widget.eventId).notifier);
                                      await notifier.removeAssignment(
                                        ingredientId: widget.ingredientId,
                                        assignmentId: assignment.id,
                                      );
                                      ref.refresh(ingredientProvider((eventId: widget.eventId, ingredientId: widget.ingredientId)));
                                    } catch (e) {
                                      setState(() {
                                        _selectedParticipants.add(user['id']);
                                        _errorMessage = e.toString();
                                      });
                                    }
                                  }
                                },
                              );
                            }).toList(),
                          );
                        },
                      loading: () => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5722)),
                          ),
                        ),
                      ),
                      error: (error, stack) => Text(
                        'Erreur: $error',
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              // Bouton Assigner
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    try {
                      final quantity = double.tryParse(_quantityController.text) ?? 0;
                      if (quantity <= 0) {
                        setState(() {
                          _errorMessage = 'Quantité invalide';
                          _isLoading = false;
                        });
                        return;
                      }

                      final notifier = ref.read(ingredientsStateProvider(widget.eventId).notifier);
                      final existingAssignments = ingredient.assignments ?? [];

                      // Supprimer les assignations des participants non sélectionnés
                      for (final assignment in existingAssignments) {
                        if (!_selectedParticipants.contains(assignment.userId) && assignment.status != 'purchased') {
                          await notifier.removeAssignment(
                            ingredientId: widget.ingredientId,
                            assignmentId: assignment.id,
                          );
                        }
                      }

                      // Ajouter ou mettre à jour les assignations pour les participants sélectionnés
                      for (final userId in _selectedParticipants) {
                        final existingAssignment = existingAssignments
                            .where((a) => a.userId == userId && a.status != 'purchased')
                            .firstOrNull;
                            
                        if (existingAssignment == null) {
                          // Créer une nouvelle assignation si aucune n'existe
                          await notifier.assignIngredient(
                            ingredientId: widget.ingredientId,
                            userId: userId,
                            quantity: quantity,
                          );
                        }
                      }

                      ref.refresh(ingredientProvider((eventId: widget.eventId, ingredientId: widget.ingredientId)));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ingrédient assigné avec succès')),
                        );
                        Navigator.of(context).pop();
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
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Assigner'),
                ),
              ),
            ],
          )
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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