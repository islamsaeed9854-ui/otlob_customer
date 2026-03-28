import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/home_controller.dart';
import '../widgets/vendor_card.dart';

class AllVendorsScreen extends ConsumerWidget {
  final String type;
  const AllVendorsScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final homeState = ref.watch(homeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          type == 'all'
              ? (s.isArabic ? 'جميع المتاجر' : 'All Stores')
              : type == 'restaurant'
                  ? s.restaurants
                  : type == 'pharmacy'
                      ? s.pharmacies
                      : s.supermarkets,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: homeState.when(
        data: (data) {
          final filtered = type == 'all'
              ? data.products
              : data.products.where((v) => v['type'] == type).toList();

          if (filtered.isEmpty) {
            return Center(child: Text(s.noResults));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return VendorCard(vendor: filtered[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }
}
