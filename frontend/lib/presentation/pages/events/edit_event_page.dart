import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../widgets/common/event_form_widgets.dart';
import '../../utils/event_form_validators.dart';
import './edit_event_logic.dart';
import '../../../core/theme/app_theme.dart';

class EditEventPage extends ConsumerStatefulWidget {
  final EventModel event;
  
  const EditEventPage({
    Key? key,
    required this.event,
  }) : super(key: key);

  @override
  ConsumerState<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends ConsumerState<EditEventPage> {
  late final EditEventLogic _logic;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description ?? '');
    _locationController = TextEditingController(text: widget.event.location ?? '');
    
    _logic = EditEventLogic(
      ref: ref,
      event: widget.event,
      formKey: _formKey,
      titleController: _titleController,
      descriptionController: _descriptionController,
      locationController: _locationController,
    );
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => EmojiPickerModal(
        emojis: EditEventLogic.commonEmojis,
        onEmojiSelected: (emoji) => _logic.updateSelectedEmoji(emoji, () => setState(() {})),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _logic.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _logic.selectedDate) {
      _logic.updateSelectedDate(picked, () => setState(() {}));
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _logic.selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _logic.selectedTime) {
      _logic.updateSelectedTime(picked, () => setState(() {}));
    }
  }

  Future<void> _handleUpdateEvent() async {
    await _logic.updateEvent(context, () => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modifier l\'événement',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          children: [
            // Sélecteur d'emoji
            EmojiSelector(
              selectedEmoji: _logic.selectedEmoji,
              onTap: _showEmojiPicker,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Message d'erreur
            if (_logic.errorMessage != null)
              ErrorMessageDisplay(message: _logic.errorMessage!),

            // Titre
            ShadowedTextField(
              controller: _titleController,
              labelText: 'Titre de l\'événement',
              hintText: 'Ex: Dîner chez Marie',
              prefixIcon: Icons.title,
              validator: EventFormValidators.validateTitle,
              isRequired: true,
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Description
            ShadowedTextField(
              controller: _descriptionController,
              labelText: 'Description (optionnelle)',
              hintText: 'Ex: Apportez votre spécialité !',
              prefixIcon: Icons.description,
              maxLines: 3,
              validator: EventFormValidators.validateDescription,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Type d'événement
            const Text(
              'Type d\'événement',
              style: TextStyle(
                fontSize: AppTheme.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.cardShadow,
              ),
              child: DropdownButtonFormField<String>(
                value: _logic.selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingM,
                    vertical: AppTheme.spacingM,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: EditEventLogic.eventTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'] as String,
                    child: Row(
                      children: [
                        Icon(type['icon'] as IconData, color: AppTheme.primaryColor),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          type['label'] as String,
                          style: const TextStyle(color: AppTheme.textColor),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _logic.updateSelectedType(value, () => setState(() {}));
                  }
                },
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Statut de l'événement
            const Text(
              'Statut',
              style: TextStyle(
                fontSize: AppTheme.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            StatusSelector(
              selectedStatus: _logic.selectedStatus,
              onStatusChanged: (status) => _logic.updateSelectedStatus(status, () => setState(() {})),
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Date et heure
            const Text(
              'Date et heure',
              style: TextStyle(
                fontSize: AppTheme.fontSizeM,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              children: [
                Expanded(
                  child: DateTimePicker(
                    icon: Icons.calendar_today,
                    value: dateFormat.format(_logic.selectedDate),
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: DateTimePicker(
                    icon: Icons.access_time,
                    value: _logic.selectedTime.format(context),
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Lieu
            ShadowedTextField(
              controller: _locationController,
              labelText: 'Lieu (optionnel)',
              hintText: 'Ex: 12 rue des Lilas, Paris',
              prefixIcon: Icons.location_on,
              validator: EventFormValidators.validateLocation,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Bouton de mise à jour
            SubmitButton(
              text: 'Mettre à jour l\'événement',
              onPressed: _handleUpdateEvent,
              isLoading: _logic.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
