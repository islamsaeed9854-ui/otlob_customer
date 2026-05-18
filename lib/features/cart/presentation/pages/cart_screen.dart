import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_utils.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFFBFBFB),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          s.cart, 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 22,
            color: isDark ? Colors.white : Colors.black,
          )
        ),
        actions: [
          if (cartState.vendorBaskets.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: IconButton(
                onPressed: () => _showClearConfirmation(context, ref, s),
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                tooltip: s.clearAll,
              ),
            ),
        ],
      ),
      body: cartState.vendorBaskets.isEmpty
          ? _buildEmptyCart(context, s, isDark)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: cartState.vendorBaskets.length,
              itemBuilder: (context, index) {
                final vendorId = cartState.vendorBaskets.keys.elementAt(index);
                final vendorItems = cartState.vendorBaskets[vendorId] ?? [];
                return _buildVendorBasket(context, ref, vendorId, vendorItems, s, isDark);
              },
            ),
    );
  }

  Widget _buildEmptyCart(BuildContext context, AppStrings s, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_basket_outlined, 
              size: 120, 
              color: isDark ? Colors.white12 : Colors.grey.shade200
            ),
          ),
          const SizedBox(height: 32),
          Text(
            s.emptyCart, 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black
            )
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              s.emptyCartSub, 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600, 
                fontSize: 16,
                height: 1.5
              )
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              minimumSize: const Size(200, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: Text(
              s.browseNow, 
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
            ),
          ),
        ]
      )
    );
  }

  Widget _buildVendorBasket(BuildContext context, WidgetRef ref, String vendorId, List<CartItem> items, AppStrings s, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();

    final firstProduct = items.first.product;
    final vendorName = s.isArabic 
        ? (firstProduct['vendorNameAr'] ?? firstProduct['vendorName'] ?? s.vendor) 
        : (firstProduct['vendorName'] ?? s.vendor);
    final subtotal = ref.read(cartProvider).getVendorSubtotal(vendorId);
    final delivery = subtotal > 200 ? 0.0 : 15.0;
    
    // Calculate Service Fee dynamically for Non-Contracted stores
    final isContracted = firstProduct['isContracted'] == true;
    final rawRate = firstProduct['commissionRate'];
    final commissionRate = rawRate is num
        ? rawRate.toDouble()
        : (rawRate is String ? (double.tryParse(rawRate) ?? 0.0) : 0.0);
    final serviceFee = !isContracted ? (subtotal * (commissionRate / 100)) : 0.0;
    
    final total = subtotal + delivery + serviceFee;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), 
            blurRadius: 24, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vendor Header
          InkWell(
            onTap: () => context.push('/vendor', extra: {
              'id': vendorId,
              'storeName': firstProduct['vendorName'],
              'storeNameAr': firstProduct['vendorNameAr'],
              'logo': firstProduct['vendorLogo'],
              'coverImage': firstProduct['vendorCoverImage'],
              'image': firstProduct['vendorCoverImage'],
            }),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (firstProduct['vendorLogo']?.toString().isEmpty ?? true)
                        ? Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                          )
                        : CachedNetworkImage(
                            imageUrl: ImageUtils.formatImageUrl(firstProduct['vendorLogo'] as String?),
                            height: 40,
                            width: 40,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 40, width: 40,
                              color: isDark ? Colors.white12 : Colors.grey.shade100,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                            errorWidget: (context, url, error) => Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      vendorName, 
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 18,
                        color: isDark ? Colors.white : Colors.black87
                      )
                    )
                  ),
                  Icon(
                    s.isArabic ? Icons.arrow_back_ios_rounded : Icons.arrow_forward_ios_rounded, 
                    size: 14, 
                    color: isDark ? Colors.white24 : Colors.black26
                  ),
                ],
              ),
            ),
          ),
          
          const Divider(indent: 20, endIndent: 20, height: 32),

          // Items List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: items.map((item) => _buildCartItem(context, ref, item, s, isDark)).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // Basket Footer / Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.withOpacity(0.03),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              children: [
                _buildSummaryRow(s.subtotal, '${subtotal.toStringAsFixed(0)} ${s.egp}', isDark),
                const SizedBox(height: 8),
                _buildSummaryRow(s.deliveryFee, '${delivery.toStringAsFixed(0)} ${s.egp}', isDark, isDelivery: true),
                if (serviceFee > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    s.isArabic ? 'رسوم الخدمة' : 'Service Fee',
                    '${serviceFee.toStringAsFixed(0)} ${s.egp}',
                    isDark,
                  ),
                ],
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.total, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          '${total.toStringAsFixed(0)} ${s.egp}', 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary)
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/checkout', extra: vendorId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(120, 54),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(s.checkout, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isDelivery = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
        Text(
          value, 
          style: TextStyle(
            color: isDelivery && value.startsWith('0') ? AppColors.success : (isDark ? Colors.white : Colors.black), 
            fontSize: 14, 
            fontWeight: FontWeight.w800
          )
        ),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item, AppStrings s, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ((item.product['imageUrl'] ?? item.product['image'])?.toString().isEmpty ?? true)
                    ? Container(height: 80, width: 80, color: isDark ? Colors.white12 : Colors.grey.shade100, child: const Icon(Icons.fastfood, color: Colors.grey))
                    : CachedNetworkImage(imageUrl: ImageUtils.formatImageUrl((item.product['imageUrl'] ?? item.product['image']) as String?), height: 80, width: 80, fit: BoxFit.cover),
              ),
              Positioned(
                top: 0, right: 0,
                child: GestureDetector(
                  onTap: () => ref.read(cartProvider.notifier).updateQuantity(item, 0),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  s.isArabic ? (item.product['nameAr'] ?? item.product['name'] ?? '') : (item.product['name'] ?? ''), 
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : Colors.black), 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis
                ),
                if (item.selectedUnit == 'strip')
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(s.strip, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                if (item.selectedVariant != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.isArabic ? (item.selectedVariant!['nameAr'] ?? item.selectedVariant!['name'] ?? '') : (item.selectedVariant!['name'] ?? ''),
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (item.selectedOptions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.selectedOptions.map((o) => s.isArabic ? (o['nameAr'] ?? o['name'] ?? '') : (o['name'] ?? '')).join(', '),
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${item.totalPrice.toStringAsFixed(0)} ${s.egp}', 
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16)
                ),
              ]
            )
          ),
          
          const SizedBox(width: 12),

          // Quantity Pill
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100, 
              borderRadius: BorderRadius.circular(20)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                _qtyBtn(Icons.remove, isDark, () => ref.read(cartProvider.notifier).updateQuantity(item, item.quantity - 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8), 
                  child: Text('${item.quantity}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87))
                ),
                _qtyBtn(Icons.add, isDark, () => ref.read(cartProvider.notifier).updateQuantity(item, item.quantity + 1)),
              ]
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, bool isDark, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8), 
        child: Icon(icon, size: 18, color: AppColors.primary)
      ),
    ),
  );

  void _showClearConfirmation(BuildContext context, WidgetRef ref, AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.clearAll, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(s.emptyCartSub), // Reusing string for confirmation
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
          TextButton(
            onPressed: () async {
              // Show a simple loading indicator or just await the remote operation
              await ref.read(cartProvider.notifier).clearCart();
              if (context.mounted) {
                Navigator.pop(context);
              }
            }, 
            child: Text(s.yes, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}
