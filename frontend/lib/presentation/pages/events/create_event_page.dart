import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/event_form_widgets.dart';
import '../../widgets/participant_selector.dart';
import '../events/invite_participants_modal.dart';
import './create_event_logic.dart';
import '../../../core/theme/app_theme.dart';

class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  late final CreateEventLogic _logic;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _logic = CreateEventLogic(
      ref: ref,
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
        emojis: CreateEventLogic.commonEmojis,
        onEmojiSelected: (emoji) => _logic.updateSelectedEmoji(emoji, () => setState(() {})),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _logic.selectedDate,
      firstDate: DateTime.now(),
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

  Future<void> _handleCreateEvent() async {
    final event = await _logic.createEvent(() => setState(() {}));
    if (event != null && mounted) {
      final shareableLink = await _logic.getShareableLink(event.id);
      
      if (mounted) {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => InviteParticipantsModal(
            nicknames: _logic.selectedNicknames,
            invitationLink: shareableLink,
            onInviteLater: () => Navigator.of(context).pop(),
          ),
        );
        
        if (mounted) {
          _logic.navigateToDashboard(context);
        }
      }
    }
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
          'Create Event',
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
              labelText: 'Event Title',
              hintText: 'Ex: Dinner at Marie\'s',
              prefixIcon: Icons.title,
              validator: EventFormValidators.validateTitle,
              isRequired: true,
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Description
            ShadowedTextField(
              controller: _descriptionController,
              labelText: 'Description (optional)',
              hintText: 'Ex: Bring your specialty!',
              prefixIcon: Icons.description,
              maxLines: 3,
              validator: EventFormValidators.validateDescription,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Type d'événement
            const Text(
              'Event Type',
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
                items: CreateEventLogic.eventTypes.map((type) {
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

            // Date et heure
            const Text(
              'Date and Time',
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
              labelText: 'Location (optional)',
              hintText: 'Ex: 12 Lily Street, Paris',
              prefixIcon: Icons.location_on,
              validator: EventFormValidators.validateLocation,
            ),
            const SizedBox(height: AppTheme.spacingL),

            // Sélecteur de participants
            ParticipantSelector(
              selectedNicknames: _logic.selectedNicknames,
              onParticipantsChanged: (nicknames) => 
                _logic.updateSelectedNicknames(nicknames, () => setState(() {})),
              subtitle: 'Add participants to your event',
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Bouton de création
            SubmitButton(
              text: 'Create Event',
              onPressed: _handleCreateEvent,
              isLoading: _logic.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
