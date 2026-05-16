import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/network_providers.dart';

part 'support_ticket_provider.g.dart';

@riverpod
class SupportTicket extends _$SupportTicket {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String category,
    String? subCategory,
    String? description,
    String? orderId,
    String? vendorId,
    Map<String, dynamic>? metadata,
  }) async {
    final dio = ref.read(dioProvider);
    
    final response = await dio.post('/tickets', data: {
      'subject': subject,
      'category': category,
      'subCategory': subCategory,
      'description': description,
      'orderId': orderId,
      'vendorId': vendorId,
      'metadata': metadata,
    });

    return response.data['data'] ?? response.data;
  }

  Future<List<dynamic>> getTickets() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/tickets');
    final data = response.data['data'] ?? response.data;
    return data['tickets'] ?? [];
  }
}
