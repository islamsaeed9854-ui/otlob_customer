import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../providers/vendor_detail_controller.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;
  const VendorDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  String _selectedCategory = 'all';
  bool _initialProductShown = false;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cartState = ref.watch(cartProvider);
    
    final vendorId = widget.restaurant['id']?.toString() ?? '';
    final detailAsync = ref.watch(vendorDetailControllerProvider(vendorId));

    return detailAsync.when(
      data: (fullVendor) {
        final isPharmacy = fullVendor['type'] == 'pharmacy';
        final allMenu = (fullVendor['menu'] as List<dynamic>?) ?? [];

        final initialProductId = widget.restaurant['productId'];
        if (!_initialProductShown && initialProductId != null && allMenu.isNotEmpty) {
          final item = allMenu.where((i) => i['id']?.toString() == initialProductId.toString()).firstOrNull;
          if (item != null) {
            _initialProductShown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showProductBottomSheet(context, ref, item as Map<String, dynamic>, ref.read(cartProvider), s);
            });
          }
        }
        
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
                  background: (fullVendor['image']?.toString().isEmpty ?? true)
                      ? Container(color: Colors.grey.shade200, child: const Icon(Icons.restaurant, size: 48, color: Colors.grey))
                      : CachedNetworkImage(
                          imageUrl: ImageUtils.formatImageUrl(fullVendor['image'] as String?),
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
                  child: Builder(builder: (context) {
                    final isAr = Localizations.localeOf(context).languageCode == 'ar';
                    final name = isAr && fullVendor['nameAr'] != null && fullVendor['nameAr'].toString().isNotEmpty
                        ? fullVendor['nameAr'] as String
                        : fullVendor['name'] as String;
                    final description = isAr && fullVendor['vendorAr'] != null && fullVendor['vendorAr'].toString().isNotEmpty
                        ? fullVendor['vendorAr'] as String
                        : fullVendor['vendor'] as String;

                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        Row(children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('${fullVendor['rating']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                      ]),
                      const SizedBox(height: 4),
                      Text(description, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      const SizedBox(height: 12),
                      Row(children: [
                        _chip(Icons.access_time_rounded, fullVendor['deliveryTime']?.toString() ?? ''),
                        const SizedBox(width: 12),
                        _chip(Icons.delivery_dining, fullVendor['deliveryFee']?.toString() ?? ''),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 42,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/chat/vendor/${fullVendor['id']}', extra: {'title': name}),
                          icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary),
                          label: Text(
                            s.chatWithVendor,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: AppColors.primary.withOpacity(0.08),
                          ),
                        ),
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
                    ]);
                  }),
                ),
              ),

              if (isPharmacy)
                SliverToBoxAdapter(
                  child: _buildPharmacyCategories(s, isDark),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Text(
                    isPharmacy ? s.products : s.menu, 
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
                            s.noItemsInCategory,
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
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cartState.totalItems}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                Text(s.viewCart, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                              ],
                            ),
                          ),
                          Text(
                            '${cartState.getVendorSubtotal(fullVendor['id'] ?? '').toStringAsFixed(0)} ${s.egp}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${s.errorPrefix}${err.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(vendorDetailControllerProvider(vendorId)),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPharmacyCategories(AppStrings s, bool isDark) {
    final categories = [
      {'id': 'all', 'label': s.catAll, 'icon': Icons.grid_view_rounded},
      {'id': 'medicines', 'label': s.catMedicines, 'icon': Icons.healing_rounded},
      {'id': 'cosmetics', 'label': s.catCosmetics, 'icon': Icons.face_retouching_natural_rounded},
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
                Icon(cat['icon'] as IconData, size: 24, color: isSelected ? Colors.white : Colors.grey),
                const SizedBox(width: 8),
                Text(cat['label'] as String, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87), fontWeight: FontWeight.bold)),
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

    return GestureDetector(
      onTap: () => _showProductBottomSheet(context, ref, item, cartState, s),
      child: Container(
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
              : CachedNetworkImage(imageUrl: ImageUtils.formatImageUrl(item['image'] as String?), width: 100, height: 110, fit: BoxFit.cover),
        ),
        Expanded(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Builder(builder: (context) {
              final isAr = Localizations.localeOf(context).languageCode == 'ar';
              final name = isAr && item['nameAr'] != null && item['nameAr'].toString().isNotEmpty
                  ? item['nameAr'] as String
                  : item['name'] as String;
              final description = isAr && item['descriptionAr'] != null && item['descriptionAr'].toString().isNotEmpty
                  ? item['descriptionAr'] as String
                  : item['description'] as String? ?? '';

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey.shade500, fontSize: 11), maxLines: 2),
              ]);
            }),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${item['price']} ${s.egp}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
              qty == 0 ? _addButton(ref, item, s) : _qtyControl(ref, item, qty),
            ]),
          ]),
        )),
      ]),
    ),
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


  void _showProductBottomSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> item, CartState cartState, AppStrings s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentCartItem = ref.watch(cartProvider).allItems.where((ci) => ci.product['id'] == item['id']).firstOrNull;
            final currentQty = currentCartItem?.quantity ?? 0;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: (item['image']?.toString().isEmpty ?? true)
                                ? Container(
                                    width: double.infinity,
                                    height: 250,
                                    color: Colors.grey.shade100,
                                    child: Icon(Icons.fastfood_rounded, size: 80, color: Colors.grey.shade300),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: ImageUtils.formatImageUrl(item['image'] as String?),
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(height: 24),
                          Builder(builder: (context) {
                            final isAr = Localizations.localeOf(context).languageCode == 'ar';
                            final name = isAr && item['nameAr'] != null && item['nameAr'].toString().isNotEmpty
                                ? item['nameAr'] as String
                                : item['name'] as String;
                            final description = isAr && item['descriptionAr'] != null && item['descriptionAr'].toString().isNotEmpty
                                ? item['descriptionAr'] as String
                                : item['description'] as String? ?? '';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                      ),
                                    ),
                                    Text(
                                      '${item['price']} ${s.egp}',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  description,
                                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6),
                                ),
                              ],
                            );
                          }),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                      ],
                    ),
                    child: currentQty == 0
                        ? ElevatedButton(
                            onPressed: () {
                              ref.read(cartProvider.notifier).addItem({
                                ...item,
                                'vendorId': widget.restaurant['id'],
                                'vendorName': widget.restaurant['name'],
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: Text(s.addToCart, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                                        onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item['id'], currentQty - 1),
                                      ),
                                      Text(
                                        '$currentQty',
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                        onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item['id'], currentQty + 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 60),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    elevation: 0,
                                  ),
                                  child: Text(s.done, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
