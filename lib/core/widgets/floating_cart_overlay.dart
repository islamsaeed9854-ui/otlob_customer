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

    double totalCartPrice = 0;
    for (final vendorItems in cartState.vendorBaskets.values) {
      for (final item in vendorItems) {
        totalCartPrice += item.totalPrice;
      }
    }

    return Positioned(
      left: _offset?.dx,
      top: _offset?.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset = (_offset ?? Offset.zero) + details.delta;
            
            // Constrain within screen bounds
            double x = _offset!.dx.clamp(16.0, size.width - 200.0);
            double y = _offset!.dy.clamp(80.0, size.height - 100.0);
            _offset = Offset(x, y);
          });
        },
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
    );
  }
}
