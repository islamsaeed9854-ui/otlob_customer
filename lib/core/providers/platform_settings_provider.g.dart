// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(platformSettings)
final platformSettingsProvider = PlatformSettingsProvider._();

final class PlatformSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlatformSettingsData>,
          PlatformSettingsData,
          FutureOr<PlatformSettingsData>
        >
    with
        $FutureModifier<PlatformSettingsData>,
        $FutureProvider<PlatformSettingsData> {
  PlatformSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformSettingsHash();

  @$internal
  @override
  $FutureProviderElement<PlatformSettingsData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlatformSettingsData> create(Ref ref) {
    return platformSettings(ref);
  }
}

String _$platformSettingsHash() => r'31ff850c6cca747644e3e3ac47f477a2cbbfaf8c';
