import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/event_provider.dart';
import '../../providers/event_share_link_provider.dart';
import '../../../data/models/event_model.dart';

/// Class to manage event creation logic
class CreateEventLogic {
  final WidgetRef ref;
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'dinner';
  String _selectedEmoji = '🍽️';
  bool _isLoading = false;
  String? _errorMessage;
  final List<String> _selectedNicknames = [];

  // Getters
  DateTime get selectedDate => _selectedDate;
  TimeOfDay get selectedTime => _selectedTime;
  String get selectedType => _selectedType;
  String get selectedEmoji => _selectedEmoji;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get selectedNicknames => _selectedNicknames;

  CreateEventLogic({
    required this.ref,
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
  });

  /// Available event types
  static const List<Map<String, dynamic>> eventTypes = [
    {
      'value': 'dinner',
      'label': 'Dinner',
      'icon': Icons.dinner_dining,
      'color': Color(0xFFFF5722)
    },
    {
      'value': 'lunch',
      'label': 'Lunch',
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
      'label': 'Breakfast',
      'icon': Icons.free_breakfast,
      'color': Color(0xFFFF5722)
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.restaurant,
      'color': Color(0xFFFF5722)
    },
  ];

  /// Common emojis for events
  static const List<String> commonEmojis = [
    '🍽️', '🍖', '🥘', '🥗', '🍝', '🍕', '🌮', '🥪', '🍱', '🍲'
  ];

  /// Updates the selected date
  void updateSelectedDate(DateTime date, VoidCallback setState) {
    _selectedDate = date;
    setState();
  }

  /// Updates the selected time
  void updateSelectedTime(TimeOfDay time, VoidCallback setState) {
    _selectedTime = time;
    setState();
  }

  /// Updates the selected event type
  void updateSelectedType(String type, VoidCallback setState) {
    _selectedType = type;
    setState();
  }

  /// Updates the selected emoji
  void updateSelectedEmoji(String emoji, VoidCallback setState) {
    _selectedEmoji = emoji;
    setState();
  }

  /// Updates the selected participants
  void updateSelectedNicknames(List<String> nicknames, VoidCallback setState) {
    _selectedNicknames.clear();
    _selectedNicknames.addAll(nicknames);
    setState();
  }

  /// Combines the selected date and time
  DateTime getDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  /// Validates the form
  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Creates the event
  Future<EventModel?> createEvent(VoidCallback setState) async {
    if (!validateForm()) {
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    setState();

    try {
      final event = await ref.read(eventsStateProvider.notifier).createEvent(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        date: getDateTime(),
        location: locationController.text.trim(),
        type: _selectedType,
        emoji: _selectedEmoji,
      );

      return event;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      setState();
    }
  }

  /// Gets the shareable link for the event
  Future<String> getShareableLink(int eventId) async {
    return await ref.read(eventShareLinkProvider(eventId).future);
  }

  /// Navigates to dashboard after creation
  void navigateToDashboard(BuildContext context) {
    if (context.mounted) {
      context.go('/');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully')),
      );
    }
  }

  /// Cleans up resources
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
  }
}

/// Class for form validators
class EventFormValidators {
  /// Validates the event title
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a title';
    }
    if (value.length < 3) {
      return 'Title must contain at least 3 characters';
    }
    if (value.length > 100) {
      return 'Title cannot exceed 100 characters';
    }
    return null;
  }

  /// Validates the event description
  static String? validateDescription(String? value) {
    if (value != null && value.length > 500) {
      return 'Description cannot exceed 500 characters';
    }
    return null;
  }

  /// Validates the event location
  static String? validateLocation(String? value) {
    if (value != null && value.length > 200) {
      return 'Location cannot exceed 200 characters';
    }
    return null;
  }
}
