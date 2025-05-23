import 'package:flutter/material.dart';
import '../../data/models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool isPast;
  final IconData? icon;
  final Color? iconColor; // <-- Ajoute ce paramètre

  const EventCard({
    Key? key,
    required this.event,
    required this.onTap,
    this.isPast = false,
    this.icon,
    this.iconColor, // <-- Ajoute ce paramètre
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPast ? 1 : 4,
      color: isPast ? theme.cardColor.withOpacity(0.5) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              // Image on the left
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: event.organizer?.avatarUrl != null
                    ? Image.network(
                        event.organizer!.avatarUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade300,
                        child: Icon(
                          icon ?? Icons.restaurant_menu, // <-- Utilise l'icône personnalisée si fournie
                          size: 30,
                          color: iconColor ?? Colors.grey, // <-- Utilise la couleur ici
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPast
                            ? theme.textTheme.titleMedium?.color
                                ?.withOpacity(0.6)
                            : theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.participants?.length ?? 0} Participants',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron icon
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
