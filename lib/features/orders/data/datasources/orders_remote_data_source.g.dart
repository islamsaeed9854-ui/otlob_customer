// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_remote_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ordersRemoteDataSource)
final ordersRemoteDataSourceProvider = OrdersRemoteDataSourceProvider._();

final class OrdersRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          OrdersRemoteDataSource,
          OrdersRemoteDataSource,
          OrdersRemoteDataSource
        >
    with $Provider<OrdersRemoteDataSource> {
  OrdersRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ordersRemoteDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ordersRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<OrdersRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OrdersRemoteDataSource create(Ref ref) {
    return ordersRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrdersRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OrdersRemoteDataSource>(value),
    );
  }
}

String _$ordersRemoteDataSourceHash() =>
    r'ffba1914715b9b5d327c226004ea4fa2be954769';
