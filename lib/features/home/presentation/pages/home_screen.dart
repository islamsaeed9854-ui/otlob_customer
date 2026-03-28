import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/home_controller.dart';
import '../providers/home_state.dart';
import '../widgets/vendor_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const _mainCategoryKeys = [
    {'key': 'all', 'icon': Icons.grid_view_rounded},
    {'key': 'restaurant', 'icon': Icons.restaurant_rounded},
    {'key': 'pharmacy', 'icon': Icons.local_pharmacy_rounded},
    {'key': 'supermarket', 'icon': Icons.shopping_bag_rounded},
  ];
  String _selectedType = 'all';

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
            onRefresh: () => ref.refresh(homeControllerProvider.future),
            child: _buildBody(context, data),
          ),
          loading: () => _buildShimmer(),
          error: (error, _) => _buildError(error.toString()),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/home_cover.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.2), BlendMode.darken),
              ),
            ),
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
                  _buildMainCategoryTabs(),
                ],
              ),
            );
          }),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildCustomCourierBanner()),
        SliverToBoxAdapter(child: _buildPromoBanners()),
        SliverToBoxAdapter(child: _buildSectionTitle()),
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

  Widget _buildMainCategoryTabs() {
    final s = AppStrings.of(context);
    final labels = [
      AppStrings.of(context).isArabic ? 'الكل' : 'All',
      s.restaurants,
      s.pharmacies,
      s.supermarkets
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_mainCategoryKeys.length, (i) {
            final cat = _mainCategoryKeys[i];
            final isSelected = _selectedType == cat['key'];

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
                  onTap: () => setState(() {
                    _selectedType = cat['key'] as String;
                    _searchController.clear();
                  }),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: isSelected ? Colors.white : AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            labels[i],
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

  Widget _buildCustomCourierBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = AppStrings.of(context);
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delivery_dining_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
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
                  Text(
                    s.customDeliveryBannerSub,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_back_ios_new_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanners() {
    final s = AppStrings.of(context);
    final banners = s.promoBanners;
    if (banners.isEmpty) return const SizedBox.shrink();

    final palette = [
      AppColors.primary,
      const Color(0xFF7B1FA2),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 140,
        child: PageView.builder(
          controller: _promoPageController,
          onPageChanged: (int page) {
            _currentPromoPage = page;
          },
          itemBuilder: (context, index) {
            final actualIndex = index % banners.length;
            final b = banners[actualIndex];
            final col = palette[actualIndex % palette.length];

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                    colors: [col, col.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                image: DecorationImage(
                  image: NetworkImage(b[2]),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      col.withOpacity(0.55), BlendMode.srcATop),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(b[0],
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black45)
                              ])),
                      const SizedBox(height: 4),
                      Text(b[1],
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12)),
                    ]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    final s = AppStrings.of(context);
    final label = _selectedType == 'all'
        ? (s.isArabic ? 'جميع المتاجر' : 'All Stores')
        : _selectedType == 'restaurant'
            ? s.nearbyRestaurants
            : _selectedType == 'pharmacy'
                ? s.availablePharm
                : s.nearbySuper;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(s.seeAll,
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
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

  Widget _buildBottomNav(BuildContext context) {
    final s = AppStrings.of(context);
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle:
          const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      elevation: 20,
      onTap: (index) {},
      items: [
        BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_filled),
            label: s.navHome),
        BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: s.navOrders),
        BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: const Icon(Icons.chat_bubble_rounded),
            label: s.navChat),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline_rounded),
            activeIcon: const Icon(Icons.person_rounded),
            label: s.navProfile),
      ],
    );
  }
}
