import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/widgets/floating_cart_overlay.dart';
import '../providers/home_controller.dart';
import '../providers/discovery_search_controller.dart';
import '../widgets/vendor_card.dart';

class AllVendorsScreen extends ConsumerStatefulWidget {
  final String type;
  const AllVendorsScreen({super.key, required this.type});

  @override
  ConsumerState<AllVendorsScreen> createState() => _AllVendorsScreenState();
}

class _AllVendorsScreenState extends ConsumerState<AllVendorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeState = ref.watch(homeControllerProvider);

    String title = widget.type == 'all' ? s.allStores : s.stores;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: Stack(
        children: [
          homeState.when(
            data: (data) {
              final allVendors = data.products;
              final categoryVendors = widget.type == 'all'
                  ? allVendors
                  : allVendors.where((v) => v['type'] == widget.type).toList();

              // Resolve dynamic title from categories data
              if (widget.type != 'all') {
                final cat = data.categories.where((c) => c['type'] == widget.type).firstOrNull;
                if (cat != null) {
                  title = (s.isArabic && cat['nameAr'] != null) ? cat['nameAr'] : cat['name'];
                }
              }

              // Search results from Discovery Search
              final discoverySearch = _searchQuery.isEmpty 
                  ? null 
                  : ref.watch(discoverySearchControllerProvider(
                      (query: _searchQuery, 
                       verticalId: widget.type == 'all' ? null : data.categories.where((c) => c['type'] == widget.type).firstOrNull?['id'])
                    ));

              final filtered = categoryVendors.where((v) {
                final name = (v['name'] as String? ?? '').toLowerCase();
                return name.contains(_searchQuery.toLowerCase());
              }).toList();

              final suggestions = List.from(categoryVendors)
                ..sort((a, b) => (b['rating'] ?? 0).compareTo(a['rating'] ?? 0));
              final topSuggestions = suggestions.take(5).toList();

              return CustomScrollView(
                slivers: [
                  _buildAppBar(title, isDark),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildSearchBar(s, isDark),
                    ),
                  ),
                  if (_searchQuery.isEmpty && topSuggestions.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSuggestionsSection(s, topSuggestions, isDark),
                    ),
                  ],
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        _searchQuery.isEmpty ? s.allResults : s.searchResults,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) 
                    discoverySearch!.when(
                      data: (results) {
                        if (results.isEmpty) {
                          return SliverFillRemaining(
                            child: _buildEmptyState(s),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.only(bottom: 32),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildDiscoveryResultCard(s, results[index], isDark),
                              childCount: results.length,
                            ),
                          ),
                        );
                      },
                      loading: () => const SliverToBoxAdapter(
                        child: Center(child: Padding(padding: EdgeInsets.all(64), child: CircularProgressIndicator())),
                      ),
                      error: (e, st) => SliverToBoxAdapter(
                        child: Center(child: Text('${s.searchErrorPrefix}$e', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(s),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: VendorCard(vendor: filtered[index]),
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('${s.errorPrefix}$e', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
          ),
          const FloatingCartOverlay(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppStrings s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(s.noResults, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildDiscoveryResultCard(AppStrings s, Map<String, dynamic> v, bool isDark) {
    final products = v['matchingProducts'] as List<dynamic>? ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => context.push('/vendor', extra: v),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: 'https://api.otlob-egy.online${v['image']}',
                      width: 50, height: 50, fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(color: Colors.grey.shade200, child: const Icon(Icons.storefront, size: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (v['tag'] == 'Premium' || v['tag'] == 'Top Rated')
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.purple.shade700, borderRadius: BorderRadius.circular(4)),
                                  child: Text(AppStrings.of(context).proLabel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            Expanded(
                              child: Text(v['name'] ?? '',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(v['deliveryTime'] ?? '30 mins', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text('${v['rating'] ?? '4.5'}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),

          // Horizontal Product List
          if (products.isNotEmpty)
            SizedBox(
              height: 195,
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                itemBuilder: (context, idx) {
                  final p = products[idx];
                  return _buildDiscoveryProductCard(s, v, p, isDark);
                },
              ),
            ),
          
          if (products.isEmpty)
             Padding(
               padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
               child: Text(s.clickToViewMenu, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
             ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryProductCard(AppStrings s, Map<String, dynamic> vendor, dynamic p, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/vendor', extra: {
        ...vendor,
        'productId': p['id']?.toString(),
      }),
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: (p['image']?.toString().isNotEmpty ?? false)
                        ? 'https://api.otlob-egy.online${p['image']}'
                        : 'https://via.placeholder.com/150',
                    height: 120, width: 150, fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 8, right: 8,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${s.egp} ${p['price']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(String title, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
      ),
    );
  }

  Widget _buildSearchBar(AppStrings s, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: s.searchInStores,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(AppStrings s, List<dynamic> topSuggestions, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.featuredSuggestions,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
              ),
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topSuggestions.length,
            itemBuilder: (context, index) {
              final v = topSuggestions[index];
              return _buildSuggestionCard(v, isDark);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSuggestionCard(dynamic v, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/vendor', extra: v),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: (v['image']?.toString().isNotEmpty ?? false)
                          ? 'https://api.otlob-egy.online${v['image']}'
                          : 'https://via.placeholder.com/160x100',
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${v['rating'] ?? 4.5}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v['name'] ?? 'Store',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v['deliveryTime']?.toString() ?? '20-30 min',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
