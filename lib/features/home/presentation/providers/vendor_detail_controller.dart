import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/network_providers.dart';

part 'vendor_detail_controller.g.dart';

@riverpod
class VendorDetailController extends _$VendorDetailController {
  @override
  FutureOr<Map<String, dynamic>> build(String vendorId) async {
    return fetchVendorDetails(vendorId);
  }

  Future<Map<String, dynamic>> fetchVendorDetails(String vendorId) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/vendors/$vendorId');
    final responseData = response.data as Map<String, dynamic>;
    return responseData['data'] as Map<String, dynamic>;
  }
}
