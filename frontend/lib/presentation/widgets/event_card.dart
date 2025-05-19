import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isPast;

  const EventCard({
    Key? key,
    required this.event,
    required this.onTap,
    this.isPast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPast ? 1 : 4,
      color: isPast ? theme.cardColor.withOpacity(0.5) : theme.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              // Émoji à gauche
              Text(
                event.emoji ??
                    '🙂', // Utilise un émoji par défaut si `emoji` est null
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              // Titre de l'événement
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPast
                        ? theme.textTheme.titleMedium?.color?.withOpacity(0.6)
                        : theme.textTheme.titleMedium?.color,
                  ),
                ),
              ),
              // Flèche à droite indiquant que la carte est cliquable
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
