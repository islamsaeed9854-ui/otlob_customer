import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/floating_cart_overlay.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../providers/orders_provider.dart';

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          s.navOrders,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
      body: Stack(
        children: [
          ordersAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, stack) => Center(child: Text(err.toString())),
            data: (orders) => orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          s.noResults,
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.white70
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _buildOrderCard(context, ref, order, s);
                    },
                  ),
          ),
          const FloatingCartOverlay(),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String status, bool isDark, AppStrings s) {
    if (status == 'CANCELLED') return const SizedBox.shrink();

    // 0: PENDING
    // 1: PREPARING, COOKING
    // 2: READY, OUT_FOR_DELIVERY, PICKED_UP
    // 3: DELIVERED
    int currentStep = 0;
    if (status == 'PREPARING' || status == 'COOKING') {
      currentStep = 1;
    } else if (status == 'READY' ||
        status == 'OUT_FOR_DELIVERY' ||
        status == 'PICKED_UP') {
      currentStep = 2;
    } else if (status == 'DELIVERED') {
      currentStep = 3;
    }

    final steps = s.isArabic
        ? ['تم الطلب', 'التحضير', 'في الطريق', 'تم التوصيل']
        : ['Placed', 'Preparing', 'On Way', 'Delivered'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(4, (index) {
          final isActive = index <= currentStep;
          final isCompleted = index < currentStep;
          final label = steps[index];

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2.5,
                        color: index == 0
                            ? Colors.transparent
                            : (isActive ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade200)),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.primary
                            : (isActive ? Colors.white : (isDark ? const Color(0xFF262626) : Colors.grey.shade100)),
                        border: Border.all(
                          color: isActive ? AppColors.primary : (isDark ? Colors.white24 : Colors.grey.shade300),
                          width: 2.5,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? AppColors.primary : Colors.transparent,
                                ),
                              ),
                            ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2.5,
                        color: index == 3
                            ? Colors.transparent
                            : (index < currentStep
                                ? AppColors.primary
                                : (isDark ? Colors.white10 : Colors.grey.shade200)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                    color: isActive
                        ? AppColors.primary
                        : (isDark ? Colors.white30 : Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, WidgetRef ref, Map<String, dynamic> order, AppStrings s) {
    final isCustom = order['type'] == 'custom_delivery';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final vendor = order['vendor'] as Map<String, dynamic>?;

    final vendorName = s.isArabic
        ? (vendor?['storeNameAr'] ?? vendor?['storeName'] ?? s.vendor)
        : (vendor?['storeName'] ?? s.vendor);
    final vendorLogoUrl = vendor?['logo'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subtotal = _parseDouble(order['subtotal']);
    final deliveryFee = _parseDouble(order['deliveryFee']);
    final serviceFee = _parseDouble(order['serviceFee']);
    final tax = _parseDouble(order['tax']);
    final discount = _parseDouble(order['discount']);
    final grandTotal = _parseDouble(order['grandTotal']);

    double total = grandTotal;
    if (total == 0.0) {
      if (isCustom) {
        total = _parseDouble(order['totalFee']);
      } else {
        double calcSubtotal = 0;
        for (var i in items) {
          final price = _parseDouble(i['price'] ?? i['unitPrice']);
          final q = i['quantity'];
          final quantity = q is int ? q : (int.tryParse(q?.toString() ?? '1') ?? 1);
          calcSubtotal += price * quantity;
        }
        total = calcSubtotal + deliveryFee + serviceFee + tax - discount;
      }
    }

    final status = order['status'] as String? ?? 'PENDING';
    Color statusColor = AppColors.primary;
    Color statusBgColor = AppColors.primary.withOpacity(0.1);

    if (status == 'DELIVERED') {
      statusColor = AppColors.success;
      statusBgColor = AppColors.success.withOpacity(0.1);
    } else if (status == 'CANCELLED') {
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
    } else if (status == 'PREPARING' || status == 'COOKING' || status == 'READY') {
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.withOpacity(0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (vendorLogoUrl == null || vendorLogoUrl.isEmpty)
                    ? Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            color: AppColors.primary, size: 20),
                      )
                    : CachedNetworkImage(
                        imageUrl: ImageUtils.formatImageUrl(vendorLogoUrl),
                        height: 42,
                        width: 42,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded,
                              color: AppColors.primary, size: 20),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCustom
                          ? s.customDeliveryTitle
                          : '${s.orderNo}${order['id'].toString().split('-').last.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          // Timeline Progress Tracker
          if (!isCustom) _buildStatusTimeline(status, isDark, s),

          const Divider(height: 20),

          // Items List
          if (isCustom) ...[
            Row(
              children: [
                const Icon(Icons.circle, size: 10, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.pickupLocation}: ${order['pickup']}',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${s.dropoffLocation}: ${order['dropoff']}',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ] else
            ...items.map((i) {
              final product = i['product'] as Map<String, dynamic>?;
              final productImgUrl = product?['imageUrl'] as String?;
              final productName = i['productName'] ?? i['name'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (productImgUrl == null || productImgUrl.isEmpty)
                          ? Container(
                              height: 32,
                              width: 32,
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade100,
                              child: const Icon(Icons.fastfood,
                                  size: 16, color: Colors.grey),
                            )
                          : CachedNetworkImage(
                              imageUrl:
                                  ImageUtils.formatImageUrl(productImgUrl),
                              height: 32,
                              width: 32,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${i['quantity']}x $productName',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '${_parseDouble(i['totalPrice']).toStringAsFixed(0)} ${s.egp}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const Divider(height: 24),

          // Pricing Breakdown to show transparency
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.subtotal,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${subtotal == 0.0 ? (total - deliveryFee - tax - serviceFee + discount) : subtotal} ${s.egp}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.deliveryFee,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      deliveryFee == 0
                          ? (s.isArabic ? 'مجاني' : 'Free')
                          : '${deliveryFee.toStringAsFixed(0)} ${s.egp}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: deliveryFee == 0 ? AppColors.success : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ],
                ),
                if (serviceFee > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.isArabic ? 'رسوم الخدمة' : 'Service Fee',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${serviceFee.toStringAsFixed(0)} ${s.egp}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
                if (tax > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.isArabic ? 'الضرائب والرسوم' : 'Taxes & Fees',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${tax.toStringAsFixed(0)} ${s.egp}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.isArabic ? 'الخصم' : 'Discount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '-${discount.toStringAsFixed(0)} ${s.egp}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 24),

          // Total Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.total,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                '${total.toStringAsFixed(0)} ${s.egp}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // Action buttons at the bottom of card
          if (!isCustom) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (status == 'PENDING') ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelBottomSheet(context, ref, order['id'], s, isDark),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        s.isArabic ? 'إلغاء الطلب' : 'Cancel Order',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleEditOrder(context, ref, order, s),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        s.isArabic ? 'تعديل الطلب' : 'Edit Order',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ] else if (status == 'DELIVERED' || status == 'CANCELLED') ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleReorder(context, ref, order, s),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.replay_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            s.isArabic ? 'إعادة طلب' : 'Reorder',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelBottomSheet(BuildContext context, WidgetRef ref, String orderId, AppStrings s, bool isDark) {
    String selectedReason = s.isArabic ? 'غيرت رأيي' : 'Change of mind';
    final customController = TextEditingController();
    bool showCustomField = false;
    bool isCancelling = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final reasons = s.isArabic
                ? ['غيرت رأيي', 'نسيت إضافة منتج', 'عنوان التوصيل خاطئ', 'وقت التحضير طويل جداً', 'أخرى']
                : ['Change of mind', 'Forgot to add item', 'Wrong delivery address', 'Prep time too long', 'Other'];

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.isArabic ? 'إلغاء الطلب' : 'Cancel Order',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.isArabic
                        ? 'يرجى اختيار سبب إلغاء طلبك لمساعدتنا على التحسن:'
                        : 'Please select a reason for cancelling your order:',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ...reasons.map((r) {
                    final isSelected = selectedReason == r;
                    return RadioListTile<String>(
                      title: Text(r, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal)),
                      value: r,
                      groupValue: selectedReason,
                      activeColor: Colors.red,
                      contentPadding: EdgeInsets.zero,
                      onChanged: isCancelling ? null : (val) {
                        setModalState(() {
                          selectedReason = val!;
                          showCustomField = val == (s.isArabic ? 'أخرى' : 'Other');
                        });
                      },
                    );
                  }),
                  if (showCustomField) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: customController,
                      enabled: !isCancelling,
                      decoration: InputDecoration(
                        hintText: s.isArabic ? 'اكتب سبب الإلغاء هنا...' : 'Enter cancellation reason here...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCancelling ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(s.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isCancelling
                              ? null
                              : () async {
                                  final finalReason = showCustomField ? customController.text : selectedReason;
                                  
                                  setModalState(() {
                                    isCancelling = true;
                                  });

                                  final success = await ref.read(ordersProvider.notifier).cancelOrder(orderId, finalReason);

                                  if (context.mounted) {
                                    Navigator.pop(context); // Pop sheet safely

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success
                                            ? (s.isArabic ? 'تم إلغاء الطلب بنجاح!' : 'Order cancelled successfully!')
                                            : (s.isArabic ? 'فشل إلغاء الطلب!' : 'Failed to cancel order!')),
                                        backgroundColor: success ? Colors.green : Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: isCancelling
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(s.isArabic ? 'تأكيد الإلغاء' : 'Confirm Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleEditOrder(BuildContext context, WidgetRef ref, Map<String, dynamic> order, AppStrings s) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(s.isArabic ? 'تعديل الطلب' : 'Edit Order', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          s.isArabic
              ? 'تعديل هذا الطلب سيؤدي إلى إلغائه وإعادة إضافة جميع عناصره إلى سلتك للتعديل عليها وإتمام الشراء مجدداً.\nهل تريد المتابعة؟'
              : 'Editing this order will cancel it and reload all its items back into your cart so you can modify them and checkout again.\nDo you want to continue?',
          style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade700, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(s.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    // 1. Cancel the order
    final cancelSuccess = await ref.read(ordersProvider.notifier).cancelOrder(order['id'], 'Editing order');
    if (!cancelSuccess) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isArabic ? 'فشل تعديل الطلب (فشل الإلغاء)!' : 'Failed to edit order (cancel failed)!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Clear & Add items to cart
    final vendor = order['vendor'] as Map<String, dynamic>?;
    final vendorId = (order['vendorId'] ?? vendor?['id']) as String?;
    if (vendorId == null) {
      print('ERROR: vendorId is null! order: $order');
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isArabic ? 'خطأ: معرف المتجر غير موجود' : 'Error: Store ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final vendorName = vendor?['storeName'] ?? '';
    final vendorNameAr = vendor?['storeNameAr'] ?? '';
    final vendorLogo = vendor?['logo'] ?? '';
    final items = order['items'] as List<dynamic>? ?? [];

    await ref.read(cartProvider.notifier).clearVendorCart(vendorId);

    for (final item in items) {
      final product = Map<String, dynamic>.from(item['product'] as Map? ?? {});
      product['id'] = item['productId'];
      product['name'] = item['productName'] ?? item['name'] ?? '';
      product['vendorId'] = vendorId;
      product['vendorName'] = vendorName;
      product['vendorNameAr'] = vendorNameAr;
      product['vendorLogo'] = vendorLogo;

      Map<String, dynamic>? variantMap;
      if (item['variantId'] != null) {
        variantMap = {
          'id': item['variantId'],
          'name': item['variantName'] ?? '',
        };
      }

      final List<Map<String, dynamic>> mappedOptions = [];
      if (item['options'] != null) {
        for (final opt in item['options']) {
          mappedOptions.add({
            'id': opt['optionId'] ?? opt['id'],
            'name': opt['optionName'] ?? opt['name'],
            'priceAdded': opt['priceAdded'],
          });
        }
      }

      await ref.read(cartProvider.notifier).addItem(
        product,
        variant: variantMap,
        options: mappedOptions,
      );

      final quantity = item['quantity'] is int
          ? item['quantity'] as int
          : (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1);

      if (quantity > 1) {
        final currentBasket = ref.read(cartProvider).vendorBaskets[vendorId] ?? [];
        final addedItemIndex = currentBasket.indexWhere(
          (i) => i.product['id'] == product['id'] && i.selectedVariant?['id'] == variantMap?['id'],
        );
        if (addedItemIndex != -1) {
          await ref.read(cartProvider.notifier).updateQuantity(currentBasket[addedItemIndex], quantity);
        }
      }
    }

    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.isArabic ? 'تم إلغاء الطلب وإعادة العناصر إلى السلة!' : 'Order cancelled and items added to cart!'),
        backgroundColor: Colors.green,
      ),
    );

    context.push('/cart');
  }

  Future<void> _handleReorder(BuildContext context, WidgetRef ref, Map<String, dynamic> order, AppStrings s) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final vendor = order['vendor'] as Map<String, dynamic>?;
    final vendorId = (order['vendorId'] ?? vendor?['id']) as String?;
    if (vendorId == null) {
      print('ERROR: vendorId is null! order: $order');
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.isArabic ? 'خطأ: معرف المتجر غير موجود' : 'Error: Store ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final vendorName = vendor?['storeName'] ?? '';
    final vendorNameAr = vendor?['storeNameAr'] ?? '';
    final vendorLogo = vendor?['logo'] ?? '';
    final items = order['items'] as List<dynamic>? ?? [];

    await ref.read(cartProvider.notifier).clearVendorCart(vendorId);

    for (final item in items) {
      final product = Map<String, dynamic>.from(item['product'] as Map? ?? {});
      product['id'] = item['productId'];
      product['name'] = item['productName'] ?? item['name'] ?? '';
      product['vendorId'] = vendorId;
      product['vendorName'] = vendorName;
      product['vendorNameAr'] = vendorNameAr;
      product['vendorLogo'] = vendorLogo;

      Map<String, dynamic>? variantMap;
      if (item['variantId'] != null) {
        variantMap = {
          'id': item['variantId'],
          'name': item['variantName'] ?? '',
        };
      }

      final List<Map<String, dynamic>> mappedOptions = [];
      if (item['options'] != null) {
        for (final opt in item['options']) {
          mappedOptions.add({
            'id': opt['optionId'] ?? opt['id'],
            'name': opt['optionName'] ?? opt['name'],
            'priceAdded': opt['priceAdded'],
          });
        }
      }

      await ref.read(cartProvider.notifier).addItem(
        product,
        variant: variantMap,
        options: mappedOptions,
      );

      final quantity = item['quantity'] is int
          ? item['quantity'] as int
          : (int.tryParse(item['quantity']?.toString() ?? '1') ?? 1);

      if (quantity > 1) {
        final currentBasket = ref.read(cartProvider).vendorBaskets[vendorId] ?? [];
        final addedItemIndex = currentBasket.indexWhere(
          (i) => i.product['id'] == product['id'] && i.selectedVariant?['id'] == variantMap?['id'],
        );
        if (addedItemIndex != -1) {
          await ref.read(cartProvider.notifier).updateQuantity(currentBasket[addedItemIndex], quantity);
        }
      }
    }

    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.isArabic ? 'تم إضافة عناصر الطلب إلى السلة!' : 'Order items added to cart!'),
        backgroundColor: Colors.green,
      ),
    );

    context.push('/cart');
  }
}
