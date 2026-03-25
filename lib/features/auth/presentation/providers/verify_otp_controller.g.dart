// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VerifyOtpController)
final verifyOtpControllerProvider = VerifyOtpControllerProvider._();

final class VerifyOtpControllerProvider
    extends $NotifierProvider<VerifyOtpController, AsyncValue<void>> {
  VerifyOtpControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyOtpControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyOtpControllerHash();

  @$internal
  @override
  VerifyOtpController create() => VerifyOtpController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$verifyOtpControllerHash() =>
    r'11712c9c9c82761f1410233279e39ba2a52e8033';

abstract class _$VerifyOtpController extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
