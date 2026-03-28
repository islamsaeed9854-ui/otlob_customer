import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/cart_controller.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.cart, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (cartState.vendorBaskets.isNotEmpty)
            Text('${cartState.totalItems} ${s.cartButton}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
        ]),
        actions: [
          if (cartState.vendorBaskets.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clearCart(),
              child: Text(s.clearAll, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: cartState.vendorBaskets.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade200),
              const SizedBox(height: 20),
              Text(s.emptyCart, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(s.emptyCartSub, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.explore),
                label: Text(s.browseNow),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              ),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartState.vendorBaskets.length,
              itemBuilder: (context, index) {
                final vendorId = cartState.vendorBaskets.keys.elementAt(index);
                final vendorItems = cartState.vendorBaskets[vendorId]!;
                return _buildVendorBasket(context, ref, vendorId, vendorItems, s);
              },
            ),
    );
  }

  Widget _buildVendorBasket(BuildContext context, WidgetRef ref, String vendorId, List<CartItem> items, AppStrings s) {
    if (items.isEmpty) return const SizedBox.shrink();

    final vendorName = items.first.product['vendorName'] as String? ?? 'Vendor';
    final subtotal = ref.read(cartProvider).getVendorSubtotal(vendorId);
    final delivery = subtotal > 200 ? 0.0 : 15.0;
    final total = subtotal + delivery;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(vendorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Text('${items.length} ${s.cartButton}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: items.map((item) => _buildCartItem(context, ref, item, s)).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.total, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text('${total.toStringAsFixed(0)} ${s.egp}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => context.push('/checkout', extra: vendorId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(s.checkout, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item, AppStrings s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: (item.product['image']?.toString().isEmpty ?? true)
              ? Container(height: 60, width: 60, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, color: Colors.grey))
              : CachedNetworkImage(imageUrl: item.product['image'] as String, height: 60, width: 60, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.product['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 2),
          const SizedBox(height: 4),
          Text('${item.totalPrice.toStringAsFixed(0)} ${s.egp}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
        ])),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _qtyBtn(Icons.remove, () => ref.read(cartProvider.notifier).updateQuantity(item.product['id'], item.quantity - 1)),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
            _qtyBtn(Icons.add, () => ref.read(cartProvider.notifier).updateQuantity(item.product['id'], item.quantity + 1)),
          ]),
        ),
      ]),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(6), child: Icon(icon, size: 16, color: AppColors.primary)),
  );
}
