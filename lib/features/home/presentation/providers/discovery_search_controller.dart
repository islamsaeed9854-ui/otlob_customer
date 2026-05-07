import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';

final discoverySearchControllerProvider = FutureProvider.family<List<Map<String, dynamic>>, ({String query, String? verticalId})>((ref, arg) async {
  final dio = ref.read(dioProvider);
  
  if (arg.query.isEmpty) return [];

  // Convert verticalId 'all' to null for backend
  final vId = arg.verticalId == 'all' ? null : arg.verticalId;

  try {
    final response = await dio.get(
      '/vendors/discovery/search',
      queryParameters: {
        'search': arg.query,
        if (vId != null) 'verticalId': vId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final results = data['data']['results'] as List<dynamic>? ?? [];
    return results.map((v) => Map<String, dynamic>.from(v as Map)).toList();
  } catch (e) {
    print('Discovery search error: $e');
    return [];
  }
});



