import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/widgets/custom_chat_icon.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../cart/presentation/providers/cart_controller.dart';
import '../../../../core/widgets/floating_cart_overlay.dart';
import '../providers/vendor_detail_controller.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> restaurant;
  const VendorDetailScreen({super.key, required this.restaurant});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String _selectedUnit = 'package';
  bool _initialProductShown = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
              _showProductBottomSheet(context, ref, item as Map<String, dynamic>, ref.read(cartProvider), s, isDark);
            });
          }
        }
        
        final filteredMenu = allMenu.where((item) {
          final map = item as Map<String, dynamic>;
          final matchesCategory = _selectedCategory == 'all' || map['category'] == _selectedCategory;
          
          if (_searchQuery.isEmpty) return matchesCategory;

          final isAr = Localizations.localeOf(context).languageCode == 'ar';
          final name = (isAr ? (map['nameAr'] ?? map['name'] ?? '') : (map['name'] ?? '')).toString().toLowerCase();
          final description = (isAr ? (map['descriptionAr'] ?? map['description'] ?? '') : (map['description'] ?? '')).toString().toLowerCase();
          final searchLower = _searchQuery.toLowerCase();
          
          return matchesCategory && (name.contains(searchLower) || description.contains(searchLower));
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 240,
                    floating: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                          onPressed: () => context.pop(),
                        ),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          (fullVendor['image']?.toString().isEmpty ?? true)
                              ? Container(color: isDark ? const Color(0xFF252525) : Colors.grey.shade200, child: const Icon(Icons.restaurant, size: 48, color: Colors.grey))
                              : CachedNetworkImage(
                                  imageUrl: ImageUtils.formatImageUrl(fullVendor['image'] as String?),
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) => Container(color: isDark ? const Color(0xFF252525) : Colors.grey.shade200),
                                  errorWidget: (c, u, e) => Container(color: isDark ? const Color(0xFF252525) : Colors.grey.shade200, child: const Icon(Icons.restaurant, size: 48, color: Colors.grey)),
                                ),
                          // Dynamic gradient for better text/icon visibility
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.1),
                                  Theme.of(context).scaffoldBackgroundColor,
                                ],
                                stops: const [0.0, 0.3, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ],
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
                            Expanded(
                              child: Text(
                                name, 
                                style: TextStyle(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  color: isDark ? Colors.white : Colors.black,
                                ), 
                                overflow: TextOverflow.ellipsis
                              )
                            ),
                            Row(children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text('${fullVendor['rating']}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                            ]),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                            description, 
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87.withOpacity(0.7), 
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 46,
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/chat/vendor/${fullVendor['id']}', extra: {'title': name}),
                              icon: const CustomChatIcon(size: 18, color: AppColors.primary),
                              label: Text(
                                s.chatWithVendor,
                                style: const TextStyle(
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w900, 
                                  color: AppColors.primary,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                backgroundColor: AppColors.primary.withOpacity(0.08),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                s.chatWithVendorSubtext,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ]);
                      }),
                    ),
                  ),

                  if (fullVendor['categories'] != null && (fullVendor['categories'] as List).isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 20),
                        child: _buildCategoryList(fullVendor['categories'] as List<dynamic>, allMenu, s, isDark),
                      ),
                    ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPharmacy ? s.products : s.menu, 
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), 
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() => _searchQuery = value),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: s.search,
                                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500),
                                prefixIcon: Icon(Icons.search, size: 20, color: isDark ? AppColors.primary : Colors.grey),
                                suffixIcon: _searchQuery.isNotEmpty 
                                    ? IconButton(
                                        icon: Icon(Icons.clear, size: 18, color: isDark ? Colors.white70 : Colors.grey),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                          ),
                        ],
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
                          (context, index) => _buildMenuItem(context, ref, filteredMenu[index] as Map<String, dynamic>, cartState, s, isDark),
                          childCount: filteredMenu.length,
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
              FloatingCartOverlay(),
            ],
          ),
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

  Widget _buildCategoryList(List<dynamic> categories, List<dynamic> menuItems, AppStrings s, bool isDark) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    // Add "All" category at the beginning
    final allCategories = [
      {'id': 'all', 'name': s.catAll, 'nameAr': 'الكل', 'icon': Icons.grid_view_rounded},
      ...categories,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: allCategories.map((cat) {
          final catId = cat['id']?.toString() ?? '';
          final isSelected = _selectedCategory == catId;
          final label = isAr ? (cat['nameAr'] ?? cat['name'] ?? '') : (cat['name'] ?? '');
          
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = catId),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsetsDirectional.only(end: 12),
              width: 85,
              height: 110,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                  width: 1.5,
                ),
                boxShadow: isSelected 
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] 
                  : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: ClipOval(
                        child: catId == 'all' 
                          ? _buildAllCategoryIconCluster(categories, isSelected)
                          : (cat['iconUrl'] != null && cat['iconUrl'].toString().isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: ImageUtils.formatImageUrl(cat['iconUrl'] as String?),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Icon(
                                  Icons.category_rounded, 
                                  size: 32, 
                                  color: isSelected ? Colors.white : AppColors.primary
                                ),
                              )
                            : Icon(
                                (cat['icon'] as IconData?) ?? Icons.grid_view_rounded, 
                                size: 32, 
                                color: isSelected ? Colors.white : AppColors.primary
                              )),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      label, 
                      style: TextStyle(
                        color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87), 
                        fontWeight: FontWeight.w900, 
                        fontSize: 9.5,
                        letterSpacing: -0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllCategoryIconCluster(List<dynamic> categories, bool isSelected) {
    final previewItems = categories.where((c) => (c['iconUrl'] != null && c['iconUrl'].toString().isNotEmpty) || c['icon'] != null).take(4).toList();
    final color = isSelected ? Colors.black : AppColors.primary;
    
    if (previewItems.isEmpty) {
      return Icon(Icons.grid_view_rounded, size: 28, color: color);
    }

    return SizedBox(
      width: 72,
      height: 72,
      child: Center(
        child: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            children: List.generate(previewItems.length, (index) {
              final double radius = 16.0;
              final cat = previewItems[index] as Map<String, dynamic>;
              
              return Center(
                child: Transform.translate(
                  offset: Offset(
                    radius * (index == 0 || index == 1 ? 1 : -1),
                    radius * (index == 1 || index == 2 ? 1 : -1),
                  ),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.5), width: 1),
                    ),
                    child: ClipOval(
                      child: (cat['iconUrl'] != null && cat['iconUrl'].toString().isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: ImageUtils.formatImageUrl(cat['iconUrl'] as String?),
                            fit: BoxFit.contain,
                            errorWidget: (c, u, e) => Icon((cat['icon'] as IconData?) ?? Icons.category_rounded, size: 14, color: color),
                          )
                        : Icon((cat['icon'] as IconData?) ?? Icons.grid_view_rounded, size: 16, color: color),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, WidgetRef ref, Map<String, dynamic> item, CartState cartState, AppStrings s, bool isDark) {
    final cartItem = cartState.allItems.where((ci) => ci.product['id'] == item['id']).firstOrNull;
    final qty = cartItem?.quantity ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedUnit = 'package'); 
        _showProductBottomSheet(context, ref, item, cartState, s, isDark);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text(
                          name, 
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 15, 
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.5,
                          ), 
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description, 
                          style: TextStyle(
                            color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey.shade600, 
                            fontSize: 12,
                            height: 1.3,
                          ), 
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  Text(
                    '${item['price']} ${s.egp}', 
                    style: const TextStyle(
                      color: AppColors.primary, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: (item['image']?.toString().isEmpty ?? true)
                    ? Icon(Icons.fastfood, color: Colors.grey.shade400, size: 36)
                    : CachedNetworkImage(
                        imageUrl: ImageUtils.formatImageUrl(item['image'] as String?),
                        fit: BoxFit.contain,
                        width: 110,
                        height: 110,
                      ),
              ),
            ),
          ],
        ),
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
        }, unit: 'package');
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary, 
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _qtyControl(WidgetRef ref, Map<String, dynamic> item, int qty) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary, 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.remove_rounded, color: Colors.black, size: 18), 
            onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item['id'], qty - 1, unit: 'package')
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('$qty', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.add_rounded, color: Colors.black, size: 18), 
            onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item['id'], qty + 1, unit: 'package')
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Icon(icon, size: 14, color: isDark ? AppColors.primary : Colors.black54),
          const SizedBox(width: 6),
          Text(
            label, 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontSize: 12, 
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            )
          ),
        ],
      ),
    );
  }


  void _showProductBottomSheet(BuildContext context, WidgetRef ref, Map<String, dynamic> item, CartState cartState, AppStrings s, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer(
              builder: (context, ref, child) {
                final currentCartItem = ref.watch(cartProvider).allItems.where((ci) => 
                  ci.product['id'] == item['id'] && ci.selectedUnit == _selectedUnit).firstOrNull;
                final currentQty = currentCartItem?.quantity ?? 0;
                
                final bool supportsStrips = item['sellByStrip'] == true && item['stripsPerPackage'] != null;
                final double basePrice = double.tryParse(item['price']?.toString() ?? item['basePrice']?.toString() ?? '0') ?? 0.0;
                final int stripsCount = item['stripsPerPackage'] as int? ?? 1;
                final double currentUnitPrice = _selectedUnit == 'strip' ? (basePrice / stripsCount) : basePrice;

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
                                    : Container(
                                        width: double.infinity,
                                        height: 250,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: ImageUtils.formatImageUrl(item['image'] as String?),
                                            fit: BoxFit.contain,
                                            errorWidget: (context, url, error) => Icon(Icons.fastfood, size: 40, color: isDark ? Colors.white24 : Colors.grey.shade300),
                                          ),
                                        ),
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
                                            style: TextStyle(
                                              fontSize: 24, 
                                              fontWeight: FontWeight.w900, 
                                              letterSpacing: -0.5,
                                              color: isDark ? Colors.white : Colors.black,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${currentUnitPrice.toStringAsFixed(2)} ${s.egp}',
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                    if (supportsStrips) ...[
                                      const SizedBox(height: 24),
                                      Text(
                                        s.sellingUnit,
                                        style: TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildUnitOption(
                                              label: s.package,
                                              isSelected: _selectedUnit == 'package',
                                              price: basePrice,
                                              s: s,
                                              onTap: () {
                                                setSheetState(() => _selectedUnit = 'package');
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildUnitOption(
                                              label: s.strip,
                                              isSelected: _selectedUnit == 'strip',
                                              price: basePrice / stripsCount,
                                              s: s,
                                              onTap: () {
                                                setSheetState(() => _selectedUnit = 'strip');
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 15, 
                                        color: isDark ? Colors.white : Colors.grey.shade700, 
                                        height: 1.6
                                      ),
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
                                  }, unit: _selectedUnit);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.black,
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
                                            onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item['id'], currentQty - 1, unit: _selectedUnit),
                                          ),
                                          Text(
                                            '$currentQty',
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                            onPressed: () => ref.read(cartProvider.notifier).updateQuantity(item['id'], currentQty + 1, unit: _selectedUnit),
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
      },
    );
  }

  Widget _buildUnitOption({
    required String label,
    required bool isSelected,
    required double price,
    required AppStrings s,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? Colors.white 
                    : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${price.toStringAsFixed(2)} ${s.egp}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? Colors.white.withOpacity(0.9) 
                    : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
