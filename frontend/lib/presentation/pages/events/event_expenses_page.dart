import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/event_model.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_message.dart';

class EventExpensesPage extends ConsumerStatefulWidget {
  final int eventId;
  
  const EventExpensesPage({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  @override
  ConsumerState<EventExpensesPage> createState() => _EventExpensesPageState();
}

class _EventExpensesPageState extends ConsumerState<EventExpensesPage> {
  bool _isLoading = false;
  String? _errorMessage;
  
  Future<void> _calculateExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Ici, vous devriez appeler votre API pour calculer les dépenses
      // Pour l'exemple, nous allons simplement attendre un peu
      await Future.delayed(const Duration(seconds: 1));
      
      // Rafraîchir les données
      ref.refresh(eventProvider(widget.eventId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dépenses calculées avec succès')),
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
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses'),
      ),
      body: eventAsync.when(
        data: (event) {
          final isOrganizer = currentUser != null && event.organizerId == currentUser.id;
          
          // Pour l'exemple, nous allons simuler des dépenses
          final expenses = [
            {
              'id': 1,
              'description': 'Ingrédients principaux',
              'amount': 45.50,
              'paidBy': 'Jean Dupont',
              'date': DateTime.now().subtract(const Duration(days: 2)),
            },
            {
              'id': 2,
              'description': 'Boissons',
              'amount': 28.75,
              'paidBy': 'Marie Martin',
              'date': DateTime.now().subtract(const Duration(days: 1)),
            },
            {
              'id': 3,
              'description': 'Desserts',
              'amount': 15.20,
              'paidBy': 'Pierre Durand',
              'date': DateTime.now(),
            },
          ];
          
          final totalExpenses = expenses.fold<double>(0, (sum, expense) => sum + (expense['amount'] as double));
          final perPersonAmount = totalExpenses / (event.participants?.length ?? 1);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                
                // Résumé des dépenses
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Résumé des dépenses',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total des dépenses:'),
                            Text(
                              NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(totalExpenses),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Nombre de participants:'),
                            Text(
                              '${event.participants?.length ?? 1}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Montant par personne:'),
                            Text(
                              NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(perPersonAmount),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        
                        if (isOrganizer) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _calculateExpenses,
                              icon: const Icon(Icons.calculate),
                              label: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Recalculer les dépenses'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Liste des dépenses
                Text(
                  'Détail des dépenses',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(expense['description'] as String),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payé par: ${expense['paidBy']}'),
                            Text(
                              'Date: ${DateFormat('dd/MM/yyyy').format(expense['date'] as DateTime)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        trailing: Text(
                          NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(expense['amount']),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Remboursements
                Text(
                  'Remboursements à effectuer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Exemple de remboursements
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: const Text('Marie Martin doit rembourser Jean Dupont'),
                    subtitle: const Text('Pour: Ingrédients principaux'),
                    trailing: Text(
                      NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(15.20),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: const Text('Pierre Durand doit rembourser Jean Dupont'),
                    subtitle: const Text('Pour: Ingrédients principaux'),
                    trailing: Text(
                      NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(10.30),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
}