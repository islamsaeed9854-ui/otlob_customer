import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/widgets/custom_chat_icon.dart';

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
  bool _isFirstPromoSlide = true;

  late PageController _promoPageController;
  Timer? _promoTimer;
  int _currentPromoPage = 0;

  @override
  void initState() {
    super.initState();
    _promoPageController =
        PageController(initialPage: _currentPromoPage, viewportFraction: 1.0);
    _promoTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_isFirstPromoSlide) {
        _isFirstPromoSlide = false;
        return;
      }
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
          child: Builder(builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Container(
              color: isDark ? const Color(0xFF1C1C1C) : Theme.of(ctx).colorScheme.surface,
              child: _buildHeader(context),
            );
          }),
        ),
        SliverToBoxAdapter(
          child: _buildTopBanners(context, data),
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
                  _buildSearch(),
                  _buildMainCategoryTabs(data),
                ],
              ),
            );
          }),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildCustomCourierBanner()),
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
      child: Directionality(
        textDirection: TextDirection.ltr,
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
                    const Icon(Icons.near_me_rounded,
                        color: AppColors.primary, size: 14),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.stars_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '1,250',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
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
                    Icon(Icons.notifications_active_rounded,
                        size: 24, color: isDark ? Colors.white : AppColors.textPrimaryLight),
                    PositionedDirectional(
                      end: 2,
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
      ),
    );
  }

  Widget _buildSearch() {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          textAlign: TextAlign.start,
          decoration: InputDecoration(
            hintText: s.searchRestaurant,
            hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
            suffixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
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
              width: 96,
              height: 116,
              margin: const EdgeInsetsDirectional.only(end: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    context.push('/all-vendors', extra: cat['type'] as String);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : (isDark ? Colors.black26 : Colors.grey.shade100),
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
                                  ? Colors.black
                                  : (isDark ? Colors.white : Colors.black87),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: -0.5,
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
    final color = isSelected ? Colors.black : AppColors.primary;
    
    if (cat['type'] == 'all') {
      final realCategories = allCategories.where((c) => c['type'] != 'all').take(4).toList();
      
      return SizedBox(
        width: 72,
        height: 72,
        child: Center(
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              children: List.generate(realCategories.length, (index) {
                final c = realCategories[index];
                // Position 4 icons in a tight circular cluster
                final double radius = 16.0;
                
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
        width: 72,
        height: 72,
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
        errorWidget: (context, url, error) => Icon(_getFallbackIconData(type), color: color, size: 18),
      );
    }
    return Icon(_getFallbackIconData(type), color: color, size: 18);
  }

  IconData _getFallbackIconData(String type) {
    if (type.contains('restaurant')) return Icons.restaurant_rounded;
    if (type.contains('pharmacy')) return Icons.healing_rounded;
    if (type.contains('supermarket') || type.contains('market')) return Icons.shopping_bag_rounded;
    return Icons.category_rounded;
  }

  Widget _buildFallbackIcon(String type, Color color) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Center(
        child: Icon(_getFallbackIconData(type), color: color, size: 56),
      ),
    );
  }

  Widget _buildCustomCourierBanner() {
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Consumer(
        builder: (context, ref, child) {
          final platformSettings = ref.watch(platformSettingsProvider).value;
          final iconUrl = platformSettings?.deliveryBannerIconUrl ?? platformSettings?.motorcycleIconUrl;
          final String fullUrl = ImageUtils.formatImageUrl(iconUrl);

          return Container(
            height: 235,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
              image: iconUrl != null && iconUrl.isNotEmpty ? DecorationImage(
                image: CachedNetworkImageProvider(fullUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.darken,
                ),
              ) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    s.customDeliveryBannerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                      shadows: [Shadow(blurRadius: 12, color: Colors.black54)]
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.customDeliveryBannerSub,
                    maxLines: 3,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black26)]
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 140,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () => context.push('/custom-delivery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700), // Gold
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: Text(
                          s.orderNow,
                          style: const TextStyle(
                            fontSize: 15, 
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBanners(BuildContext context, HomeData data) {
    final s = AppStrings.of(context);
    final banners = data.promotions;
    final totalItems = banners.isEmpty ? 1 : (banners.length + 1);

    return Consumer(
      builder: (context, ref, child) {
        final platformSettings = ref.watch(platformSettingsProvider).value;
        final coverUrl = platformSettings?.homeCoverUrl;

        final coverImageWidget = Container(
          width: double.infinity,
          height: 160,
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

        if (banners.isEmpty) {
          return coverImageWidget;
        }

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _promoPageController,
                onPageChanged: (int page) {
                  setState(() => _currentPromoPage = page);
                },
                itemBuilder: (context, index) {
                  final actualIndex = index % totalItems;

                  if (actualIndex == 0) {
                    return coverImageWidget;
                  }

                  final b = banners[actualIndex - 1];
                  final palette = [
                    AppColors.primary,
                    const Color(0xFF7B1FA2),
                    const Color(0xFF1565C0),
                    const Color(0xFF2E7D32),
                  ];
                  final col = palette[(actualIndex - 1) % palette.length];
                  
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
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [col, col.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
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
                            PositionedDirectional(
                              top: 16,
                              end: 16,
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
                  );
                },
              ),
            ),
            if (totalItems > 1)
              Positioned(
                bottom: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalItems, (index) {
                    final isSelected = (_currentPromoPage % totalItems) == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: isSelected ? 20 : 6,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
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
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
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
              _buildNavItem(0, LucideIcons.home, LucideIcons.home, s.navHome, true),
              _buildNavItem(1, LucideIcons.messageSquare, LucideIcons.messageSquare, s.navChat, false),
              _buildNavItem(3, LucideIcons.shoppingBag, LucideIcons.shoppingBag, s.navOrders, false),
              _buildNavItem(4, LucideIcons.user, LucideIcons.user, s.navProfile, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, dynamic activeIcon, dynamic inactiveIcon, String label, bool isSelected) {
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
          index == 1 
            ? CustomChatIcon(size: 24, color: color)
            : Icon(isSelected ? activeIcon as IconData : inactiveIcon as IconData, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(
              color: color, 
              fontSize: 11, 
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
