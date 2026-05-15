import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../l10n/app_strings.dart';
import '../../features/cart/presentation/providers/cart_controller.dart';

class DraggableCartOverlay extends ConsumerStatefulWidget {
  const DraggableCartOverlay({super.key});

  @override
  ConsumerState<DraggableCartOverlay> createState() => _DraggableCartOverlayState();
}

class _DraggableCartOverlayState extends ConsumerState<DraggableCartOverlay> {
  Offset _offset = const Offset(16, 100); // Initial position from bottom-right
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      // Start at bottom center-ish
      _offset = Offset(size.width * 0.05, size.height - 160);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    if (cartState.totalItems == 0) return const SizedBox.shrink();

    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
            
            // Constrain within screen bounds
            double x = _offset.dx.clamp(16.0, size.width - 220.0);
            double y = _offset.dy.clamp(80.0, size.height - 100.0);
            _offset = Offset(x, y);
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 200,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: InkWell(
              onTap: () => context.push('/cart'),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${cartState.totalItems}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Icon(LucideIcons.shoppingBag, color: Colors.black, size: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.viewCart,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
