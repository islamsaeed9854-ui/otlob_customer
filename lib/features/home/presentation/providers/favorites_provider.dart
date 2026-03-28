import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorites_provider.g.dart';

@riverpod
class Favorites extends _$Favorites {
  @override
  Set<String> build() {
    return {};
  }

  void toggleFavorite(String vendorId) {
    if (state.contains(vendorId)) {
      state = {...state}..remove(vendorId);
    } else {
      state = {...state, vendorId};
    }
  }
}
