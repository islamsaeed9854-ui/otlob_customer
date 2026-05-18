import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/cart/presentation/providers/cart_controller.dart';
import '../theme/app_colors.dart';
import '../l10n/app_strings.dart';

class FloatingCartOverlay extends ConsumerStatefulWidget {
  const FloatingCartOverlay({super.key});

  @override
  ConsumerState<FloatingCartOverlay> createState() => _FloatingCartOverlayState();
}

class _FloatingCartOverlayState extends ConsumerState<FloatingCartOverlay> {
  Offset? _offset;
  bool _isInitialized = false;
  bool _isDragging = false;
  bool _isOverTrash = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      final bottomPadding = MediaQuery.of(context).padding.bottom;
      // Initial position: centered at the bottom, above the nav bar
      _offset = Offset(size.width * 0.1, size.height - bottomPadding - 140);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    if (cartState.totalItems == 0) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double totalCartPrice = 0;
    for (final vendorItems in cartState.vendorBaskets.values) {
      for (final item in vendorItems) {
        totalCartPrice += item.totalPrice;
      }
    }

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Draggable Floating Cart Button
          Positioned(
            left: _offset?.dx,
            top: _offset?.dy,
            child: GestureDetector(
              onPanStart: (_) {
                setState(() {
                  _isDragging = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _offset = (_offset ?? Offset.zero) + details.delta;
                  
                  // Constrain within screen bounds
                  double x = _offset!.dx.clamp(16.0, size.width - 200.0);
                  double y = _offset!.dy.clamp(80.0, size.height - 100.0);
                  _offset = Offset(x, y);

                  // Collision Detection with bottom-center Trash Bin
                  final trashX = size.width / 2;
                  final trashY = size.height - bottomPadding - 80;
                  final buttonCenterX = _offset!.dx + 90; // Approx half of button width (180)
                  final buttonCenterY = _offset!.dy + 27; // Half of button height (54)

                  final distance = sqrt(pow(buttonCenterX - trashX, 2) + pow(buttonCenterY - trashY, 2));
                  _isOverTrash = distance < 80.0;
                });
              },
              onPanEnd: (_) async {
                if (_isOverTrash) {
                  // Clear all baskets
                  final vendorIds = List<String>.from(cartState.vendorBaskets.keys);
                  for (final vId in vendorIds) {
                    await ref.read(cartProvider.notifier).clearVendorCart(vId);
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(s.isArabic ? 'تم تفريغ السلة بنجاح!' : 'Cart cleared successfully!'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                }
                
                setState(() {
                  _isDragging = false;
                  _isOverTrash = false;
                });
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _isOverTrash ? 0.4 : 1.0,
                child: AnimatedScale(
                  scale: _isOverTrash ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Material(
                    color: Colors.transparent,
                    child: GestureDetector(
                      onTap: () => context.push('/cart'),
                      child: Container(
                        height: 54,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${cartState.totalItems} ${s.cartButton} • ${totalCartPrice.toStringAsFixed(0)}${s.egp}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.shopping_cart_rounded, color: Colors.black, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 2. Animated Bottom Center Trash Bin
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            bottom: _isDragging ? bottomPadding + 30 : -100,
            left: (size.width / 2) - 30,
            child: AnimatedScale(
              scale: _isOverTrash ? 1.25 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _isOverTrash 
                      ? Colors.red.withOpacity(0.9) 
                      : (isDark ? const Color(0xFF2C2C2C).withOpacity(0.8) : Colors.white.withOpacity(0.9)),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isOverTrash 
                          ? Colors.red.withOpacity(0.4) 
                          : Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: _isOverTrash ? 5 : 1,
                    ),
                  ],
                  border: Border.all(
                    color: _isOverTrash 
                        ? Colors.red.shade300 
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isOverTrash ? LucideIcons.trash2 : LucideIcons.trash,
                    color: _isOverTrash 
                        ? Colors.white 
                        : (isDark ? Colors.white60 : Colors.grey.shade600),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
