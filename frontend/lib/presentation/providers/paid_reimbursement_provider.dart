import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reimbursement_model.dart';
import 'reimbursement_provider.dart';

final paidReimbursementProvider = FutureProvider.family<List<ReimbursementModel>, int>((ref, eventId) async {
  final datasource = ref.read(reimbursementDatasourceProvider);
  
  try {
    // Récupérer tous les remboursements payés pour cet événement
    return await datasource.getPaidHistory(eventId);
  } catch (e) {
    print('Erreur lors de la récupération des remboursements payés: $e');
    return [];
  }
});
