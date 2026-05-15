import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/favorites_provider.dart';

class VendorCard extends ConsumerWidget {
  final Map<String, dynamic> vendor;

  const VendorCard({super.key, required this.vendor});

  Color _tagColor(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('أعلى') || t.contains('highest') || t.contains('top rated')) return Colors.amber.shade700;
    if (t.contains('بريميوم') || t.contains('premium')) return const Color(0xFF7B1FA2);
    if (t.contains('رائج') || t.contains('trending')) return Colors.blue.shade600;
    if (t.contains('جديد') || t.contains('new')) return Colors.teal;
    if (t.contains('عرض') || t.contains('deal') || t.contains('offer')) return Colors.red;
    if (t.contains('صحي') || t.contains('healthy')) return Colors.green.shade600;
    if (t.contains('محلي') || t.contains('local') || t.contains('مفضل')) return AppColors.primary;
    if (t.contains('موثوق') || t.contains('trusted')) return Colors.indigo;
    if (t.contains('طازج') || t.contains('fresh')) return Colors.green.shade700;
    return AppColors.primary;
  }

  Widget _chip(IconData icon, String label, {Color? textColor}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: textColor ?? Colors.grey.shade600),
      const SizedBox(width: 4),
      Text(
        label, 
        style: TextStyle(
          color: textColor ?? Colors.grey.shade700, 
          fontSize: 12, 
          fontWeight: FontWeight.w600
        ), 
      ),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = vendor['tag'] as String? ?? '';
    final favorites = ref.watch(favoritesProvider);
    final vendorId = vendor['id']?.toString() ?? '';
    final isFav = favorites.contains(vendorId);
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('/vendor', extra: vendor),
          borderRadius: BorderRadius.circular(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: (vendor['image']?.toString().isEmpty ?? true)
                    ? Container(height: 160, color: Theme.of(context).canvasColor, child: const Icon(Icons.storefront, size: 40, color: Colors.grey))
                    : CachedNetworkImage(
                        imageUrl: ImageUtils.formatImageUrl(vendor['image'] as String?),
                        height: 160, width: double.infinity, fit: BoxFit.cover,
                        placeholder: (c, u) => Container(height: 160, color: Theme.of(context).canvasColor),
                        errorWidget: (c, u, e) => Container(height: 160, color: Theme.of(context).canvasColor, child: const Icon(Icons.storefront, size: 40, color: Colors.grey)),
                      ),
              ),
              if (tag.isNotEmpty)
                Positioned(
                  top: 12, left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _tagColor(tag), borderRadius: BorderRadius.circular(20)),
                    child: Text(tag, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              Positioned(
                top: 8, right: 8,
                child: CircleAvatar(
                  radius: 18, backgroundColor: Theme.of(context).cardColor,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey, size: 16),
                    onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(vendorId),
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Builder(builder: (context) {
                final isAr = Localizations.localeOf(context).languageCode == 'ar';
                final name = isAr && vendor['nameAr'] != null && vendor['nameAr'].toString().isNotEmpty
                    ? vendor['nameAr'] as String
                    : vendor['name'] as String;
                final description = isAr && vendor['vendorAr'] != null && vendor['vendorAr'].toString().isNotEmpty
                    ? vendor['vendorAr'] as String
                    : vendor['vendor'] as String;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(name, style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: -0.5,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Builder(builder: (context) {
                        double rating = double.tryParse(vendor['rating']?.toString() ?? '0') ?? 0.0;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            if (index < rating.floor()) {
                              return const Icon(Icons.star_rounded, color: Colors.amber, size: 18);
                            } else if (index < rating) {
                              return const Icon(Icons.star_half_rounded, color: Colors.amber, size: 18);
                            } else {
                              return Icon(Icons.star_rounded, color: Colors.grey.shade300, size: 18);
                            }
                          }),
                        );
                      }),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      description, 
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey.shade700, 
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Text(
                          strings.orderShort,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}
