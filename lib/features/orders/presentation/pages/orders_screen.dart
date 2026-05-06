import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.navOrders, style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: orders.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(s.noResults, style: const TextStyle(fontSize: 18, color: Colors.grey)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(context, order, s);
              },
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
          Text(isCustom ? (s.isArabic ? 'طلب خاص' : 'Custom Delivery') : 'Order #${order['id'].toString().split('-').last}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(order['status'] as String, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ]),
        const Divider(height: 24),
        if (isCustom) ...[
          Text('${s.pickupLocation}: ${order['pickup']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 4),
          Text('${s.dropoffLocation}: ${order['dropoff']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ] else
          ...items.map((i) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('${i['quantity']}x ${i['name']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          )),
        const Divider(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(s.total, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${total.toStringAsFixed(0)} ${s.egp}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ]),
      ]),
    );
  }
}
