import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/event_provider.dart';
import '../../../data/models/event_model.dart';

/// Classe pour gérer la logique d'édition d'événement
class EditEventLogic {
  final WidgetRef ref;
  final EventModel event;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;

  DateTime _selectedDate;
  TimeOfDay _selectedTime;
  String _selectedType;
  String _selectedStatus;
  String _selectedEmoji;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  DateTime get selectedDate => _selectedDate;
  TimeOfDay get selectedTime => _selectedTime;
  String get selectedType => _selectedType;
  String get selectedStatus => _selectedStatus;
  String get selectedEmoji => _selectedEmoji;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EditEventLogic({
    required this.ref,
    required this.event,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
  }) : _selectedDate = event.date,
       _selectedTime = TimeOfDay(
         hour: event.date.hour,
         minute: event.date.minute,
       ),
       _selectedType = event.type,
       _selectedStatus = event.status,
       _selectedEmoji = event.emoji ?? '🍽️';

  /// Types d'événements disponibles
  static const List<Map<String, dynamic>> eventTypes = [
    {
      'value': 'dinner',
      'label': 'Dîner',
      'icon': Icons.dinner_dining,
      'color': Color(0xFFFF5722)
    },
    {
      'value': 'lunch',
      'label': 'Déjeuner',
      'icon': Icons.lunch_dining,
      'color': Color(0xFFFF5722)
    },
    {
      'value': 'brunch',
      'label': 'Brunch',
      'icon': Icons.brunch_dining,
      'color': Color(0xFFFF5722)
    },
    {
      'value': 'breakfast',
      'label': 'Petit-déjeuner',
      'icon': Icons.free_breakfast,
      'color': Color(0xFFFF5722)
    },
    {
      'value': 'other',
      'label': 'Autre',
      'icon': Icons.restaurant,
      'color': Color(0xFFFF5722)
    },
  ];

  /// Statuts d'événements disponibles
  static const List<Map<String, dynamic>> eventStatuses = [
    {'value': 'draft', 'label': 'Brouillon', 'color': Colors.grey},
    {'value': 'planning', 'label': 'En préparation', 'color': Colors.blue},
    {'value': 'confirmed', 'label': 'Confirmé', 'color': Colors.green},
    {'value': 'cancelled', 'label': 'Annulé', 'color': Colors.red},
    {'value': 'completed', 'label': 'Terminé', 'color': Colors.teal},
  ];

  /// Emojis communs pour les événements
  static const List<String> commonEmojis = [
    '🍽️', '🍖', '🥘', '🥗', '🍝', '🍕', '🌮', '🥪', '🍱', '🍲'
  ];

  /// Met à jour la date sélectionnée
  void updateSelectedDate(DateTime date, VoidCallback setState) {
    _selectedDate = date;
    setState();
  }

  /// Met à jour l'heure sélectionnée
  void updateSelectedTime(TimeOfDay time, VoidCallback setState) {
    _selectedTime = time;
    setState();
  }

  /// Met à jour le type d'événement sélectionné
  void updateSelectedType(String type, VoidCallback setState) {
    _selectedType = type;
    setState();
  }

  /// Met à jour le statut d'événement sélectionné
  void updateSelectedStatus(String status, VoidCallback setState) {
    _selectedStatus = status;
    setState();
  }

  /// Met à jour l'emoji sélectionné
  void updateSelectedEmoji(String emoji, VoidCallback setState) {
    _selectedEmoji = emoji;
    setState();
  }

  /// Combine la date et l'heure sélectionnées
  DateTime getDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  /// Valide le formulaire
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Met à jour l'événement
  Future<bool> updateEvent(BuildContext context, VoidCallback setState) async {
    if (!validateForm()) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    setState();

    try {
      await ref.read(eventsStateProvider.notifier).updateEvent(
        id: event.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        date: getDateTime(),
        location: locationController.text.trim(),
        type: _selectedType,
        status: _selectedStatus,
      );

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement mis à jour avec succès')),
        );
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      setState();
    }
  }

  /// Nettoie les ressources
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
  }
}

/// Widget pour le sélecteur de statut avec chips
class StatusSelector extends StatelessWidget {
  final String selectedStatus;
  final Function(String) onStatusChanged;

  const StatusSelector({
    Key? key,
    required this.selectedStatus,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: EditEventLogic.eventStatuses.map((status) {
          final isSelected = selectedStatus == status['value'];
          final color = status['color'] as Color;
          return ChoiceChip(
            label: Text(status['label'] as String),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                onStatusChanged(status['value'] as String);
              }
            },
            backgroundColor: Colors.white,
            selectedColor: color,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.w500,
            ),
            elevation: isSelected ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSelected ? Colors.transparent : color.withOpacity(0.3),
                width: 1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
