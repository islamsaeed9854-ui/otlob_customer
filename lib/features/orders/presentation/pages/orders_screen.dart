import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/floating_cart_overlay.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.navOrders, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
      ),
      body: Stack(
        children: [
          ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, stack) => Center(child: Text(err.toString())),
            data: (orders) => orders.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(s.noResults, style: TextStyle(fontSize: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(context, order, s);
                    },
                  ),
          ),
          const FloatingCartOverlay(),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order, AppStrings s) {
    final isCustom = order['type'] == 'custom_delivery';
    final items = (order['items'] as List<dynamic>?) ?? [];
    
    double total = 0;
    if (isCustom) {
      total = (order['totalFee'] as num?)?.toDouble() ?? 0.0;
    } else {
      double subtotal = 0;
      for (var i in items) {
        final p = i['price'];
        final price = p is num ? p : (num.tryParse(p?.toString() ?? '0') ?? 0);
        final q = i['quantity'];
        final quantity = q is int ? q : (int.tryParse(q?.toString() ?? '1') ?? 1);
        subtotal += price * quantity;
      }
      final df = order['deliveryFee'];
      final deliveryFee = df is num ? df : (num.tryParse(df?.toString() ?? '0') ?? 0);
      total = subtotal + deliveryFee;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(isCustom ? s.customDeliveryTitle : '${s.orderNo}${order['id'].toString().split('-').last}', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(order['status'] as String, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
        const Divider(height: 24),
        if (isCustom) ...[
          Text('${s.pickupLocation}: ${order['pickup']}', style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey)),
          const SizedBox(height: 4),
          Text('${s.dropoffLocation}: ${order['dropoff']}', style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey)),
        ] else
          ...items.map((i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${i['quantity']}x ${i['name']}', style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey)),
          )),
        const Divider(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(s.total, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
          Text('${total.toStringAsFixed(0)} ${s.egp}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ]),
      ]),
    );
  }
}
