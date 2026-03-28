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
  String get customDeliveryTitle => isArabic ? 'توصيل خاص' : 'Custom Delivery';
  String get pickupLocation => isArabic ? 'موقع الاستلام' : 'Pickup Location';
  String get dropoffLocation => isArabic ? 'موقع التسليم' : 'Dropoff Location';
  String get itemDetails => isArabic ? 'تفاصيل الغرض' : 'Item Details';
  String get enterPickupLocation => isArabic ? 'أدخل موقع الاستلام' : 'Enter pickup location';
  String get enterDropoffLocation => isArabic ? 'أدخل موقع التسليم' : 'Enter dropoff location';
  String get enterItemDetails => isArabic ? 'أدخل تفاصيل الغرض (مثال: أوراق هامة)' : 'Enter item details (e.g., important documents)';
  String get vehicleType => isArabic ? 'نوع المركبة' : 'Vehicle Type';
  String get motorcycle => isArabic ? 'دراجة نارية' : 'Motorcycle';
  String get car => isArabic ? 'سيارة' : 'Car';
  String get requestCourier => isArabic ? 'طلب مندوب' : 'Request Courier';
  String get trackOrder => isArabic ? 'تتبع' : 'Track';
  String get cartButton => isArabic ? 'عنصر' : 'item';
  String get egp => isArabic ? ' ج.م' : ' EGP';
  String get retry => isArabic ? 'إعادة المحاولة' : 'Retry';
  String get noResults => isArabic ? 'لا توجد نتائج' : 'No results found';
  String get chatWithVendor => isArabic ? 'دردشة مع البائع' : 'Chat with Vendor';
  String get chatWithVendorSubtext => isArabic ? 'يمكنك الاستفسار عن تفاصيل طلبك' : 'Inquire about your order details';
  String get menu => isArabic ? 'القائمة' : 'Menu';
  String get viewCart => isArabic ? 'عرض السلة' : 'View Cart';
  String get addedToCart => isArabic ? 'تمت الإضافة للسلة' : 'Added to cart';
  String get cart => isArabic ? 'السلة' : 'Cart';
  String get clearAll => isArabic ? 'مسح الكل' : 'Clear All';
  String get emptyCart => isArabic ? 'السلة فارغة' : 'Your cart is empty';
  String get emptyCartSub => isArabic ? 'أضف بعض العناصر اللذيذة وابدأ الطلب!' : 'Add some delicious items and start ordering!';
  String get browseNow => isArabic ? 'تصفح الآن' : 'Browse Now';
  String get total => isArabic ? 'الإجمالي' : 'Total';
  String get checkout => isArabic ? 'الدفع' : 'Checkout';
  String get subtotal => isArabic ? 'المجموع الفرعي' : 'Subtotal';
  String get deliveryFee => isArabic ? 'رسوم التوصيل' : 'Delivery Fee';
  String get free => isArabic ? 'مجاني' : 'Free';
  String get orderSummary => isArabic ? 'ملخص الطلب' : 'Order Summary';
  String get placeOrder => isArabic ? 'إتمام الطلب' : 'Place Order';
  String get checkoutTitle => isArabic ? 'إتمام الشراء' : 'Checkout';
  String get deliveryAddress => isArabic ? 'عنوان التوصيل' : 'Delivery Address';
  String get paymentMethod => isArabic ? 'طريقة الدفع' : 'Payment Method';
  String get cash => isArabic ? 'نقداً' : 'Cash';
  String get creditCard => isArabic ? 'بطاقة ائتمان' : 'Credit Card';
  String get instapay => isArabic ? 'إنستا باي' : 'Instapay';
  String get orderSuccess => isArabic ? 'تم تأكيد طلبك!' : 'Order Confirmed!';
  String get orderSuccessSub => isArabic ? 'طلبك قيد التحضير وسنوافيك بالتحديثات قريباً' : 'Your order is being prepared. We will update you shortly.';
  String get goToOrders => isArabic ? 'الذهاب لطلباتي' : 'Go to My Orders';
  String get processing => isArabic ? 'جاري المعالجة...' : 'Processing...';
  String get editProfile => isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile';
  String get myAddresses => isArabic ? 'عناويني' : 'My Addresses';
  String get helpCenter => isArabic ? 'مركز المساعدة' : 'Help Center';
  String get aboutApp => isArabic ? 'عن التطبيق' : 'About App';
  String get logout => isArabic ? 'تسجيل الخروج' : 'Logout';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get notifications => isArabic ? 'التنبيهات' : 'Notifications';
  String get darkMode => isArabic ? 'الوضع الليلي' : 'Dark Mode';
  String get appName => isArabic ? 'أطلب' : 'OTLOB';

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
