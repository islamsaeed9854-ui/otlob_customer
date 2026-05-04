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
      // Parallel fetch for better performance
      final results = await Future.wait([
        dio.get('/vendor-verticals'),
        dio.get('/vendors'),
      ]);

      final verticalsData = results[0].data as List<dynamic>;
      final vendorsResponse = results[1].data as Map<String, dynamic>;
      final vendorsData = vendorsResponse['vendors'] as List<dynamic>;

      // Map verticals to categories
      final categories = verticalsData.map((v) => {
        'id': v['id'],
        'name': v['name'],
        'type': v['slug'],
      }).toList();

      // Add "All" category at the beginning
      categories.insert(0, {'id': 'all', 'name': 'All', 'type': 'all'});

      // Map vendors (app calls them products in the HomeData model)
      final vendors = vendorsData.map((v) => Map<String, dynamic>.from(v)).toList();

      return HomeData(
        categories: categories,
        products: vendors,
        activeOrder: null,
      );
    } catch (e) {
      // Fallback to empty lists or rethrow for error state
      print('Error loading dashboard data: $e');
      rethrow;
    }
  }
}
