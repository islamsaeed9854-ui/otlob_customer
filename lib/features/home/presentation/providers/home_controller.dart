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
      ]);

      final resp0 = results[0].data;
      final resp1 = results[1].data;

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
        'type': v['slug'],
      }).toList();

      // Add "All" category at the beginning
      categories.insert(0, {'id': 'all', 'name': 'All', 'type': 'all'});

      // Map vendors
      final vendors = vendorsData.map((v) => Map<String, dynamic>.from(v as Map)).toList();

      return HomeData(
        categories: categories,
        products: vendors,
        activeOrder: null,
      );
    } catch (e, stack) {
      print('Error loading dashboard data: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }
}
