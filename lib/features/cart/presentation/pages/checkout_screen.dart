import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/cart_controller.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../../../core/services/location_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String? vendorId;
  const CheckoutScreen({super.key, required this.vendorId});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedPayment = 'cash';
  bool _isProcessing = false;
  Map<String, dynamic>? _selectedAddress;

  void _placeOrder(AppStrings s, List<CartItem> vendorItems) async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.isArabic ? 'الرجاء اختيار عنوان' : 'Please select an address')));
      return;
    }

    setState(() => _isProcessing = true);

    final location = _selectedAddress!['location'] as List<dynamic>?;
    final List<double> coords = location?.map((e) => (e as num).toDouble()).toList() ??
        [24.7136, 46.6753];

    final success = await ref.read(ordersProvider.notifier).placeOrder(
          vendorId: widget.vendorId ?? '',
          items: vendorItems,
          paymentMethod: _selectedPayment,
          address: _selectedAddress!['address'] ?? s.locationName,
          location: coords,
        );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ref.read(cartProvider.notifier).clearVendorCart(widget.vendorId ?? '');
        _showSuccess(s);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                s.isArabic ? 'فشل إتمام الطلب' : 'Failed to place order')));
      }
    }
  }

  void _showSuccess(AppStrings s) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 150,
            width: 150,
            child: Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json',
              repeat: false,
              errorBuilder: (c, e, st) =>
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.orderSuccess,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(s.orderSuccessSub,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.pop();
                context.go('/orders');
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(s.goToOrders, style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.pop();
              context.go('/home');
            },
            child: Text(s.navHome),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final cartState = ref.watch(cartProvider);
    final profileState = ref.watch(profileProvider);

    if (widget.vendorId == null ||
        !cartState.vendorBaskets.containsKey(widget.vendorId)) {
      return Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop())),
        body: Center(child: Text(s.emptyCart)),
      );
    }

    final vendorItems = cartState.vendorBaskets[widget.vendorId ?? ''] ?? [];
    final vendorName = vendorItems.isNotEmpty
        ? (vendorItems.first.product['vendorName'] as String? ?? s.vendor)
        : s.vendor;
    final subtotal = cartState.getVendorSubtotal(widget.vendorId ?? '');

    // In a real app, delivery fee comes from backend based on location
    final deliveryFee = subtotal > 200 ? 0.0 : 15.0;
    final total = subtotal + deliveryFee;

    // Auto-select default address if not set
    if (_selectedAddress == null && profileState.addresses.isNotEmpty) {
      _selectedAddress = profileState.addresses.first;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.checkoutTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(vendorName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: _isProcessing
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionCard(s.deliveryAddress, [
                  if (profileState.addresses.isEmpty)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_off, color: Colors.grey),
                      title: Text(
                          s.isArabic ? 'لا توجد عناوين' : 'No addresses found'),
                      subtitle: Text(s.isArabic
                          ? 'اضف عنواناً في الملف الشخصي'
                          : 'Add one in profile'),
                      trailing: TextButton(
                        onPressed: () => context.push('/profile/addresses'),
                        child: Text(s.isArabic ? 'إضافة' : 'Add'),
                      ),
                    )
                  else
                    ...profileState.addresses.map((addr) => RadioListTile<Map<String, dynamic>>(
                          value: addr,
                          groupValue: _selectedAddress,
                          onChanged: (val) =>
                              setState(() => _selectedAddress = val),
                          contentPadding: EdgeInsets.zero,
                          title: Text(addr['label'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(addr['address'] ?? '',
                              style: const TextStyle(fontSize: 12)),
                          activeColor: AppColors.primary,
                        )),
                ]),
                const SizedBox(height: 16),
                _sectionCard(s.paymentMethod, [
                  _paymentOption(s.cash, Icons.money, 'cash'),
                  _paymentOption(s.creditCard, Icons.credit_card, 'card'),
                ]),
                const SizedBox(height: 16),
                _sectionCard(s.orderSummary, [
                  ...vendorItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                  child: Text(item.product['name'] as String,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold))),
                              Text('x${item.quantity}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              const SizedBox(width: 8),
                              Text(
                                  '${item.totalPrice.toStringAsFixed(0)} ${s.egp}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ]),
                            if (item.selectedVariant != null)
                              Text(
                                  s.isArabic
                                      ? (item.selectedVariant!['nameAr'] ??
                                          item.selectedVariant!['name'])
                                      : item.selectedVariant!['name'],
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            if (item.selectedOptions.isNotEmpty)
                              Text(
                                  item.selectedOptions
                                      .map((o) => s.isArabic
                                          ? (o['nameAr'] ?? o['name'])
                                          : o['name'])
                                      .join(', '),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.blueGrey)),
                          ],
                        ),
                      )),
                  const Divider(),
                  _priceRow(
                      s.subtotal, '${subtotal.toStringAsFixed(0)} ${s.egp}'),
                  _priceRow(
                      s.deliveryFee, '${deliveryFee.toStringAsFixed(0)} ${s.egp}'),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(s.total,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${total.toStringAsFixed(0)} ${s.egp}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: AppColors.primary)),
                      ]),
                ]),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _placeOrder(s, vendorItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                        '${s.placeOrder} (${total.toStringAsFixed(0)} ${s.egp})',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _paymentOption(String title, IconData icon, String val) {
    final isSelected = _selectedPayment == val;
    return ListTile(
      onTap: () => setState(() => _selectedPayment = val),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
      title: Text(title),
      trailing: Radio(
          value: val,
          groupValue: _selectedPayment,
          onChanged: (v) => setState(() => _selectedPayment = v as String),
          activeColor: AppColors.primary),
    );
  }

  Widget _priceRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(val,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
