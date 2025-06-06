import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/event_share_link_provider.dart';
import '../../widgets/participant_selector.dart';
import '../events/invite_participants_modal.dart';

class CreateEventPage extends ConsumerStatefulWidget {
  const CreateEventPage({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends ConsumerState<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedType = 'dinner';
  String _selectedEmoji = '🍽️';
  bool _isLoading = false;
  String? _errorMessage;
  final List<String> _selectedNicknames = [];

  final List<Map<String, dynamic>> _eventTypes = [
    {'value': 'dinner', 'label': 'Dîner', 'icon': Icons.dinner_dining, 'color': const Color(0xFFFF5722)},
    {'value': 'lunch', 'label': 'Déjeuner', 'icon': Icons.lunch_dining, 'color': const Color(0xFFFF5722)},
    {'value': 'brunch', 'label': 'Brunch', 'icon': Icons.brunch_dining, 'color': const Color(0xFFFF5722)},
    {'value': 'breakfast', 'label': 'Petit-déjeuner', 'icon': Icons.free_breakfast, 'color': const Color(0xFFFF5722)},
    {'value': 'other', 'label': 'Autre', 'icon': Icons.restaurant, 'color': const Color(0xFFFF5722)},
  ];

  final List<String> _commonEmojis = ['🍽️', '🍖', '🥘', '🥗', '🍝', '🍕', '🌮', '🥪', '🍱', '🍲'];

  // New: Dropdown selected value for event type
  String? _dropdownSelectedType;

  @override
  void initState() {
    super.initState();
    _dropdownSelectedType = _selectedType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choisir un emoji',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: _commonEmojis.map((emoji) => GestureDetector(
                onTap: () {
                  setState(() => _selectedEmoji = emoji);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 40,
                        color: Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
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

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        print('Creating event with nicknames: $_selectedNicknames');
        
        final event = await ref.read(eventsStateProvider.notifier).createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          date: _getDateTime(),
          location: _locationController.text.trim(),
          type: _selectedType,
          emoji: _selectedEmoji,
        );
        
        print('Event created with ID: ${event.id}');
        
        // Fetch shareable link using eventShareLinkProvider
        final shareableLink = await ref.read(eventShareLinkProvider(event.id).future);
        
        // Show invite participants modal after event creation
        if (mounted) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => InviteParticipantsModal(
              nicknames: _selectedNicknames,
              invitationLink: shareableLink,
              onInviteLater: () {
                Navigator.of(context).pop(); // Ferme seulement le modal
              },
            ),
          );
          
          // Naviguer vers le dashboard avec GoRouter
          if (mounted) {
            context.go('/');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Événement créé avec succès')),
            );
          }
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
      // Même couleur de fond que le dashboard
      backgroundColor: const Color(0xFFF9F5F0),
      appBar: AppBar(
        // Même couleur que le fond principal
        backgroundColor: const Color(0xFFF9F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFF5722)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Créer un événement',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Emoji Selector
            Center(
              child: GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: 0.5,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _selectedEmoji,
                      style: const TextStyle(
                        fontSize: 48,
                        color: Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ),
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

            // Titre - avec ombre plus prononcée pour mieux ressortir
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
              child: TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Color(0xFF2D3142)),
                decoration: InputDecoration(
                  labelText: 'Titre de l\'événement',
                  labelStyle: const TextStyle(color: Color(0xFF2D3142)),
                  hintText: 'Ex: Dîner chez Marie',
                  hintStyle: TextStyle(color: const Color(0xFF2D3142).withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.title, color: Color(0xFFFF5722)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    borderSide: const BorderSide(color: Color(0xFF6B4EFF)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Description - avec ombre plus prononcée
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
              child: TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Color(0xFF2D3142)),
                decoration: InputDecoration(
                  labelText: 'Description (optionnelle)',
                  labelStyle: const TextStyle(color: Color(0xFF2D3142)),
                  hintText: 'Ex: Apportez votre spécialité !',
                  hintStyle: TextStyle(color: const Color(0xFF2D3142).withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.description, color: Color(0xFFFF5722)),
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
                    borderSide: const BorderSide(color: Color(0xFF6B4EFF)),
                  ),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 24),
            
            // Type d'événement - texte en noir (non blanc)
            Text(
              'Type d\'événement',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142), // Changé de blanc à noir
              ),
            ),
            const SizedBox(height: 8),
            // Dropdown avec ombre
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
              child: DropdownButtonFormField<String>(
                value: _dropdownSelectedType,
                decoration: InputDecoration(
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
                    borderSide: const BorderSide(color: Color(0xFF6B4EFF)),
                  ),
                ),
                dropdownColor: Colors.white, // Fond blanc pour le dropdown
                items: _eventTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'] as String,
                    child: Row(
                      children: [
                        Icon(type['icon'] as IconData, color: const Color(0xFFFF5722)),
                        const SizedBox(width: 8),
                        Text(type['label'] as String, style: const TextStyle(color: Color(0xFF2D3142))),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _dropdownSelectedType = value;
                    _selectedType = value ?? 'dinner';
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            
            // Date et heure
            Text(
              'Date et heure',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
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
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFFFF5722)),
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
                        ),
                        child: Text(
                          dateFormat.format(_selectedDate),
                          style: const TextStyle(
                            color: Color(0xFF2D3142),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context),
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
                      child: InputDecorator(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.access_time, color: Color(0xFFFF5722)),
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
                        ),
                        child: Text(
                          _selectedTime.format(context),
                          style: const TextStyle(
                            color: Color(0xFF2D3142),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lieu
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
              child: TextFormField(
                controller: _locationController,
                style: const TextStyle(color: Color(0xFF2D3142)),
                decoration: InputDecoration(
                  labelText: 'Lieu (optionnel)',
                  labelStyle: const TextStyle(color: Color(0xFF2D3142)),
                  hintText: 'Ex: 12 rue des Lilas, Paris',
                  hintStyle: TextStyle(color: const Color(0xFF2D3142).withOpacity(0.6)),
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFFFF5722)),
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
                    borderSide: const BorderSide(color: Color(0xFF6B4EFF)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Sélecteur de participants
            ParticipantSelector(
              selectedNicknames: _selectedNicknames,
              onParticipantsChanged: (nicknames) {
                setState(() {
                  _selectedNicknames.clear();
                  _selectedNicknames.addAll(nicknames);
                });
              },
              subtitle: 'Ajoutez des participants à votre événement',
            ),
            
            const SizedBox(height: 32),
            
            // Bouton de création
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
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
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Créer l\'événement',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}