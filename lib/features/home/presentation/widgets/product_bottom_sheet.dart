import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../cart/presentation/providers/cart_controller.dart';

class ProductBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> restaurant;
  final String initialUnit;
  final AppStrings s;
  final bool isDark;

  const ProductBottomSheet({
    super.key,
    required this.item,
    required this.restaurant,
    required this.initialUnit,
    required this.s,
    required this.isDark,
  });

  @override
  ConsumerState<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends ConsumerState<ProductBottomSheet> {
  late String _selectedUnit;
  Map<String, dynamic>? _selectedVariant;
  final Map<String, List<Map<String, dynamic>>> _selectedOptions = {};

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
    
    final variants = widget.item['variants'] as List<dynamic>? ?? [];
    if (widget.item['hasVariants'] == true && variants.isNotEmpty) {
      _selectedVariant = variants.first as Map<String, dynamic>;
    }
    
    final productOptionGroups = widget.item['optionGroups'] as List<dynamic>? ?? [];
    for (final group in productOptionGroups) {
      _selectedOptions[group['id']] = [];
    }

    if (_selectedVariant != null) {
      final variantOptionGroups = _selectedVariant!['optionGroups'] as List<dynamic>? ?? [];
      for (final group in variantOptionGroups) {
        _selectedOptions[group['id']] = [];
      }
    }
  }

  bool _areOptionsEqual(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((o) => o['id']).toSet();
    final bIds = b.map((o) => o['id']).toSet();
    return aIds.containsAll(bIds);
  }

  void _toggleOption(Map<String, dynamic> group, Map<String, dynamic> option) {
    final groupId = group['id'];
    final maxSelect = group['maxSelect'] as int? ?? 1;
    final list = List<Map<String, dynamic>>.from(_selectedOptions[groupId] ?? []);
    
    final isSelected = list.any((o) => o['id'] == option['id']);
    
    setState(() {
      if (isSelected) {
        list.removeWhere((o) => o['id'] == option['id']);
      } else {
        if (maxSelect == 1) {
          list.clear();
          list.add(option);
        } else {
          if (list.length < maxSelect) {
            list.add(option);
          }
        }
      }
      _selectedOptions[groupId] = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final s = widget.s;
    final isDark = widget.isDark;

    final flatOptions = _selectedOptions.values.expand((list) => list).toList();

    final currentCartItem = ref.watch(cartProvider).allItems.where((ci) {
      return ci.product['id'] == item['id'] && 
             ci.selectedUnit == _selectedUnit &&
             ci.selectedVariant?['id'] == _selectedVariant?['id'] &&
             _areOptionsEqual(ci.selectedOptions, flatOptions);
    }).firstOrNull;
    
    final currentQty = currentCartItem?.quantity ?? 0;
    
    final bool supportsStrips = item['sellByStrip'] == true && item['stripsPerPackage'] != null;
    final int stripsCount = item['stripsPerPackage'] as int? ?? 1;

    double basePrice = 0.0;
    if (_selectedVariant != null) {
      final vp = _selectedVariant!['basePrice'];
      basePrice = double.tryParse(vp?.toString() ?? '0') ?? 0.0;
    } else {
      final p = item['price'] ?? item['basePrice'];
      basePrice = double.tryParse(p?.toString() ?? '0') ?? 0.0;
    }

    double currentUnitPrice = _selectedUnit == 'strip' ? (basePrice / stripsCount) : basePrice;
    
    for (final opt in flatOptions) {
      final op = opt['priceAdded'];
      currentUnitPrice += double.tryParse(op?.toString() ?? '0') ?? 0.0;
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final name = isAr && item['nameAr'] != null && item['nameAr'].toString().isNotEmpty
        ? item['nameAr'] as String
        : item['name'] as String;
    final description = isAr && item['descriptionAr'] != null && item['descriptionAr'].toString().isNotEmpty
        ? item['descriptionAr'] as String
        : item['description'] as String? ?? '';

    final variants = item['variants'] as List<dynamic>? ?? [];
    final productOptionGroups = item['optionGroups'] as List<dynamic>? ?? [];
    final variantOptionGroups = _selectedVariant?['optionGroups'] as List<dynamic>? ?? [];
    final optionGroups = [...productOptionGroups, ...variantOptionGroups];

    // Check if required options are met
    bool requiredMet = true;
    for (final group in optionGroups) {
      if (group['isRequired'] == true) {
        final minSelect = group['minSelect'] as int? ?? 1;
        final count = _selectedOptions[group['id']]?.length ?? 0;
        if (count < minSelect) {
          requiredMet = false;
          break;
        }
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
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
                  if (description.isNotEmpty) ...[
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
                              setState(() => _selectedUnit = 'package');
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
                              setState(() => _selectedUnit = 'strip');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (item['hasVariants'] == true && variants.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Select Variant',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...variants.map((v) {
                      final vName = isAr && v['nameAr'] != null && v['nameAr'].toString().isNotEmpty ? v['nameAr'] : v['name'];
                      final vPrice = double.tryParse(v['basePrice']?.toString() ?? '0') ?? 0.0;
                      return RadioListTile<String>(
                        title: Text(vName),
                        subtitle: Text('+${vPrice.toStringAsFixed(2)} ${s.egp}'),
                        value: v['id'],
                        groupValue: _selectedVariant?['id'],
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _selectedVariant = v as Map<String, dynamic>;
                            // Initialize new option groups if any
                            final vOptionGroups = v['optionGroups'] as List<dynamic>? ?? [];
                            for (final g in vOptionGroups) {
                              if (!_selectedOptions.containsKey(g['id'])) {
                                _selectedOptions[g['id']] = [];
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],

                  if (optionGroups.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...optionGroups.map((group) {
                      final gName = isAr && group['nameAr'] != null && group['nameAr'].toString().isNotEmpty ? group['nameAr'] : group['name'];
                      final options = group['options'] as List<dynamic>? ?? [];
                      final isRequired = group['isRequired'] == true;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                gName,
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              if (isRequired)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text('*', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...options.map((opt) {
                            final oName = isAr && opt['nameAr'] != null && opt['nameAr'].toString().isNotEmpty ? opt['nameAr'] : opt['name'];
                            final oPrice = double.tryParse(opt['priceAdded']?.toString() ?? '0') ?? 0.0;
                            final isSelected = (_selectedOptions[group['id']] ?? []).any((o) => o['id'] == opt['id']);
                            
                            return CheckboxListTile(
                              title: Text(oName),
                              subtitle: oPrice > 0 ? Text('+${oPrice.toStringAsFixed(2)} ${s.egp}') : null,
                              value: isSelected,
                              activeColor: AppColors.primary,
                              checkColor: Colors.black,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) => _toggleOption(group as Map<String, dynamic>, opt as Map<String, dynamic>),
                            );
                          }).toList(),
                        ],
                      );
                    }).toList(),
                  ],

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
                    onPressed: requiredMet ? () {
                      ref.read(cartProvider.notifier).addItem(
                        {
                          ...item,
                          'vendorId': widget.restaurant['id'],
                          'vendorName': widget.restaurant['name'],
                        }, 
                        unit: _selectedUnit,
                        variant: _selectedVariant,
                        options: flatOptions,
                      );
                    } : null,
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
                                onPressed: () => ref.read(cartProvider.notifier).updateQuantity(currentCartItem!, currentQty - 1),
                              ),
                              Text(
                                '$currentQty',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                onPressed: () => ref.read(cartProvider.notifier).updateQuantity(currentCartItem!, currentQty + 1),
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
                    ? Colors.black 
                    : (widget.isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${price.toStringAsFixed(2)} ${s.egp}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? Colors.black87 
                    : (widget.isDark ? Colors.white70 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
