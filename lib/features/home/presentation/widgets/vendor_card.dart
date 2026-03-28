import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
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

  Widget _chip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Colors.grey.shade500),
      const SizedBox(width: 3),
      Flexible(
        child: Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = vendor['tag'] as String? ?? '';
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(vendor['id'] as String);
    final strings = AppStrings.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () {}, // TODO: Navigate to vendor detail
          borderRadius: BorderRadius.circular(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Stack(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: (vendor['image']?.toString().isEmpty ?? true)
                    ? Container(height: 160, color: Theme.of(context).canvasColor, child: const Icon(Icons.storefront, size: 40, color: Colors.grey))
                    : CachedNetworkImage(
                        imageUrl: vendor['image'] as String,
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
                    child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              Positioned(
                top: 8, right: 8,
                child: CircleAvatar(
                  radius: 18, backgroundColor: Theme.of(context).cardColor,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey, size: 16),
                    onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(vendor['id'] as String),
                  ),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(vendor['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text('${vendor['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ]),
                ]),
                const SizedBox(height: 4),
                Text(vendor['vendor'] as String, style: TextStyle(color: Colors.grey.shade500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                Row(children: [
                  _chip(Icons.access_time_rounded, vendor['deliveryTime'] as String),
                  const SizedBox(width: 8),
                  Expanded(child: _chip(Icons.delivery_dining, vendor['deliveryFee'] as String)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Builder(builder: (ctx) => const Text('Order Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
