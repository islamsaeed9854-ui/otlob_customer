import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/utils/image_utils.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/platform_settings_provider.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/home_controller.dart';
import '../providers/home_state.dart';
import '../widgets/vendor_card.dart';
import '../widgets/vendor_card.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedType = 'all';
  bool _isCourierExpanded = false;

  late PageController _promoPageController;
  Timer? _promoTimer;
  int _currentPromoPage = 1000;

  @override
  void initState() {
    super.initState();
    _promoPageController =
        PageController(initialPage: _currentPromoPage, viewportFraction: 0.85);
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_promoPageController.hasClients) {
        _currentPromoPage++;
        _promoPageController.animateToPage(
          _currentPromoPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _promoTimer?.cancel();
    _promoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: homeState.when(
          data: (data) => RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await ref.refresh(homeControllerProvider.future);
              await ref.refresh(platformSettingsProvider.future);
            },
            child: _buildBody(context, data),
          ),
          loading: () => _buildShimmer(),
          error: (error, _) => _buildError(error.toString()),
        ),
      ),
      bottomNavigationBar: homeState.maybeWhen(
        data: (data) => _buildBottomNav(context, data),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeData data) {
    final searchQuery = _searchController.text.toLowerCase();

    final filtered = data.products.where((v) {
      final matchType =
          _selectedType == 'all' ? true : v['type'] == _selectedType;
      final matchSearch = searchQuery.isEmpty ||
          (v['name'] as String).toLowerCase().contains(searchQuery) ||
          (v['vendor'] as String? ?? '').toLowerCase().contains(searchQuery);
      return matchType && matchSearch;
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Consumer(
            builder: (context, ref, child) {
              final platformSettings = ref.watch(platformSettingsProvider).value;
              final coverUrl = platformSettings?.homeCoverUrl;

              return Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: coverUrl != null && coverUrl.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(ImageUtils.formatImageUrl(coverUrl)),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.2), BlendMode.darken),
                        )
                      : DecorationImage(
                          image: const AssetImage('assets/home_cover.jpg'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.2), BlendMode.darken),
                        ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: Builder(builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1C) : Theme.of(ctx).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  _buildSearch(),
                  _buildMainCategoryTabs(data),
                ],
              ),
            );
          }),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildCustomCourierBanner()),
        SliverToBoxAdapter(child: _buildPromoBanners(data)),
        SliverToBoxAdapter(child: _buildSectionTitle(data)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: _buildVendorGrid(context, filtered),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ]),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(s.deliverTo,
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Text(s.locationName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      )),
                  const SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: isDark ? Colors.white70 : AppColors.textPrimaryLight),
                ]),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Stack(
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 24, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: s.searchRestaurant,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
          filled: true,
          fillColor: isDark ? const Color(0xFF383838) : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildMainCategoryTabs(HomeData data) {
    final s = AppStrings.of(context);
    final categories = data.categories;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(categories.length, (i) {
            final cat = categories[i];
            final isSelected = _selectedType == cat['type'];
            final String name = (s.isArabic && cat['nameAr'] != null)
                ? cat['nameAr']
                : cat['name'];

            return Container(
              width: 92,
              margin: const EdgeInsetsDirectional.only(end: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                        width: 1.5,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () {
                    context.push('/all-vendors', extra: cat['type'] as String);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: _buildCategoryIcon(cat, isSelected, categories),
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(Map<String, dynamic> cat, bool isSelected, List<dynamic> allCategories) {
    final color = isSelected ? Colors.white : AppColors.primary;
    
    if (cat['type'] == 'all') {
      final realCategories = allCategories.where((c) => c['type'] != 'all').take(4).toList();
      
      return SizedBox(
        width: 68,
        height: 68,
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            child: Stack(
              children: List.generate(realCategories.length, (index) {
                final c = realCategories[index];
                // Position 4 icons in a tight circular cluster
                final angles = [0.0, 1.57, 3.14, 4.71]; // Top-right, Bottom-right, Bottom-left, Top-left
                final double radius = 10.0;
                
                return Center(
                  child: Transform.translate(
                    offset: Offset(
                      radius * (index == 0 || index == 1 ? 1 : -1),
                      radius * (index == 1 || index == 2 ? 1 : -1),
                    ),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.5), width: 1),
                      ),
                      child: ClipOval(
                        child: _buildMiniCategoryIcon(c['type'], c['iconUrl'], color),
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
    
    if (cat['iconUrl'] != null && cat['iconUrl'].toString().isNotEmpty) {
      final fullUrl = ImageUtils.formatImageUrl(cat['iconUrl'] as String?);
      return SizedBox(
        width: 68,
        height: 68,
        child: CachedNetworkImage(
          imageUrl: fullUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          errorWidget: (context, url, error) => _buildFallbackIcon(cat['type'], color),
        ),
      );
    }
    
    return _buildFallbackIcon(cat['type'], color);
  }

  Widget _buildMiniCategoryIcon(String type, dynamic iconUrl, Color color) {
    if (iconUrl != null && iconUrl.toString().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: ImageUtils.formatImageUrl(iconUrl as String?),
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => Icon(_getFallbackIconData(type), color: color, size: 14),
      );
    }
    return Icon(_getFallbackIconData(type), color: color, size: 14);
  }

  IconData _getFallbackIconData(String type) {
    if (type.contains('restaurant')) return Icons.restaurant_rounded;
    if (type.contains('pharmacy')) return Icons.healing_rounded;
    if (type.contains('supermarket') || type.contains('market')) return Icons.shopping_bag_rounded;
    return Icons.category_rounded;
  }

  Widget _buildFallbackIcon(String type, Color color) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Center(
        child: Icon(_getFallbackIconData(type), color: color, size: 40),
      ),
    );
  }

  Widget _buildCustomCourierBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStrings.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/custom-delivery'),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.customDeliveryBannerTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Text(
                        s.customDeliveryBannerSub,
                        maxLines: _isCourierExpanded ? 10 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isCourierExpanded = !_isCourierExpanded);
                      },
                      child: Text(
                        _isCourierExpanded ? s.readLess : s.readMore,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Consumer(
                builder: (context, ref, child) {
                  final platformSettings = ref.watch(platformSettingsProvider).value;
                  final iconUrl = platformSettings?.deliveryBannerIconUrl ?? platformSettings?.motorcycleIconUrl;

                  return Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: iconUrl != null && iconUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CachedNetworkImage(
                              imageUrl: ImageUtils.formatImageUrl(iconUrl),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 28),
                              errorWidget: (context, url, error) => const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 28),
                            ),
                          )
                        : const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 28),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanners(HomeData data) {
    final s = AppStrings.of(context);
    final banners = data.promotions;
    if (banners.isEmpty) return const SizedBox.shrink();

    final palette = [
      AppColors.primary,
      const Color(0xFF7B1FA2),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _promoPageController,
              onPageChanged: (int page) {
                setState(() => _currentPromoPage = page);
              },
              itemBuilder: (context, index) {
                final actualIndex = index % banners.length;
                final b = banners[actualIndex];
                final col = palette[actualIndex % palette.length];
                
                final title = (s.isArabic && b['titleAr'] != null) ? b['titleAr'] : b['title'];
                final description = (s.isArabic && b['descriptionAr'] != null) ? b['descriptionAr'] : (b['description'] ?? '');
                
                final String imageUrl = b['imageUrl'] ?? '';
                final String fullUrl = imageUrl.startsWith('http') ? imageUrl : 'https://api.otlob-egy.online$imageUrl';

                final vendorId = b['vendorId']?.toString();
                final linkedVendor = vendorId != null 
                    ? data.products.where((v) => v['id']?.toString() == vendorId).firstOrNull 
                    : null;

                return GestureDetector(
                  onTap: () async {
                    if (b['type'] == 'VENDOR' || b['type'] == 'PRODUCT') {
                      final vendorId = b['vendorId']?.toString();
                      if (vendorId != null) {
                        context.push('/vendor', extra: {
                          'id': vendorId, 
                          'name': title,
                          'productId': b['type'] == 'PRODUCT' ? b['productId']?.toString() : null,
                        });
                      }
                    } else if (b['type'] == 'EXTERNAL_LINK') {
                      final url = b['externalUrl']?.toString();
                      if (url != null && url.isNotEmpty) {
                        final uri = Uri.tryParse(url);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      }
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _promoPageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_promoPageController.position.hasContentDimensions) {
                        value = _promoPageController.page! - index;
                        value = (1 - (value.abs() * 0.1)).clamp(0.0, 1.0);
                      }
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                            colors: [col, col.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        boxShadow: [
                          BoxShadow(color: col.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                        image: imageUrl.isNotEmpty ? DecorationImage(
                          image: NetworkImage(fullUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                              col.withOpacity(0.4), BlendMode.srcATop),
                        ) : null,
                      ),
                      child: Stack(
                        children: [
                          if (linkedVendor != null)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${linkedVendor['rating'] ?? '4.5'}',
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (linkedVendor != null) ...[
                                    Text(
                                      (linkedVendor['name'] ?? '').toString().toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(title,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          letterSpacing: -0.5,
                                          shadows: [Shadow(blurRadius: 12, color: Colors.black54)])),
                                  if (description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.95),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            shadows: const [Shadow(blurRadius: 8, color: Colors.black38)])),
                                  ],
                                ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final isSelected = (_currentPromoPage % banners.length) == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isSelected ? 20 : 6,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSectionTitle(HomeData data) {
    final s = AppStrings.of(context);
    
    String label = s.allStores;
    
    if (_selectedType != 'all') {
      try {
        final selectedCat = data.categories.firstWhere((c) => c['type'] == _selectedType);
        final String catName = (s.isArabic && selectedCat['nameAr'] != null)
            ? selectedCat['nameAr']
            : selectedCat['name'];
        
        label = '${s.nearbyPrefix}$catName${s.nearbySuffix}';
      } catch (_) {
        label = s.nearbyStores;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: () => context.push('/all-vendors', extra: _selectedType),
          child: Text(s.seeAll,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ),
      ]),
    );
  }

  Widget _buildVendorGrid(
      BuildContext context, List<Map<String, dynamic>> vendors) {
    if (vendors.isEmpty) {
      return SliverToBoxAdapter(
          child: Center(
              child: Column(children: [
        const SizedBox(height: 60),
        const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        Text(AppStrings.of(context).noResults,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
      ])));
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final vendor = vendors[index];
          return VendorCard(
              key: ValueKey('${_selectedType}_${vendor['id']}'),
              vendor: vendor);
        },
        childCount: vendors.length,
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
          onPressed: () => ref.refresh(homeControllerProvider),
          child: Text(AppStrings.of(context).retry)),
    ]));
  }

  Widget _buildShimmer() {
    return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
            3,
            (_) => Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 240,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18))),
                )));
  }

  Widget _buildBottomNav(BuildContext context, HomeData data) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_filled, Icons.home_outlined, s.navHome, true),
              _buildNavItem(1, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_outline_rounded, s.navChat, false),
              _buildNavItem(3, Icons.receipt_long, Icons.receipt_long_outlined, s.navOrders, false),
              _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, s.navProfile, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label, bool isSelected) {
    final color = isSelected ? AppColors.primary : Colors.grey;
    return InkWell(
      onTap: () {
        if (index == 1) context.push('/chat/support/0');
        if (index == 3) context.push('/orders');
        if (index == 4) context.push('/profile');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : inactiveIcon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
