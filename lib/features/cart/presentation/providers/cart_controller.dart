import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/cart_remote_data_source.dart';

part 'cart_controller.g.dart';

class CartItem {
  final String? backendId;
  final Map<String, dynamic> product;
  final int quantity;
  final String selectedUnit; // 'package' or 'strip'
  final Map<String, dynamic>? selectedVariant;
  final List<Map<String, dynamic>> selectedOptions;

  CartItem({
    this.backendId,
    required this.product,
    required this.quantity,
    this.selectedUnit = 'package',
    this.selectedVariant,
    this.selectedOptions = const [],
  });

  double get totalPrice {
    double price = 0.0;
    
    if (selectedVariant != null) {
      final vPrice = selectedVariant!['basePrice'];
      price = vPrice is num ? vPrice.toDouble() : (double.tryParse(vPrice?.toString() ?? '0') ?? 0.0);
    } else {
      final p = product['price'] ?? product['basePrice'];
      price = p is num ? p.toDouble() : (double.tryParse(p?.toString() ?? '0') ?? 0.0);
    }
    
    if (selectedUnit == 'strip' && product['sellByStrip'] == true) {
      final stripsCount = product['stripsPerPackage'] as int? ?? 1;
      if (stripsCount > 0) {
        price = price / stripsCount;
      }
    }
    
    for (final opt in selectedOptions) {
      final optPrice = opt['priceAdded'];
      final p = optPrice is num ? optPrice.toDouble() : (double.tryParse(optPrice?.toString() ?? '0') ?? 0.0);
      price += p;
    }
    
    return price * quantity;
  }

  CartItem copyWith({
    String? backendId,
    Map<String, dynamic>? product,
    int? quantity,
    String? selectedUnit,
    Map<String, dynamic>? selectedVariant,
    List<Map<String, dynamic>>? selectedOptions,
  }) {
    return CartItem(
      backendId: backendId ?? this.backendId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }
}

class CartState {
  final Map<String, List<CartItem>> vendorBaskets;

  const CartState({required this.vendorBaskets});

  int get totalItems {
    int count = 0;
    for (final vendorItems in vendorBaskets.values) {
      for (final item in vendorItems) {
        count += item.quantity;
      }
    }
    return count;
  }

  List<CartItem> get allItems {
    return vendorBaskets.values.expand((items) => items).toList();
  }

  double getVendorSubtotal(String vendorId) {
    final basket = vendorBaskets[vendorId];
    if (basket == null) return 0.0;
    return basket.fold(
      0.0,
      (total, item) => total + item.totalPrice,
    );
  }
}

@Riverpod(keepAlive: true)
class Cart extends _$Cart {
  @override
  CartState build() {
    _loadCarts();
    return const CartState(vendorBaskets: {});
  }

  Future<void> _loadCarts() async {
    try {
      final remote = ref.read(cartRemoteDataSourceProvider);
      final carts = await remote.getMyCarts();
      
      final Map<String, List<CartItem>> baskets = {};
      
      for (final cartJson in carts) {
        final vendorId = cartJson['vendorId'] as String;
        final vendorJson = cartJson['vendor'] as Map<String, dynamic>?;
        final vendorName = vendorJson?['storeName'];
        final vendorNameAr = vendorJson?['storeNameAr'];
        final vendorLogo = vendorJson?['logo'];
        final vendorCoverImage = vendorJson?['coverImage'];
        final List<CartItem> items = [];
        
        for (final itemJson in cartJson['items']) {
          items.add(CartItem(
            backendId: itemJson['id'],
            product: {
              ...itemJson['product'],
              'vendorId': vendorId,
              'vendorName': vendorName,
              'vendorNameAr': vendorNameAr,
              'vendorLogo': vendorLogo,
              'vendorCoverImage': vendorCoverImage,
              'commissionRate': vendorJson?['commissionRate'],
              'isContracted': vendorJson?['isContracted'],
            },
            quantity: itemJson['quantity'],
            selectedUnit: 'package', 
            selectedVariant: itemJson['variant'],
            selectedOptions: List<Map<String, dynamic>>.from(itemJson['options']),
          ));
        }
        baskets[vendorId] = items;
      }
      
      state = CartState(vendorBaskets: baskets);
    } catch (e) {
      print('Error loading carts: $e');
    }
  }

