import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/ingredient_provider.dart';
import './common/modal_widgets.dart';
import './add_ingredient_modal/ingredient_form_logic.dart';
import '../../core/theme/app_theme.dart';

class AddIngredientModal extends ConsumerStatefulWidget {
  final int eventId;

  const AddIngredientModal({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  ConsumerState<AddIngredientModal> createState() => _AddIngredientModalState();
}

class _AddIngredientModalState extends ConsumerState<AddIngredientModal> {
  late final IngredientFormLogic _formLogic;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _estimatedPriceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formLogic = IngredientFormLogic(
      ref: ref,
      eventId: widget.eventId,
      formKey: _formKey,
      nameController: _nameController,
      quantityController: _quantityController,
      estimatedPriceController: _estimatedPriceController,
      notesController: _notesController,
    );
  }

  @override
  void dispose() {
    _formLogic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(ingredientUnitsProvider);

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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ModalHandle(),
              const SizedBox(height: AppTheme.spacingM),
              const ModalTitle(title: 'Ajouter un ingrédient'),
              const SizedBox(height: AppTheme.spacingL),

              // Nom de l'ingrédient
              const SectionLabel(label: 'Nom de l\'ingrédient'),
              const SizedBox(height: AppTheme.spacingS),
              StyledTextField(
                controller: _nameController,
                hintText: 'Ex: Tomates, Fromage...',
                prefixIcon: Icons.restaurant,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nom de l\'ingrédient';
                  }
                  return null;
                },
                onChanged: (_) {}, // Requis par StyledTextField
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Quantité et unité
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel(label: 'Quantité'),
                        const SizedBox(height: AppTheme.spacingS),
                        StyledTextField(
                          controller: _quantityController,
                          hintText: '1',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Quantité requise';
                            }
                            final quantity = double.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Quantité invalide';
                            }
                            return null;
                          },
                          onChanged: (_) {}, // Requis par StyledTextField
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel(label: 'Unité'),
                        const SizedBox(height: AppTheme.spacingS),
                        StyledDropdown<String>(
                          value: _formLogic.selectedUnit,
                          items: units.entries
                              .map((entry) => DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ))
                              .toList(),
                          hintText: 'Unité',
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _formLogic.setSelectedUnit(value);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Prix estimé
              const SectionLabel(label: 'Prix estimé (optionnel)'),
              const SizedBox(height: AppTheme.spacingS),
              StyledTextField(
                controller: _estimatedPriceController,
                hintText: '0,00',
                suffixText: '€',
                prefixIcon: Icons.euro,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (_) {}, // Requis par StyledTextField
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Notes
              const SectionLabel(label: 'Notes (optionnel)'),
              const SizedBox(height: AppTheme.spacingS),
              _NotesTextField(controller: _notesController),
              const SizedBox(height: AppTheme.spacingXL),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontSize: AppTheme.fontSizeM,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Ajouter',
                      isLoading: _formLogic.isLoading,
                      onPressed: () => _formLogic.saveIngredient(context, () => setState(() {})),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget personnalisé pour le champ de notes
class _NotesTextField extends StatelessWidget {
  final TextEditingController controller;

  const _NotesTextField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.cardShadow,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Ajouter des notes...',
          hintStyle: TextStyle(
            color: AppTheme.textColor.withOpacity(0.6),
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusL)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingM,
            vertical: AppTheme.spacingM,
          ),
          prefixIcon: const Icon(
            Icons.note,
            color: AppTheme.primaryColor,
          ),
        ),
        style: const TextStyle(
          color: AppTheme.textColor,
          fontSize: AppTheme.fontSizeM,
        ),
        maxLines: 3,
        textInputAction: TextInputAction.done,
      ),
    );
  }
}
