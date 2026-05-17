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
    final data = responseData['data'] as Map<String, dynamic>;

    // Map vendor fields
    data['name'] = data['storeName'];
    data['nameAr'] = data['storeNameAr'];
    data['image'] = data['coverImage'] ?? data['logo'];
    data['logo'] = data['logo'];
    data['coverImage'] = data['coverImage'];
    data['vendor'] = data['description'];
    data['vendorAr'] = data['descriptionAr'];
    data['type'] = data['vertical']?['slug'] ?? 'other';

    // Flatten categories or use direct products/menu list
    final List<Map<String, dynamic>> menu = [];
    if (data['menu'] != null && (data['menu'] as List).isNotEmpty) {
      for (final item in data['menu']) {
        menu.add(Map<String, dynamic>.from(item as Map));
      }
    } else if (data['products'] != null && (data['products'] as List).isNotEmpty) {
      final products = data['products'] as List<dynamic>;
      for (final prod in products) {
        final Map<String, dynamic> p = Map<String, dynamic>.from(prod as Map);
        p['category'] = p['categoryId'];
        p['image'] = p['imageUrl'];
        p['price'] = p['basePrice'];
        menu.add(p);
      }
    } else {
      final categories = data['categories'] as List<dynamic>? ?? [];
      for (final cat in categories) {
        final products = cat['products'] as List<dynamic>? ?? [];
        for (final prod in products) {
          final Map<String, dynamic> p = Map<String, dynamic>.from(prod as Map);
          p['category'] = cat['id'];
          p['image'] = p['imageUrl'];
          p['price'] = p['basePrice'];
          menu.add(p);
        }
      }
    }
    data['menu'] = menu;

    return data;
  }
}
