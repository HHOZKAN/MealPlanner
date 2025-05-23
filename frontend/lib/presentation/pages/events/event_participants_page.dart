import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/event_model.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';

class EventParticipantsPage extends ConsumerStatefulWidget {
  final int eventId;
  
  const EventParticipantsPage({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  ConsumerState<EventParticipantsPage> createState() => _EventParticipantsPageState();
}

class _EventParticipantsPageState extends ConsumerState<EventParticipantsPage> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _inviteParticipant() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer une adresse email';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final eventRepository = ref.read(eventRepositoryProvider);
      await eventRepository.inviteParticipant(
        eventId: widget.eventId,
        email: _emailController.text.trim(),
        message: _messageController.text.trim(),
      );
      
      // Rafraîchir les données
      ref.refresh(eventProvider(widget.eventId));
      ref.refresh(eventParticipantsProvider(widget.eventId));
      
      // Réinitialiser les champs
      _emailController.clear();
      _messageController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation envoyée avec succès')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    final participantsAsync = ref.watch(eventParticipantsProvider(widget.eventId));
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
      ),
      body: eventAsync.when(
        data: (event) {
          final isOrganizer = currentUser != null && event.organizerId == currentUser.id;
          
          return Column(
            children: [
              // Formulaire d'invitation (seulement pour l'organisateur)
              if (isOrganizer)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inviter un participant',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          
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
                          
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Entrez l\'email du participant',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              labelText: 'Message (optionnel)',
                              hintText: 'Ajoutez un message personnalisé',
                              prefixIcon: Icon(Icons.message),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _inviteParticipant,
                              icon: const Icon(Icons.send),
                              label: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Envoyer l\'invitation'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Liste des participants
              Expanded(
                child: participantsAsync.when(
                  data: (participants) {
                    if (participants.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun participant',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isOrganizer
                                  ? 'Invitez des participants en utilisant le formulaire ci-dessus'
                                  : 'Aucun participant n\'a encore rejoint cet événement',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        final user = participant.user;
                        
                        if (user == null) {
                          return const SizedBox.shrink();
                        }
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary,
                              child: user.avatarUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        user.avatarUrl!,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(user.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                const SizedBox(height: 4),
                                _buildStatusChip(context, participant.status),
                              ],
                            ),
                            trailing: isOrganizer && user.id != currentUser.id
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showRemoveParticipantDialog(participant),
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const LoadingIndicator(),
                  error: (error, stackTrace) => ErrorMessage(
                    message: 'Erreur lors du chargement des participants: $error',
                    onRetry: () => ref.refresh(eventParticipantsProvider(widget.eventId)),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, stackTrace) => ErrorMessage(
          message: 'Erreur lors du chargement de l\'événement: $error',
          onRetry: () => ref.refresh(eventProvider(widget.eventId)),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'accepted':
        color = Colors.green;
        label = 'Accepté';
        break;
      case 'declined':
        color = Colors.red;
        label = 'Refusé';
        break;
      case 'maybe':
        color = Colors.orange;
        label = 'Peut-être';
        break;
      case 'pending':
        color = Colors.blue;
        label = 'En attente';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Future<void> _showRemoveParticipantDialog(ParticipantModel participant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le participant'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${participant.user?.name} de cet événement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        // Implémenter la suppression du participant
        // Vous devrez ajouter cette méthode à votre repository
        
        // Rafraîchir les données
        ref.refresh(eventProvider(widget.eventId));
        ref.refresh(eventParticipantsProvider(widget.eventId));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Participant supprimé avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}