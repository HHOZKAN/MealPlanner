import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meal_planner/presentation/providers/auth_provider.dart';
import 'package:dio/dio.dart';

final eventShareLinkProvider = FutureProvider.family<String, int>((ref, eventId) async {
  final dioClient = ref.watch(dioClientProvider);
  try {
    final response = await dioClient.get('/events/$eventId/participants/share-link');
    final data = response.data;
    if (data['status'] == 'success') {
      return data['data']['shareable_link'] as String;
    } else {
      throw Exception('Failed to fetch shareable link');
    }
  } on DioError catch (e) {
    throw Exception('Failed to fetch shareable link: ${e.message}');
  }
});
