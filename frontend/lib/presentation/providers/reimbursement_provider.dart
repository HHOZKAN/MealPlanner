import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/reimbursement_datasource.dart';
import '../../data/models/reimbursement_model.dart';

final reimbursementDatasourceProvider = Provider<ReimbursementDatasource>((ref) {
  return ReimbursementDatasource(client: http.Client());
});

final reimbursementProvider = StateNotifierProvider.family<ReimbursementNotifier, AsyncValue<List<ReimbursementModel>>, int>(
  (ref, eventId) => ReimbursementNotifier(
    ref.read(reimbursementDatasourceProvider),
    eventId,
  ),
);

class ReimbursementNotifier extends StateNotifier<AsyncValue<List<ReimbursementModel>>> {
  final ReimbursementDatasource _datasource;
  final int eventId;

  ReimbursementNotifier(this._datasource, this.eventId) : super(const AsyncValue.data([]));

  Future<void> markAsPaid({
    required int fromUserId,
    required int toUserId,
    String? paymentProof,
    String? notes,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // Appeler l'API pour marquer comme payé (qui va supprimer le remboursement)
      final response = await _datasource.markAsPaid(
        eventId: eventId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        paymentProof: paymentProof,
        notes: notes,
      );

      // La réponse contient les nouveaux remboursements après suppression
      if (response['reimbursements'] != null) {
        final reimbursements = (response['reimbursements'] as List)
            .map((r) => ReimbursementModel.fromJson(r))
            .toList();
        state = AsyncValue.data(reimbursements);
      } else {
        // Si pas de remboursements dans la réponse, recalculer
        final updatedReimbursements = await calculateReimbursements();
        state = AsyncValue.data(updatedReimbursements);
      }

    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<List<ReimbursementModel>> calculateReimbursements() async {
    try {
      state = const AsyncValue.loading();
      final reimbursements = await _datasource.calculateReimbursements(eventId);
      state = AsyncValue.data(reimbursements);
      return reimbursements;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
