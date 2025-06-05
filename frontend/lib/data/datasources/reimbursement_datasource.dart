import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/reimbursement_model.dart';
import '../../core/config/api_config.dart';
import '../../core/utils/token_storage.dart';

class ReimbursementDatasource {
  final http.Client client;

  ReimbursementDatasource({required this.client});

  Future<Map<String, dynamic>> markAsPaid({
    required int eventId,
    required int fromUserId,
    required int toUserId,
    String? paymentProof,
    String? notes,
  }) async {
    final token = await TokenStorage.getToken();
    
    print('Appel API markAsPaid pour eventId: $eventId, fromUserId: $fromUserId, toUserId: $toUserId');
    
    final url = '${ApiConfig.baseUrl}/events/$eventId/reimbursements/paid';
    print('URL: $url');
    
    final response = await client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'from_user_id': fromUserId,
        'to_user_id': toUserId,
        if (paymentProof != null) 'payment_proof': paymentProof,
        if (notes != null) 'notes': notes,
      }),
    );

    print('Réponse API markAsPaid:');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Data décodée markAsPaid: $data');
      return data['data']; // Retourner toutes les données (remboursements + soldes)
    } else {
      throw Exception('Erreur lors du marquage du remboursement: ${response.body}');
    }
  }

  Future<List<ReimbursementModel>> calculateReimbursements(int eventId) async {
    final token = await TokenStorage.getToken();
    
    print('Appel API calculateReimbursements pour eventId: $eventId');
    
    final response = await client.post(
      Uri.parse('${ApiConfig.baseUrl}/events/$eventId/reimbursements/calculate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Réponse API calculateReimbursements:');
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Data décodée: $data');
      
      final reimbursements = data['data']['reimbursements'] as List;
      print('Remboursements extraits: $reimbursements');
      
      final result = reimbursements.map((r) => ReimbursementModel.fromJson(r)).toList();
      print('Remboursements convertis: ${result.length} éléments');
      
      return result;
    } else {
      throw Exception('Erreur lors du calcul des remboursements: ${response.body}');
    }
  }
}
