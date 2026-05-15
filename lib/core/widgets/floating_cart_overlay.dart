import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/cart/presentation/providers/cart_controller.dart';
import '../theme/app_colors.dart';
import '../l10n/app_strings.dart';

class FloatingCartOverlay extends ConsumerWidget {
  const FloatingCartOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    if (cartState.totalItems == 0) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    
    double totalCartPrice = 0;
    for (final vendorItems in cartState.vendorBaskets.values) {
      for (final item in vendorItems) {
        totalCartPrice += item.totalPrice;
      }
    }

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 65, // Positioned exactly above the bottom nav icons
      left: 16,
      right: 16,
      child: Center(
        child: GestureDetector(
          onTap: () => context.push('/cart'),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Keep it as a pill
              children: [
                Text(
                  '${cartState.totalItems} ${s.cartButton} • ${totalCartPrice.toStringAsFixed(0)} ${s.egp}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(LucideIcons.shoppingCart, color: Colors.black, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
