import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/network_providers.dart';
import 'home_state.dart';

part 'home_controller.g.dart';

@riverpod
class HomeController extends _$HomeController {
  @override
  FutureOr<HomeData> build() async {
    return loadDashboardData();
  }

  Future<HomeData> loadDashboardData() async {
    final dio = ref.read(dioProvider);

    try {
      final results = await Future.wait([
        dio.get('/vendor-verticals'),
        dio.get('/vendors'),
        dio.get('/promotions'),
        dio.get('/offers'),
      ]);

      final resp0 = results[0].data;
      final resp1 = results[1].data;
      final resp2 = results[2].data;
      final resp3 = results[3].data;

      List<dynamic> verticalsData = [];
      if (resp0 is Map<String, dynamic>) {
        verticalsData = resp0['data'] as List<dynamic>? ?? [];
      } else if (resp0 is List) {
        verticalsData = resp0;
      }

      Map<String, dynamic> vendorsMap = {};
      if (resp1 is Map<String, dynamic>) {
        final dataField = resp1['data'];
        if (dataField is Map<String, dynamic>) {
          vendorsMap = dataField;
        } else if (dataField is List) {
           // Handle case where 'data' is a list directly
           vendorsMap = {'vendors': dataField};
        }
      }

      final vendorsData = vendorsMap['vendors'] as List<dynamic>? ?? [];

      // Map verticals to categories
      final categories = verticalsData.map((v) => {
        'id': v['id'],
        'name': v['name'],
        'nameAr': v['nameAr'],
        'iconUrl': v['iconUrl'],
        'type': v['slug'],
      }).toList();

      // Add "All" category at the beginning
      categories.insert(0, {'id': 'all', 'name': 'All', 'nameAr': 'الكل', 'type': 'all'});

      // Map vendors
      final vendors = vendorsData.map((v) {
        final Map<String, dynamic> vendor = Map<String, dynamic>.from(v as Map);
        // Map backend fields to frontend expectations
        vendor['name'] = vendor['storeName'];
        vendor['nameAr'] = vendor['storeNameAr'];
        vendor['image'] = vendor['coverImage'] ?? vendor['logo'];
        vendor['logo'] = vendor['logo'];
        vendor['coverImage'] = vendor['coverImage'];
        vendor['vendor'] = vendor['description'];
        vendor['vendorAr'] = vendor['descriptionAr'];
        vendor['type'] = vendor['vertical']?['slug'] ?? 'other';
        return vendor;
      }).toList();

      // Map promotions
      List<dynamic> promotionsData = [];
      if (resp2 is Map<String, dynamic>) {
        promotionsData = resp2['data'] as List<dynamic>? ?? [];
      } else if (resp2 is List) {
        promotionsData = resp2;
      }
      
      final promotions = promotionsData.map((p) => {
        'id': p['id'],
        'title': p['title'],
        'titleAr': p['titleAr'],
        'description': p['description'],
        'descriptionAr': p['descriptionAr'],
        'imageUrl': p['imageUrl'],
        'type': p['type'],
        'vendorId': p['vendorId'],
        'productId': p['productId'],
        'externalUrl': p['externalUrl'],
      }).toList();

      // Map offers
      List<dynamic> offersData = [];
      if (resp3 is Map<String, dynamic>) {
        offersData = (resp3['data'] ?? resp3['offers']) as List<dynamic>? ?? [];
      } else if (resp3 is List) {
        offersData = resp3;
      }

      final offers = offersData.map((o) => {
        'id': o['id'],
        'originalPrice': o['originalPrice'],
        'offerPrice': o['offerPrice'],
        'vendorId': o['vendorId'],
        'productId': o['productId'],
        'isActive': o['isActive'],
        'sortOrder': o['sortOrder'],
        // Enriched from relations
        'productImageUrl': o['product']?['imageUrl'],
        'productName': o['product']?['name'],
        'productNameAr': o['product']?['nameAr'],
        'productBasePrice': o['product']?['basePrice'],
        'productComparePrice': o['product']?['comparePrice'],
        'vendorStoreName': o['vendor']?['storeName'],
        'vendorStoreNameAr': o['vendor']?['storeNameAr'],
      }).toList();

      return HomeData(
        categories: categories,
        products: vendors,
        promotions: promotions,
        offers: offers,
        activeOrder: null,
      );
    } catch (e, stack) {
      print('Error loading dashboard data: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }
}
