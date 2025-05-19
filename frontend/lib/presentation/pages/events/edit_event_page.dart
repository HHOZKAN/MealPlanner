import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../../presentation/providers/event_provider.dart';

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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedType;
  late String _selectedStatus;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  final List<Map<String, dynamic>> _eventTypes = [
    {'value': 'dinner', 'label': 'Dîner', 'icon': Icons.dinner_dining, 'color': Colors.deepOrange},
    {'value': 'lunch', 'label': 'Déjeuner', 'icon': Icons.lunch_dining, 'color': Colors.amber},
    {'value': 'brunch', 'label': 'Brunch', 'icon': Icons.brunch_dining, 'color': Colors.lightGreen},
    {'value': 'breakfast', 'label': 'Petit-déjeuner', 'icon': Icons.free_breakfast, 'color': Colors.brown},
    {'value': 'other', 'label': 'Autre', 'icon': Icons.restaurant, 'color': Colors.purple},
  ];
  
  final List<Map<String, dynamic>> _eventStatuses = [
    {'value': 'draft', 'label': 'Brouillon', 'color': Colors.grey},
    {'value': 'planning', 'label': 'En préparation', 'color': Colors.blue},
    {'value': 'confirmed', 'label': 'Confirmé', 'color': Colors.green},
    {'value': 'cancelled', 'label': 'Annulé', 'color': Colors.red},
    {'value': 'completed', 'label': 'Terminé', 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description ?? '');
    _locationController = TextEditingController(text: widget.event.location ?? '');
    
    _selectedDate = widget.event.date;
    _selectedTime = TimeOfDay(
      hour: widget.event.date.hour,
      minute: widget.event.date.minute,
    );
    _selectedType = widget.event.type;
    _selectedStatus = widget.event.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime _getDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await ref.read(eventsStateProvider.notifier).updateEvent(
          id: widget.event.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          date: _getDateTime(),
          location: _locationController.text.trim(),
          type: _selectedType,
          status: _selectedStatus,
        );
        
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Événement mis à jour avec succès')),
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
    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'événement'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de l\'événement',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            // Type d'événement
            Text(
              'Type d\'événement',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _eventTypes.map((type) {
                final isSelected = _selectedType == type['value'];
                final color = type['color'] as Color;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : color,
                      ),
                      const SizedBox(width: 8),
                      Text(type['label'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = type['value'] as String;
                      });
                    }
                  },
                  backgroundColor: Colors.transparent,
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                  ),
                  elevation: isSelected ? 3 : 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Statut de l'événement
            Text(
              'Statut',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _eventStatuses.map((status) {
                final isSelected = _selectedStatus == status['value'];
                final color = status['color'] as Color;
                return ChoiceChip(
                  label: Text(status['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStatus = status['value'] as String;
                      });
                    }
                  },
                  backgroundColor: color.withOpacity(0.1),
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : color,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Date et heure
            Text(
              'Date et heure',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(dateFormat.format(_selectedDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lieu
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lieu (optionnel)',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 32),
            
            // Bouton de mise à jour
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateEvent,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Mettre à jour l\'événement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}