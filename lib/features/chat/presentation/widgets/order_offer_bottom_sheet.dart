import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../cart/presentation/providers/cart_controller.dart';

class OrderOfferBottomSheet extends ConsumerWidget {
  final Map<String, dynamic> product;
  final String vendorId;
  final String vendorName;

  const OrderOfferBottomSheet({
    super.key,
    required this.product,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    final name = isAr && product['nameAr'] != null && product['nameAr'].toString().isNotEmpty
        ? product['nameAr'] as String
        : product['name'] as String;
    
    final description = isAr && product['descriptionAr'] != null && product['descriptionAr'].toString().isNotEmpty
        ? product['descriptionAr'] as String
        : product['description'] as String? ?? '';
    
    final price = product['price'];
    final image = product['image'];

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
                    child: (image == null || image.toString().isEmpty)
                        ? Container(
                            width: double.infinity,
                            height: 250,
                            color: Colors.grey.shade100,
                            child: Icon(Icons.fastfood_rounded, size: 80, color: Colors.grey.shade300),
                          )
                        : Container(
                            width: double.infinity,
                            height: 250,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                            child: CachedNetworkImage(
                              imageUrl: ImageUtils.formatImageUrl(image as String?),
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
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
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87
                          ),
                        ),
                      ),
                      Text(
                        '$price ${s.egp}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 15, 
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.grey.shade600, 
                      height: 1.6
                    ),
                  ),
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
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      side: const BorderSide(color: Colors.grey, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(s.cancelOrder, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem({
                        ...product,
                        'vendorId': vendorId,
                        'vendorName': vendorName,
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.addedToCart)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: Text(s.confirmOrder, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