  Future<void> addItem(
    Map<String, dynamic> product, {
    String unit = 'package',
    Map<String, dynamic>? variant,
    List<Map<String, dynamic>> options = const [],
  }) async {
    final vendorId = product['vendorId'] as String;
    
    try {
      final remote = ref.read(cartRemoteDataSourceProvider);
      final response = await remote.addItem(
        vendorId: vendorId,
        productId: product['id'],
        variantId: variant?['id'],
        quantity: 1,
        optionIds: options.map((o) => o['id'] as String).toList(),
      );
      
      final updatedCart = response['data'];
      final vendorJson = updatedCart['vendor'] as Map<String, dynamic>?;
      final vendorName = vendorJson?['storeName'];
      final vendorNameAr = vendorJson?['storeNameAr'];
      final vendorLogo = vendorJson?['logo'];
      final vendorCoverImage = vendorJson?['coverImage'];
      final List<CartItem> items = [];
      for (final itemJson in updatedCart['items']) {
        items.add(CartItem(
          backendId: itemJson['id'],
          product: {
            ...itemJson['product'],
            'vendorId': vendorId,
            'vendorName': vendorName,
            'vendorNameAr': vendorNameAr,
            'vendorLogo': vendorLogo,
            'vendorCoverImage': vendorCoverImage,
            'commissionRate': vendorJson?['commissionRate'],
            'isContracted': vendorJson?['isContracted'],
          },
          quantity: itemJson['quantity'],
          selectedUnit: unit, 
          selectedVariant: itemJson['variant'],
          selectedOptions: List<Map<String, dynamic>>.from(itemJson['options']),
        ));
      }
      
      final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
      currentBaskets[vendorId] = items;
      state = CartState(vendorBaskets: currentBaskets);
      
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  Future<void> updateQuantity(CartItem cartItem, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItemExact(cartItem);
      return;
    }

    String? vendorId = cartItem.product['vendorId'] as String?;
    if (vendorId == null) {
      for (final entry in state.vendorBaskets.entries) {
        if (entry.value.any((item) => item.backendId == cartItem.backendId || item.product['id'] == cartItem.product['id'])) {
          vendorId = entry.key;
          break;
        }
      }
    }
    if (vendorId == null || cartItem.backendId == null) return;

    try {
      final remote = ref.read(cartRemoteDataSourceProvider);
      final response = await remote.updateItem(
        vendorId: vendorId,
        cartItemId: cartItem.backendId!,
        quantity: newQuantity,
      );

      final updatedCart = response['data'];
      final vendorJson = updatedCart['vendor'] as Map<String, dynamic>?;
      final vendorName = vendorJson?['storeName'];
      final vendorNameAr = vendorJson?['storeNameAr'];
      final vendorLogo = vendorJson?['logo'];
      final vendorCoverImage = vendorJson?['coverImage'];
      final List<CartItem> items = [];
      for (final itemJson in updatedCart['items']) {
        items.add(CartItem(
          backendId: itemJson['id'],
          product: {
            ...itemJson['product'],
            'vendorId': vendorId,
            'vendorName': vendorName,
            'vendorNameAr': vendorNameAr,
            'vendorLogo': vendorLogo,
            'vendorCoverImage': vendorCoverImage,
            'commissionRate': vendorJson?['commissionRate'],
            'isContracted': vendorJson?['isContracted'],
          },
          quantity: itemJson['quantity'],
          selectedUnit: cartItem.selectedUnit, 
          selectedVariant: itemJson['variant'],
          selectedOptions: List<Map<String, dynamic>>.from(itemJson['options']),
        ));
      }

      final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
      currentBaskets[vendorId] = items;
      state = CartState(vendorBaskets: currentBaskets);
    } catch (e) {
      print('Error updating quantity: $e');
    }
  }

  Future<void> _removeItemExact(CartItem cartItem) async {
    String? vendorId = cartItem.product['vendorId'] as String?;
    if (vendorId == null) {
      for (final entry in state.vendorBaskets.entries) {
        if (entry.value.any((item) => item.backendId == cartItem.backendId || item.product['id'] == cartItem.product['id'])) {
          vendorId = entry.key;
          break;
        }
      }
    }
    if (vendorId == null || cartItem.backendId == null) return;

    try {
      final remote = ref.read(cartRemoteDataSourceProvider);
      await remote.removeItem(vendorId: vendorId, cartItemId: cartItem.backendId!);
      
      final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
      final vendorItems = List<CartItem>.from(currentBaskets[vendorId]!);
      
      vendorItems.removeWhere((item) => 
        (item.backendId != null && item.backendId == cartItem.backendId) || 
        (item.product['id'] == cartItem.product['id'] && 
         item.selectedVariant?['id'] == cartItem.selectedVariant?['id']));
      
      if (vendorItems.isEmpty) {
        currentBaskets.remove(vendorId);
      } else {
        currentBaskets[vendorId] = vendorItems;
      }
      
      state = CartState(vendorBaskets: currentBaskets);
    } catch (e) {
      print('Error removing item: $e');
    }
  }

  Future<void> clearVendorCart(String vendorId) async {
    try {
      final remote = ref.read(cartRemoteDataSourceProvider);
      await remote.clearCart(vendorId);
      
      final currentBaskets = Map<String, List<CartItem>>.from(state.vendorBaskets);
      currentBaskets.remove(vendorId);
      state = CartState(vendorBaskets: currentBaskets);
    } catch (e) {
      print('Error clearing vendor cart: $e');
    }
  }

  Future<void> clearCart() async {
    final vendorIds = state.vendorBaskets.keys.toList();
    for (final vendorId in vendorIds) {
      try {
        final remote = ref.read(cartRemoteDataSourceProvider);
        await remote.clearCart(vendorId);
      } catch (e) {
        print('Error clearing vendor cart $vendorId on remote: $e');
      }
    }
    state = const CartState(vendorBaskets: {});
  }
}
