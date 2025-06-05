import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/ingredient_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/event_participants_provider.dart' as participants_provider;
import '../providers/expense_provider_new.dart';
import '../providers/event_provider.dart' as event_provider;
import '../../data/models/event_model.dart';
import '../../data/models/user_model.dart';

class AddExpenseModal extends ConsumerStatefulWidget {
  final int eventId;

  const AddExpenseModal({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  ConsumerState<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends ConsumerState<AddExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  int? _selectedIngredientId;
  int? _selectedPayerId;
  Map<int, TextEditingController> _shareControllers = {};
  Set<int> _selectedParticipants = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _shareControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _updateShares(double totalAmount) {
    if (_shareControllers.isEmpty) return;
    
    final equalShare = (totalAmount / _shareControllers.length).toStringAsFixed(2);
    _shareControllers.forEach((_, controller) {
      controller.text = equalShare;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsState = ref.watch(ingredientsStateProvider(widget.eventId));
    final notifier = ref.watch(ingredientsStateProvider(widget.eventId).notifier);
    final currentUser = ref.watch(currentUserProvider);
    final participants = ref.watch(participants_provider.eventParticipantsProvider(widget.eventId));
    final eventAsync = ref.watch(event_provider.eventProvider(widget.eventId));

    print('DEBUG - Build - currentUser?.id: ${currentUser?.id}');
    print('DEBUG - Build - ingredientsState: $ingredientsState');
    print('DEBUG - Build - notifier.ingredients count: ${notifier.ingredients.length}');

    // Définition des couleurs harmonisées
    const Color primaryColor = Color(0xFFFF5722);    // Orange pour les accents
    const Color backgroundColor = Color(0xFFF9F5F0); // Beige clair pour le fond
    const Color textColor = Color(0xFF2D3142);       // Gris foncé pour le texte
    const Color cardColor = Colors.white;            // Blanc pour les champs

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ingredientsState == IngredientsState.loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Ajouter une dépense',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Title Label
                    const Text(
                      'Titre',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Assigned Ingredients List
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: textColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          hintText: 'Sélectionner un ingrédient',
                          hintStyle: TextStyle(color: textColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                        dropdownColor: cardColor,
                        style: const TextStyle(color: textColor, fontSize: 16),
                        value: _selectedIngredientId,
                        items: notifier.ingredients
                            .where((ingredient) => ingredient.assignments?.isNotEmpty ?? false)
                            .map((ingredient) => DropdownMenuItem<int>(
                                  value: ingredient.id,
                                  child: Text(ingredient.name),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedIngredientId = value;
                            // Reset share controllers when ingredient changes
                            _shareControllers.clear();
                            _selectedParticipants.clear();
                            if (value != null) {
                              // Initialiser avec les participants assignés à l'ingrédient
                              final assignedParticipants = _getAssignedParticipants();
                              for (final participant in assignedParticipants) {
                                _selectedParticipants.add(participant['userId']);
                                _shareControllers[participant['userId']] = TextEditingController();
                              }
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner un ingrédient';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Amount Label
                    const Text(
                      'Montant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Amount Input
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: textColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          hintText: '0,00',
                          hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixText: '€',
                          suffixStyle: const TextStyle(color: textColor),
                          prefixIcon: const Icon(Icons.euro, color: primaryColor),
                        ),
                        style: const TextStyle(color: textColor, fontSize: 16),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) {
                          final amount = double.tryParse(value) ?? 0;
                          _updateShares(amount);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un montant';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Veuillez entrer un montant valide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payer Selection
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payé par',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: textColor.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    hintText: 'Sélectionner',
                                    hintStyle: TextStyle(color: textColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(15)),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                                  dropdownColor: cardColor,
                                  style: const TextStyle(color: textColor, fontSize: 16),
                                  value: _selectedPayerId,
                  items: _getAssignedParticipants().map((participant) {
                    final isCurrentUser = participant['userId'] == currentUser?.id;
                    return DropdownMenuItem<int>(
                      value: participant['userId'],
                      child: Text(isCurrentUser ? '${participant['name']} (Moi)' : participant['name']),
                    );
                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPayerId = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Requis';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quand',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: textColor.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                                      style: const TextStyle(fontSize: 16, color: textColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Share Division
                    if (_selectedIngredientId != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Diviser',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final amount = double.tryParse(_amountController.text) ?? 0;
                              if (_selectedParticipants.isNotEmpty) {
                                final equalShare = (amount / _selectedParticipants.length).toStringAsFixed(2);
                                for (final userId in _selectedParticipants) {
                                  _shareControllers[userId]?.text = equalShare;
                                }
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                            ),
                            child: const Text('Également'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._getAllEventParticipants().map((participant) {
                        final isCurrentUser = participant['userId'] == currentUser?.id;
                        final isSelected = _selectedParticipants.contains(participant['userId']);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSelected ? primaryColor : Colors.grey.withOpacity(0.3),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: textColor.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedParticipants.remove(participant['userId']);
                                        _shareControllers[participant['userId']]?.dispose();
                                        _shareControllers.remove(participant['userId']);
                                      } else {
                                        _selectedParticipants.add(participant['userId']);
                                        _shareControllers[participant['userId']] = TextEditingController();
                                        // Recalculer les parts égales
                                        final amount = double.tryParse(_amountController.text) ?? 0;
                                        if (amount > 0 && _selectedParticipants.isNotEmpty) {
                                          final equalShare = (amount / _selectedParticipants.length).toStringAsFixed(2);
                                          for (final userId in _selectedParticipants) {
                                            _shareControllers[userId]?.text = equalShare;
                                          }
                                        }
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected ? primaryColor : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? primaryColor : Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isCurrentUser ? '${participant['name']} (Moi)' : participant['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isSelected ? textColor : textColor.withOpacity(0.6),
                                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  SizedBox(
                                    width: 90,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white, // Fond blanc explicite
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: primaryColor.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _shareControllers[participant['userId']],
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          suffixText: '€',
                                          suffixStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                          hintText: '0,00',
                                          hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                                          filled: true,
                                          fillColor: Colors.white, // Fond blanc explicite
                                        ),
                                        style: const TextStyle(
                                          color: textColor, // Modifié de primaryColor à textColor
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                        ],
                                        validator: (value) {
                                          if (!isSelected) return null;
                                          if (value == null || value.isEmpty) {
                                            return 'Requis';
                                          }
                                          final amount = double.tryParse(value);
                                          if (amount == null || amount < 0) {
                                            return 'Invalide';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        )
                        );
                      }).toList(),
                    ],
                    const SizedBox(height: 32),

                    // Save Button
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Sauvegarder',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return months[month];
  }

  List<Map<String, dynamic>> _getAssignedParticipants() {
    if (_selectedIngredientId == null) return [];
    
    final selectedIngredient = ref.read(ingredientsStateProvider(widget.eventId).notifier)
        .ingredients.firstWhere((i) => i.id == _selectedIngredientId);
    
    final Set<int> assignedUserIds = {};
    final List<Map<String, dynamic>> assignedParticipants = [];

    // Ajouter les utilisateurs assignés à l'ingrédient
    for (final assignment in selectedIngredient.assignments ?? []) {
      if (!assignedUserIds.contains(assignment.userId)) {
        assignedUserIds.add(assignment.userId);
        assignedParticipants.add({
          'userId': assignment.userId,
          'name': assignment.user?.name ?? 'Utilisateur inconnu',
          'isOrganizer': false,
        });
      }
    }

    return assignedParticipants;
  }

  List<Map<String, dynamic>> _getAllEventParticipants() {
    final participants = ref.watch(participants_provider.eventParticipantsProvider(widget.eventId));
    final eventAsync = ref.watch(event_provider.eventProvider(widget.eventId));
    
    final List<Map<String, dynamic>> allParticipants = [];
    
    // Ajouter l'organisateur
    eventAsync.whenData((event) {
      if (event.organizer != null) {
        allParticipants.add({
          'userId': event.organizer!.id,
          'name': event.organizer!.name,
          'isOrganizer': true,
        });
      }
    });
    
    // Ajouter les participants (en évitant les doublons avec l'organisateur)
    participants.whenData((participantsList) {
      for (final participant in participantsList) {
        if (participant.user != null && 
            !allParticipants.any((p) => p['userId'] == participant.user!.id)) {
          allParticipants.add({
            'userId': participant.user!.id,
            'name': participant.user!.name,
            'isOrganizer': false,
          });
        }
      }
    });
    
    return allParticipants;
  }


  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate() || _selectedIngredientId == null || _selectedPayerId == null) {
      return;
    }

    // Vérifier qu'au moins un participant est sélectionné
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un participant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérifier que la somme des parts égale le montant total
    final totalAmount = double.parse(_amountController.text);
    final sumOfShares = _selectedParticipants
        .map((userId) => double.tryParse(_shareControllers[userId]?.text ?? '0') ?? 0)
        .reduce((a, b) => a + b);

    if ((sumOfShares - totalAmount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La somme des parts doit être égale au montant total'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final createExpense = ref.read(createExpenseProvider(widget.eventId));
      
      // Créer la dépense
      final expense = {
        'ingredient_id': _selectedIngredientId,
        'payer_id': _selectedPayerId,
        'amount': totalAmount,
        'shares': Map.fromEntries(_selectedParticipants.map((userId) => 
          MapEntry(userId.toString(), double.parse(_shareControllers[userId]?.text ?? '0')))),
      };

      // Envoyer la dépense au backend
      await createExpense(expense);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dépense enregistrée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
