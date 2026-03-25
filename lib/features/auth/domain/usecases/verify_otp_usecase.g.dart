// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_usecase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(verifyOtpUseCase)
final verifyOtpUseCaseProvider = VerifyOtpUseCaseProvider._();

final class VerifyOtpUseCaseProvider
    extends
        $FunctionalProvider<
          VerifyOtpUseCase,
          VerifyOtpUseCase,
          VerifyOtpUseCase
        >
    with $Provider<VerifyOtpUseCase> {
  VerifyOtpUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verifyOtpUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verifyOtpUseCaseHash();

  @$internal
  @override
  $ProviderElement<VerifyOtpUseCase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  VerifyOtpUseCase create(Ref ref) {
    return verifyOtpUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerifyOtpUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerifyOtpUseCase>(value),
    );
  }
}

String _$verifyOtpUseCaseHash() => r'5f4307244671e18b2ce85b0a27329382cdb1c884';
