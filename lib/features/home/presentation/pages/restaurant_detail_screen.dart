import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../cart/presentation/providers/cart_controller.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartState = ref.watch(cartProvider);
    
    final isPharmacy = widget.restaurant['type'] == 'pharmacy';
    final allMenu = (widget.restaurant['menu'] as List<dynamic>?) ?? [];
    
    final filteredMenu = _selectedCategory == 'all' 
        ? allMenu 
        : allMenu.where((item) => (item as Map<String, dynamic>)['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: const Icon(Icons.arrow_back, size: 20, color: AppColors.primary),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: (widget.restaurant['image']?.toString().isEmpty ?? true)
                  ? Container(color: Colors.grey.shade200, child: const Icon(Icons.restaurant, size: 48, color: Colors.grey))
                  : CachedNetworkImage(
                      imageUrl: widget.restaurant['image'] as String,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => Container(color: Colors.grey.shade200),
                      errorWidget: (c, u, e) => Container(color: Colors.grey.shade200, child: const Icon(Icons.restaurant, size: 48, color: Colors.grey)),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(widget.restaurant['name'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${widget.restaurant['rating']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ]),
                const SizedBox(height: 4),
                Text(widget.restaurant['vendor'] as String, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                const SizedBox(height: 12),
                Row(children: [
                  _chip(Icons.access_time_rounded, widget.restaurant['deliveryTime'] as String),
                  const SizedBox(width: 12),
                  _chip(Icons.delivery_dining, widget.restaurant['deliveryFee'] as String),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  height: 42,
                  width: double.infinity,
                  child: Builder(builder: (ctx) {
                    final btnColor = AppColors.primary;
                    return OutlinedButton.icon(
                      onPressed: () => context.push('/chat/vendor/${widget.restaurant['id']}', extra: {'title': widget.restaurant['name']}),
                      icon: Icon(Icons.chat_bubble_outline, size: 16, color: btnColor),
                      label: Text(
                        s.chatWithVendor,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: btnColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: btnColor, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: btnColor.withOpacity(0.08),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      s.chatWithVendorSubtext,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),

          if (isPharmacy)
            SliverToBoxAdapter(
              child: _buildPharmacyCategories(s.isArabic, isDark),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                isPharmacy ? (s.isArabic ? 'المنتجات' : 'Products') : s.menu, 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ),

          if (filteredMenu.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        s.isArabic ? 'لا توجد منتجات في هذا القسم حالياً' : 'No items in this category currently',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildMenuItem(context, ref, filteredMenu[index] as Map<String, dynamic>, cartState, s),
                  childCount: filteredMenu.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      
      bottomNavigationBar: cartState.totalItems > 0
          ? Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
                ],
              ),
              child: ElevatedButton(
                onPressed: () => context.push('/cart'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${cartState.totalItems}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                        ),
                        Text(
                          '${cartState.getVendorSubtotal(widget.restaurant['id'] ?? '').toStringAsFixed(0)} EGP',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(s.viewCart, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPharmacyCategories(bool isArabic, bool isDark) {
    final categories = [
      {'id': 'all', 'label': isArabic ? 'الكل' : 'All', 'icon': Icons.grid_view_rounded},
      {'id': 'medicines', 'label': isArabic ? 'أدوية' : 'Medicines', 'icon': Icons.healing_rounded},
      {'id': 'cosmetics', 'label': isArabic ? 'مستحضرات تجميل' : 'Cosmetics', 'icon': Icons.face_retouching_natural_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['id'] as String),
            child: Container(
              margin: const EdgeInsetsDirectional.only(end: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? Colors.grey.shade800 : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
              ),
              child: Row(children: [
                Icon(cat['icon'] as IconData, size: 20, color: isSelected ? Colors.white : Colors.grey),
                const SizedBox(width: 8),
                Text(cat['label'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, WidgetRef ref, Map<String, dynamic> item, CartState cartState, AppStrings s) {
    final cartItem = cartState.allItems.where((ci) => ci.product['id'] == item['id']).firstOrNull;
    final qty = cartItem?.quantity ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
          child: (item['image']?.toString().isEmpty ?? true)
              ? Container(width: 100, height: 110, color: Colors.grey.shade200, child: const Icon(Icons.fastfood, color: Colors.grey))
              : CachedNetworkImage(imageUrl: item['image'] as String, width: 100, height: 110, fit: BoxFit.cover),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
            const SizedBox(height: 4),
            Text(item['description'] as String? ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 11), maxLines: 2),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${item['price']} EGP', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              qty == 0 ? _addButton(ref, item, s) : _qtyControl(ref, item, qty),
            ]),
          ]),
        )),
      ]),
    );
  }

  Widget _addButton(WidgetRef ref, Map<String, dynamic> item, AppStrings s) {
    return GestureDetector(
      onTap: () {
        ref.read(cartProvider.notifier).addItem({
          ...item,
          'vendorId': widget.restaurant['id'],
          'vendorName': widget.restaurant['name'],
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _qtyControl(WidgetRef ref, Map<String, dynamic> item, int qty) {
    return Container(
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.remove, color: Colors.white, size: 16), onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item['id'], qty - 1)),
        Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.add, color: Colors.white, size: 16), onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item['id'], qty + 1)),
      ]),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Colors.grey.shade500),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
    ]);
  }
}
