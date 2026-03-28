import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'home_state.dart';

part 'home_controller.g.dart';

@riverpod
class HomeController extends _$HomeController {
  @override
  FutureOr<HomeData> build() async {
    return loadDashboardData();
  }

  Future<HomeData> loadDashboardData() async {
    // Mock data for UI development
    await Future.delayed(const Duration(seconds: 1));

    return HomeData(
      categories: [
        {'id': 1, 'name': 'All', 'type': 'all'},
        {'id': 2, 'name': 'Restaurant', 'type': 'restaurant'},
        {'id': 3, 'name': 'Pharmacy', 'type': 'pharmacy'},
        {'id': 4, 'name': 'Supermarket', 'type': 'supermarket'},
      ],
      products: [
        {
          'id': 'v1',
          'name': 'Burger King',
          'vendor': 'Fast Food • Burgers',
          'rating': 4.5,
          'deliveryTime': '20-30 دقيقة',
          'deliveryFee': '15 ج رسوم توصيل',
          'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop',
          'type': 'restaurant',
          'tag': 'Best Seller',
        },
        {
          'id': 'v2',
          'name': 'Seif Pharmacy',
          'vendor': 'Healthcare • Pharmacy',
          'rating': 4.8,
          'deliveryTime': '15-20 دقيقة',
          'deliveryFee': '10 ج رسوم توصيل',
          'image': 'https://loremflickr.com/600/400/pharmacy?lock=1',
          'type': 'pharmacy',
          'tag': 'Premium',
        },
        {
          'id': 'v3',
          'name': 'Carrefour',
          'vendor': 'Groceries • Supermarket',
          'rating': 4.2,
          'deliveryTime': '30-45 دقيقة',
          'deliveryFee': '20 ج رسوم توصيل',
          'image': 'https://loremflickr.com/600/400/supermarket?lock=2',
          'type': 'supermarket',
          'tag': 'Top Rated',
        },
      ],
      activeOrder: null,
    );
  }
}
