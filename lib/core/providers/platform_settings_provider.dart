import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/network_providers.dart';

part 'platform_settings_provider.g.dart';

class PlatformSettingsData {
  final String? homeCoverUrl;
  final String? motorcycleIconUrl;
  final String? carIconUrl;
  final String? deliveryBannerIconUrl;
  final String currency;
  final double minOrderAmount;

  PlatformSettingsData({
    this.homeCoverUrl,
    this.motorcycleIconUrl,
    this.carIconUrl,
    this.deliveryBannerIconUrl,
    this.currency = 'EGP',
    this.minOrderAmount = 0,
  });

  factory PlatformSettingsData.fromJson(Map<String, dynamic> json) {
    return PlatformSettingsData(
      homeCoverUrl: json['homeCoverUrl'],
      motorcycleIconUrl: json['motorcycleIconUrl'],
      carIconUrl: json['carIconUrl'],
      deliveryBannerIconUrl: json['deliveryBannerIconUrl'],
      currency: json['currency'] ?? 'EGP',
      minOrderAmount: double.tryParse(json['minOrderAmount']?.toString() ?? '0') ?? 0,
    );
  }
}

@riverpod
Future<PlatformSettingsData> platformSettings(Ref ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/platform-settings/public');
    final data = response.data['data'] ?? response.data;
    return PlatformSettingsData.fromJson(data);
  } catch (e) {
    // Fallback to defaults on error
    return PlatformSettingsData();
  }
}
