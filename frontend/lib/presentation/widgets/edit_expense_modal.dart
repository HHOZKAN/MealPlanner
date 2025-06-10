import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ingredient_provider.dart';
import '../providers/auth_provider.dart';
import './common/modal_widgets.dart';
import './common/participant_share_selector.dart';
import './add_expense_modal/expense_form_logic.dart';
import '../../../core/theme/app_theme.dart';
import '../../data/models/expense_model.dart';
import '../providers/expense_provider_new.dart';

class EditExpenseModal extends ConsumerStatefulWidget {
  final int eventId;
  final ExpenseModel expense;

  const EditExpenseModal({
    Key? key,
    required this.eventId,
    required this.expense,
  }) : super(key: key);

  @override
  ConsumerState<EditExpenseModal> createState() => _EditExpenseModalState();
}

class _EditExpenseModalState extends ConsumerState<EditExpenseModal> {
  late final EditExpenseFormLogic _formLogic;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _formLogic = EditExpenseFormLogic(
      ref: ref,
      eventId: widget.eventId,
      expense: widget.expense,
      formKey: _formKey,
      amountController: _amountController,
    );
  }

  @override
  void dispose() {
    _formLogic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsState = ref.watch(ingredientsStateProvider(widget.eventId));
    final notifier = ref.watch(ingredientsStateProvider(widget.eventId).notifier);
    final currentUser = ref.watch(currentUserProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: ingredientsState == IngredientsState.loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ModalHandle(),
                    const SizedBox(height: AppTheme.spacingM),
                    const ModalTitle(title: 'Modifier la dépense'),
                    const SizedBox(height: AppTheme.spacingL),

                    // Sélection de l'ingrédient
                    const SectionLabel(label: 'Titre'),
                    const SizedBox(height: AppTheme.spacingS),
                    StyledDropdown<int>(
                      value: _formLogic.selectedIngredientId,
                      items: notifier.ingredients
                          .where((ingredient) => ingredient.assignments?.isNotEmpty ?? false)
                          .map((ingredient) => DropdownMenuItem<int>(
                                value: ingredient.id,
                                child: Text(ingredient.name),
                              ))
                          .toList(),
                      hintText: 'Sélectionner un ingrédient',
                      onChanged: (value) => _formLogic.onIngredientChanged(value, () => setState(() {})),
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un ingrédient';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Montant
                    const SectionLabel(label: 'Montant'),
                    const SizedBox(height: AppTheme.spacingS),
                    StyledTextField(
                      controller: _amountController,
                      hintText: '0,00',
                      suffixText: '€',
                      prefixIcon: Icons.euro,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        final amount = double.tryParse(value) ?? 0;
                        _formLogic.updateShares(amount);
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
                    const SizedBox(height: AppTheme.spacingL),

                    // Sélection du payeur et date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionLabel(label: 'Payé par'),
                              const SizedBox(height: AppTheme.spacingS),
                              StyledDropdown<int>(
                                value: _formLogic.selectedPayerId,
                                items: _formLogic.getAssignedParticipants().map((participant) {
                                  final isCurrentUser = participant['userId'] == currentUser?.id;
                                  return DropdownMenuItem<int>(
                                    value: participant['userId'],
                                    child: Text(isCurrentUser ? '${participant['name']} (Moi)' : participant['name']),
                                  );
                                }).toList(),
                                hintText: 'Sélectionner',
                                onChanged: (value) => setState(() => _formLogic.selectedPayerId = value),
                                validator: (value) => value == null ? 'Requis' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionLabel(label: 'Quand'),
                              const SizedBox(height: AppTheme.spacingS),
                              DateDisplay(date: widget.expense.createdAt),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Sélection des participants et leurs parts
                    if (_formLogic.selectedIngredientId != null)
                      ParticipantShareSelector(
                        participants: _formLogic.getAllEventParticipants(),
                        selectedParticipants: _formLogic.selectedParticipants,
                        shareControllers: _formLogic.shareControllers,
                        currentUserId: currentUser?.id,
                        onParticipantToggle: (userId, isSelected) => 
                          _formLogic.onParticipantToggle(userId, isSelected, () => setState(() {})),
                        onEqualSharePressed: () {
                          _formLogic.distributeEqualShares();
                          setState(() {});
                        },
                      ),
                    const SizedBox(height: AppTheme.spacingXL),

                    // Bouton de mise à jour
                    PrimaryButton(
                      text: 'Mettre à jour',
                      isLoading: _formLogic.isLoading,
                      onPressed: () => _formLogic.updateExpense(context, () => setState(() {})),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Classe pour gérer la logique métier du formulaire de modification de dépense
class EditExpenseFormLogic extends ExpenseFormLogic {
  final ExpenseModel expense;

  EditExpenseFormLogic({
    required WidgetRef ref,
    required int eventId,
    required this.expense,
    required GlobalKey<FormState> formKey,
    required TextEditingController amountController,
  }) : super(
          ref: ref,
          eventId: eventId,
          formKey: formKey,
          amountController: amountController,
        ) {
    _initializeFromExpense();
  }

  /// Initialise les valeurs du formulaire à partir de la dépense existante
  void _initializeFromExpense() {
    selectedIngredientId = expense.ingredientId;
    selectedPayerId = expense.payerId;
    
    // Initialiser les parts existantes
    for (final share in expense.shares) {
      selectedParticipants.add(share.userId);
      shareControllers[share.userId] = TextEditingController(text: share.amount.toString());
    }
  }

  /// Met à jour la dépense existante
  Future<void> updateExpense(BuildContext context, VoidCallback setState) async {
    final validation = validateForm();
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.message!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    isLoading = true;
    setState();

    try {
      final notifier = ref.read(expensesStateProvider(eventId).notifier);
      final totalAmount = double.parse(amountController.text);
      
      // Créer les données de mise à jour
      final expenseData = {
        'ingredient_id': selectedIngredientId,
        'payer_id': selectedPayerId,
        'amount': totalAmount,
        'shares': Map.fromEntries(selectedParticipants.map((userId) => 
          MapEntry(userId.toString(), double.parse(shareControllers[userId]?.text ?? '0')))),
      };

      // Mettre à jour la dépense
      await notifier.updateExpense(expense.id, expenseData);
      await notifier.loadExpenses(); // Recharger les dépenses

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dépense mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        isLoading = false;
        setState();
      }
    }
  }
}
