// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VendorDetailController)
final vendorDetailControllerProvider = VendorDetailControllerFamily._();

final class VendorDetailControllerProvider
    extends
        $AsyncNotifierProvider<VendorDetailController, Map<String, dynamic>> {
  VendorDetailControllerProvider._({
    required VendorDetailControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'vendorDetailControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$vendorDetailControllerHash();

  @override
  String toString() {
    return r'vendorDetailControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  VendorDetailController create() => VendorDetailController();

  @override
  bool operator ==(Object other) {
    return other is VendorDetailControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vendorDetailControllerHash() =>
    r'0248f95a9d676eb8e93e80db2e7b17482f7a9ea7';

final class VendorDetailControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          VendorDetailController,
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>,
          String
        > {
  VendorDetailControllerFamily._()
    : super(
        retry: null,
        name: r'vendorDetailControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VendorDetailControllerProvider call(String vendorId) =>
      VendorDetailControllerProvider._(argument: vendorId, from: this);

  @override
  String toString() => r'vendorDetailControllerProvider';
}

abstract class _$VendorDetailController
    extends $AsyncNotifier<Map<String, dynamic>> {
  late final _$args = ref.$arg as String;
  String get vendorId => _$args;

  FutureOr<Map<String, dynamic>> build(String vendorId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Map<String, dynamic>>, Map<String, dynamic>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Map<String, dynamic>>,
                Map<String, dynamic>
              >,
              AsyncValue<Map<String, dynamic>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
