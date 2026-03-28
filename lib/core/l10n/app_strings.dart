import 'package:flutter/material.dart';

class AppStrings {
  final bool isArabic;
  const AppStrings(this.isArabic);

  static AppStrings of(BuildContext context) {
    // For now, default to English or check locale if available
    final locale = Localizations.maybeLocaleOf(context);
    return AppStrings(locale?.languageCode == 'ar');
  }

  String get navHome => isArabic ? 'الرئيسية' : 'Home';
  String get navOrders => isArabic ? 'طلباتي' : 'Orders';
  String get navChat => isArabic ? 'دردشة' : 'Chat';
  String get navProfile => isArabic ? 'حسابي' : 'Profile';

  String get deliverTo => isArabic ? 'توصيل إلى' : 'Deliver to';
  String get locationName => isArabic ? 'المعادي، القاهرة' : 'Maadi, Cairo';
  String get searchRestaurant => isArabic ? 'ابحث عن مطعم أو وجبة...' : 'Search for a restaurant or meal...';
  String get restaurants => isArabic ? 'مطاعم' : 'Restaurants';
  String get pharmacies => isArabic ? 'صيدليات' : 'Pharmacies';
  String get supermarkets => isArabic ? 'سوبرماركت' : 'Supermarkets';
  String get nearbyRestaurants => isArabic ? 'المطاعم القريبة' : 'Nearby Restaurants';
  String get availablePharm => isArabic ? 'الصيدليات المتاحة' : 'Available Pharmacies';
  String get nearbySuper => isArabic ? 'السوبرماركت القريب' : 'Nearby Supermarkets';
  String get seeAll => isArabic ? 'عرض الكل' : 'See All';
  String get customDeliveryBannerTitle => isArabic ? 'توصيل خاص' : 'Custom Courier';
  String get customDeliveryBannerSub => isArabic ? 'يمكنك طلب مندوب خاص بك لتوصيل طلبك' : 'Request a personal courier for any delivery';
  String get trackOrder => isArabic ? 'تتبع' : 'Track';
  String get cartButton => isArabic ? 'عنصر' : 'item';
  String get egp => isArabic ? ' ج.م' : ' EGP';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get noResults => isArabic ? 'لا توجد نتائج' : 'No results found';

  List<List<String>> get promoBanners => isArabic ? [
    ['🔥 خصم 50% على أول طلب!', 'كود: OTLOB50', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop'],
    ['🍕 توصيل مجاني هذا الأسبوع', 'على طلبات البيتزا', 'https://loremflickr.com/600/200/pizza,food?lock=902'],
  ] : [
    ['🔥 50% Off Your First Order!', 'Code: OTLOB50', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop'],
    ['🍕 Free Delivery This Week', 'On all pizza orders', 'https://loremflickr.com/600/200/pizza,food?lock=902'],
  ];

  String translateStatus(String? status) => status ?? '';
  String translateEta(String? eta) => eta ?? '';
}
