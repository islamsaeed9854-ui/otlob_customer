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
  String get navSearch => isArabic ? 'البحث' : 'Search';

  String get deliverTo => isArabic ? 'توصيل إلى' : 'Deliver to';
  String get locationName => isArabic ? 'المعادي، القاهرة' : 'Maadi, Cairo';
  String get searchRestaurant => isArabic ? 'ابحث أنا في خدمتك...' : 'Search I\'m at your service...';
  String get restaurants => isArabic ? 'مطاعم' : 'Restaurants';
  String get pharmacies => isArabic ? 'صيدليات' : 'Pharmacies';
  String get supermarkets => isArabic ? 'سوبرماركت' : 'Supermarkets';
  String get nearbyRestaurants => isArabic ? 'المطاعم القريبة' : 'Nearby Restaurants';
  String get availablePharm => isArabic ? 'الصيدليات المتاحة' : 'Available Pharmacies';
  String get nearbySuper => isArabic ? 'السوبرماركت القريب' : 'Nearby Supermarkets';
  String get seeAll => isArabic ? 'عرض الكل' : 'See All';
  String get customDeliveryBannerTitle => isArabic ? 'توصيل خاص' : 'Custom Courier';
  String get customDeliveryBannerSub => isArabic 
      ? 'اطلب مندوب لتوصيل اي شئ أو رحلة للتنقل' 
      : 'Request a delivery person for anything or a transportation trip';
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
  String get orderNow => isArabic ? 'اطلب الآن' : 'Order Now';
  String get chatWithVendor => isArabic ? 'تواصل لطلب منتجات بشكل مباشر' : 'Contact the store to order products directly';
  String get chatWithVendorSubtext => isArabic ? 'يمكنك طلب منتج غير متواجد بالقائمة.' : 'You can request a product that is not on the list.';
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
  String get languageName => isArabic ? 'العربية 🇪🇬' : 'English 🇬🇧';
  String get enabled => isArabic ? 'مفعل' : 'Enabled';
  String get disabled => isArabic ? 'معطل' : 'Disabled';
  String get on => isArabic ? 'مفعل' : 'On';
  String get off => isArabic ? 'معطل' : 'Off';
  String get logoutConfirm => isArabic ? 'هل أنت متأكد أنك تريد تسجيل الخروج؟' : 'Are you sure you want to log out?';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get saveChanges => isArabic ? 'حفظ التغييرات' : 'Save Changes';
  String get fullName => isArabic ? 'الاسم الكامل' : 'Full Name';
  String get emailAddress => isArabic ? 'البريد الإلكتروني' : 'Email Address';
  String get phoneNumber => isArabic ? 'رقم الهاتف' : 'Phone Number';
  String get noAddresses => isArabic ? 'لا توجد عناوين محفوظة' : 'No Addresses Saved';
  String get addAddressSub => isArabic ? 'أضف عنواناً لتسريع عملية الطلب' : 'Add an address to speed up your order process';
  String get addNewAddress => isArabic ? 'إضافة عنوان جديد' : 'Add New Address';
  String get addressLabel => isArabic ? 'العنوان (مثلاً: المنزل، العمل)' : 'Label (e.g. Home, Work)';
  String get fullAddress => isArabic ? 'العنوان الكامل' : 'Full Address';
  String get addAddress => isArabic ? 'إضافة العنوان' : 'Add Address';
  String get address => isArabic ? 'عنوان' : 'Address';
  String get welcomeBack => isArabic ? 'مرحباً بعودتك' : 'Welcome Back';
  String get loginToApp => isArabic ? 'تسجيل الدخول إلى أطلب' : 'Log in to Otlob';
  String get email => isArabic ? 'البريد الإلكتروني' : 'Email';
  String get password => isArabic ? 'كلمة المرور' : 'Password';
  String get emailRequired => isArabic ? 'يرجى إدخال بريد إلكتروني صحيح' : 'Valid email required';
  String get passwordMinLen => isArabic ? '6 أحرف على الأقل' : 'Min 6 characters';
  String get forgotPassword => isArabic ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get login => isArabic ? 'تسجيل الدخول' : 'Login';
  String get dontHaveAccount => isArabic ? 'ليس لديك حساب؟ ' : "Don't have an account? ";
  String get signUp => isArabic ? 'إنشاء حساب' : 'Sign up';
  String get createAccount => isArabic ? 'إنشاء حساب جديد' : 'Create Account';
  String get joinApp => isArabic ? 'انضم إلى أطلب' : 'Join Otlob';
  String get nameRequired => isArabic ? 'الاسم مطلوب' : 'Name is required';
  String get phoneNumberOptional => isArabic ? 'رقم الهاتف (اختياري)' : 'Phone Number (Optional)';
  String get register => isArabic ? 'تسجيل' : 'Register';
  String get alreadyHaveAccount => isArabic ? 'لديك حساب بالفعل؟ ' : 'Already have an account? ';
  String get vendor => isArabic ? 'البائع' : 'Vendor';
  String get defaultCity => isArabic ? 'القاهرة، مصر' : 'Cairo, Egypt';
  String get orderNo => isArabic ? 'طلب رقم ' : 'Order #';
  String get readLess => isArabic ? 'عرض أقل' : 'Read Less';
  String get readMore => isArabic ? 'اقرأ المزيد...' : 'Read More...';
  String get customCourierDesc => isArabic 
      ? 'مندوب خاص هي خدمة تتيح لك إرسال أو استلام أي طلب بسهولة وسرعة.\nاطلب مندوبًا لتوصيل أغراضك أو إحضار أي شيء من أي مكان، طالما كان قانونيًا ومسموحًا بنقله.' 
      : 'Custom Courier is a service that allows you to send or receive any item easily and quickly.\nRequest a courier to deliver your items or bring anything from anywhere, as long as it is legal and allowed to be transported.';
  String get rideServiceDesc => isArabic 
      ? 'خدمة الرحلات تتيح لك التنقل أو التنزه بكل سهولة وراحة، سواء داخل المدينة أو إلى أي مكان تريده.\nيمكنك طلب رحلة في أي وقت، وسنوفّر لك وسيلة نقل آمنة وسريعة لتصل إلى وجهتك أو تستمتع بوقتك بدون عناء.' 
      : 'Ride service lets you travel or enjoy trips with ease and comfort, whether within the city or anywhere you choose.\nYou can request a ride anytime, and we’ll provide a safe and fast transport option to get you to your destination or enjoy your time without hassle.';
  String get yourLocation => isArabic ? 'موقعك الحالي' : 'Your Location';
  String get whereAreYou => isArabic ? 'أين أنت الآن؟' : 'Where are you now?';
  String get wherePickUp => isArabic ? 'من أين سيستلم السائق الطلب؟' : 'Where should driver pick up?';
  String get destination => isArabic ? 'وجهتك' : 'Destination';
  String get whereToGo => isArabic ? 'إلى أين تريد الذهاب؟' : 'Where do you want to go?';
  String get wherePackageGoing => isArabic ? 'أين سيتم تسليم الطلب؟' : 'Where is the package going?';
  String get required => isArabic ? 'مطلوب' : 'Required';
  String get delivery => isArabic ? 'توصيل' : 'Delivery';
  String get ride => isArabic ? 'رحلة' : 'Ride';
  String get findingCaptain => isArabic ? 'جاري البحث عن كابتن...' : 'Finding a Captain...';
  String get pleaseWaitConnectDriver => isArabic ? 'يرجى الانتظار لحين قبول أقرب سائق لطلبك' : 'Please wait while we connect you with the nearest driver';
  String get requestConfirmed => isArabic ? 'تم تأكيد طلبك!' : 'Request Confirmed!';
  String get plateNo => isArabic ? 'رقم اللوحة' : 'Plate No.';
  String get trackRequest => isArabic ? 'تتبع الطلب' : 'Track Request';
  String get backToHome => isArabic ? 'العودة للرئيسية' : 'Back to Home';
  String get products => isArabic ? 'المنتجات' : 'Products';
  String get noItemsInCategory => isArabic ? 'لا توجد منتجات في هذا القسم حالياً' : 'No items in this category currently';
  String get errorPrefix => isArabic ? 'خطأ: ' : 'Error: ';
  String get catAll => isArabic ? 'الكل' : 'All';
  String get catMedicines => isArabic ? 'أدوية' : 'Medicines';
  String get catCosmetics => isArabic ? 'مستحضرات تجميل' : 'Cosmetics';
  String get addToCart => isArabic ? 'إضافة للسلة' : 'Add to Cart';
  String get done => isArabic ? 'تم' : 'Done';
  String get allStores => isArabic ? 'مقترح لك' : 'Suggested for You';
  String get stores => isArabic ? 'المتاجر' : 'Stores';
  String get allResults => isArabic ? 'جميع النتائج' : 'All Results';
  String get searchResults => isArabic ? 'نتائج البحث' : 'Search Results';
  String get clickToViewMenu => isArabic ? 'اضغط لعرض القائمة كاملة' : 'Click to view full menu';
  String get searchInStores => isArabic ? 'ابحث في المتاجر...' : 'Search in stores...';
  String get featuredSuggestions => isArabic ? 'اقتراحات مميزة' : 'Featured Suggestions';
  String get searchErrorPrefix => isArabic ? 'خطأ في البحث: ' : 'Search error: ';
  String get typeAMessage => isArabic ? 'اكتب رسالة...' : 'Type a message...';
  String get onlyImagesAllowed => isArabic ? 'يسمح بالصور فقط.' : 'Only images are allowed.';
  String get orderShort => isArabic ? 'اطلب الآن' : 'Order Now';
  String get proLabel => isArabic ? 'برو' : 'PRO';
  String get nearbyStores => isArabic ? 'المتاجر القريبة' : 'Nearby Stores';
  String get nearbyPrefix => isArabic ? 'متاجر ' : 'Nearby ';
  String get nearbySuffix => isArabic ? ' القريبة' : '';
  String get appName => isArabic ? 'أطلب' : 'OTLOB';
  String get search => isArabic ? 'بحث' : 'Search';
  String get supportGreeting => isArabic ? 'مرحباً! كيف يمكننا مساعدتك اليوم؟' : 'Hello! How can we help you today?';
  String get vendorGreeting => isArabic ? 'تواصل لطلب منتجات بشكل مباشر!' : 'Contact to order products directly!';

  List<List<String>> get promoBanners => isArabic ? [
    ['🔥 خصم 50% على أول طلب!', 'كود: OTLOB50', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop'],
    ['🍕 توصيل مجاني هذا الأسبوع', 'على طلبات البيتزا', 'https://loremflickr.com/600/200/pizza,food?lock=902'],
  ] : [
    ['🔥 50% Off Your First Order!', 'Code: OTLOB50', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop'],
    ['🍕 Free Delivery This Week', 'On all pizza orders', 'https://loremflickr.com/600/200/pizza,food?lock=902'],
  ];

  String translateStatus(String? status) => status ?? '';
  String translateEta(String? eta) => eta ?? '';

  String get edit => isArabic ? 'تعديل' : 'Edit';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get voiceMessage => isArabic ? 'رسالة صوتية' : 'Voice Message';
  String get releaseToSend => isArabic ? 'اترك للإرسال' : 'Release to send';
  String get uploading => isArabic ? 'جاري الرفع...' : 'Uploading...';
  String get deleteConfirmTitle => isArabic ? 'حذف الرسالة' : 'Delete Message';
  String get deleteConfirmBody => isArabic ? 'هل أنت متأكد من حذف هذه الرسالة؟' : 'Are you sure you want to delete this message?';
  
  String get offerTitle => isArabic ? 'عرض خاص من المتجر' : 'Special Store Offer';
  String get viewOffer => isArabic ? 'عرض التفاصيل' : 'View Details';
  String get confirmOrder => isArabic ? 'تأكيد الطلب' : 'Confirm Order';
  String get cancelOrder => isArabic ? 'إلغاء' : 'Cancel';
  
  String get package => isArabic ? 'عبوة' : 'Package';
  String get strip => isArabic ? 'شريط' : 'Strip';
  String get sellingUnit => isArabic ? 'وحدة البيع' : 'Selling Unit';
  String get yes => isArabic ? 'نعم' : 'Yes';
  String get confirm => isArabic ? 'تأكيد' : 'Confirm';

  // Offers strip
  String get hotDeals => isArabic ? '🔥 عروض حصرية' : '🔥 Hot Deals';
  String get offerBadge => isArabic ? 'عرض' : 'OFFER';
  String get seeAllOffers => isArabic ? 'عرض الكل' : 'See All';

  String get rememberMe => isArabic ? 'تذكرني' : 'Remember Me';
  String get orLoginWithAnother => isArabic ? 'أو تسجيل الدخول بحساب آخر' : 'Or login with another account';
  String get ticketExists => isArabic 
      ? 'لديك تذكرة دعم مفتوحة بالفعل. يرجى حلها أولاً.' 
      : 'You already have an open support ticket. Please resolve it first.';
}
