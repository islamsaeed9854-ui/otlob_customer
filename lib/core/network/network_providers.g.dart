// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(dio)
final dioProvider = DioProvider._();

final class DioProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
  DioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioHash() => r'b9a5bb19530285962b4e9962b49f478f68f6d035';

@ProviderFor(internetConnection)
final internetConnectionProvider = InternetConnectionProvider._();

final class InternetConnectionProvider
    extends
        $FunctionalProvider<
          InternetConnection,
          InternetConnection,
          InternetConnection
        >
    with $Provider<InternetConnection> {
  InternetConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'internetConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$internetConnectionHash();

  @$internal
  @override
  $ProviderElement<InternetConnection> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InternetConnection create(Ref ref) {
    return internetConnection(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InternetConnection value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InternetConnection>(value),
    );
  }
}

String _$internetConnectionHash() =>
    r'97ac2700b7886a7909385e8ec534af8523d4f0f4';
