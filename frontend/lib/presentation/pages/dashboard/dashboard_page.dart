import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/presentation/pages/events/event_detail_page.dart';
import 'package:meal_planner/presentation/widgets/loading_screen.dart';
import 'package:go_router/go_router.dart';
import '../../../presentation/providers/event_provider.dart';
import '../../widgets/event_card.dart';
import '../events/create_event_page.dart';
import '../../widgets/filled_tonal_icon_button.dart';

final mealPlannerTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF558B2F),
    brightness: Brightness.light,
  ).copyWith(
    secondary: const Color(0xFF8BC34A),
    tertiary: const Color(0xFFFFB74D),
    surface: const Color(0xFFF9F5F0),
    onSurface: const Color(0xFF1C1B1F),
    primary: const Color(0xFFEF6C00),
    primaryContainer: const Color(0xFFFFB74D),
    outlineVariant: const Color(0xFFE0E0E0),
    error: const Color(0xFFD32F2F),
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: Color(0xFF1C1B1F),
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1C1B1F),
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      letterSpacing: 0.15,
      color: Color(0xFF4A4A4A),
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Color(0xFF6E6E6E),
    ),
  ),
);

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 2) {
      context.go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsStateProvider);
    final colorScheme = mealPlannerTheme.colorScheme;

    return Theme(
      data: mealPlannerTheme,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: _buildAppBar(colorScheme),
        body: _buildMainContent(eventsState, context),
        bottomNavigationBar: _buildBottomNavigationBar(colorScheme),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            'Meal Planner',
            style: mealPlannerTheme.textTheme.headlineMedium,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Rafraîchir',
              color: colorScheme.primary,
              onPressed: () => ref.read(eventsStateProvider.notifier).loadEvents(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: FilledTonalIconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateEventPage()),
                );
              },
              icon: const Icon(Icons.add),
              tooltip: 'Ajouter un repas',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(EventsState state, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            mealPlannerTheme.colorScheme.surface,
            mealPlannerTheme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ],
        ),
      ),
      child: _buildBody(state, context),
    );
  }

  Widget _buildBody(EventsState state, BuildContext context) {
    final colorScheme = mealPlannerTheme.colorScheme;

    switch (state) {
      case EventsState.initial:
      case EventsState.loading:
        return const LoadingScreen();

      case EventsState.loaded:
        final events = ref.watch(eventsStateProvider.notifier).events;
        if (events.isEmpty) {
          return _buildEmptyState(colorScheme);
        }
        return _buildEventsList(events, context, colorScheme);

      case EventsState.error:
        return _buildErrorState(colorScheme);
    }
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 80,
              color: colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Your personalized meal plan',
              style: mealPlannerTheme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Plan your meals for the entire week in minutes. Build your first meal plan to get started!',
              style: mealPlannerTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to create event page (add a meal)
                context.go('/events/create');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: mealPlannerTheme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Build Your First Meal Plan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(List<dynamic> events, BuildContext context, ColorScheme colorScheme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: EventCard(
            event: events[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailPage(eventId: events[index].id),
                ),
              );
            },
            icon: _getIconForType(events[index].type),
            iconColor: _getColorForType(events[index].type),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur: ${ref.read(eventsStateProvider.notifier).errorMessage}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(eventsStateProvider.notifier).loadEvents(),
              style: ElevatedButton.styleFrom(
                backgroundColor: mealPlannerTheme.colorScheme.primaryContainer,
                foregroundColor: mealPlannerTheme.colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(ColorScheme colorScheme) {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.5),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Meal Plan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to navigation changes if needed
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'dinner':
        return Icons.dinner_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'brunch':
        return Icons.brunch_dining;
      case 'breakfast':
        return Icons.free_breakfast;
      default:
        return Icons.restaurant_menu;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'dinner':
        return Colors.deepOrange;
      case 'lunch':
        return Colors.amber;
      case 'brunch':
        return Colors.lightGreen;
      case 'breakfast':
        return Colors.brown;
      case 'other':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
