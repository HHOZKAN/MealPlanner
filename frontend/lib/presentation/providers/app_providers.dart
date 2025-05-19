import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider pour l'index de l'onglet sélectionné dans le tableau de bord
final selectedTabIndexProvider = StateProvider<int>((ref) => 0);