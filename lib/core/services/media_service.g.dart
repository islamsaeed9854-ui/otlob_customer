// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mediaService)
final mediaServiceProvider = MediaServiceProvider._();

final class MediaServiceProvider
    extends $FunctionalProvider<MediaService, MediaService, MediaService>
    with $Provider<MediaService> {
  MediaServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaServiceHash();

  @$internal
  @override
  $ProviderElement<MediaService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaService create(Ref ref) {
    return mediaService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaService>(value),
    );
  }
}

String _$mediaServiceHash() => r'224288451f95360ebac38964777f5dc5e9853007';
