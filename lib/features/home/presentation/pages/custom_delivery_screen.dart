import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/providers/platform_settings_provider.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

enum RideState { form, findingDriver, driverAssigned }

class CustomDeliveryScreen extends ConsumerStatefulWidget {
  const CustomDeliveryScreen({super.key});

  @override
  ConsumerState<CustomDeliveryScreen> createState() => _CustomDeliveryScreenState();
}

class _CustomDeliveryScreenState extends ConsumerState<CustomDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _detailsController = TextEditingController();
  
  String _selectedVehicle = 'motorcycle';
  String _serviceType = 'delivery'; // 'delivery' or 'ride'
  RideState _rideState = RideState.form;
  bool _isExpanded = false;

  double get _baseFee => _selectedVehicle == 'car' ? 55.0 : 35.0;
  final double _commissionRate = 0.10;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submitOrder() {
    if (_formKey.currentState!.validate()) {
      if (_serviceType == 'ride') {
        setState(() => _rideState = RideState.findingDriver);
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _rideState = RideState.driverAssigned);
        });
      } else {
        final pickup = _pickupController.text.trim();
        final dropoff = _dropoffController.text.trim();
        final details = _detailsController.text.trim();
        final commission = _baseFee * _commissionRate;
        final totalFee = _baseFee + commission;

        ref.read(ordersProvider.notifier).placeCustomDeliveryOrder(
          pickup: pickup,
          dropoff: dropoff,
          details: details,
          totalFee: totalFee,
          vehicleType: _selectedVehicle,
        );

        context.go('/orders');
      }
    }
  }

  bool _handleBack() {
    if (_rideState != RideState.form) {
      setState(() => _rideState = RideState.form);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final commission = _baseFee * _commissionRate;
    final totalFee = _baseFee + commission;
    final isAr = s.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _rideState == RideState.form,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
            onPressed: () {
              if (_handleBack()) context.pop();
            },
          ),
          title: Text(
            s.customDeliveryTitle, 
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.5
            )
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildBodyContent(s, isAr, totalFee, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(AppStrings s, bool isAr, double totalFee, bool isDark) {
    switch (_rideState) {
      case RideState.form:
        return _buildForm(s, isAr, totalFee, isDark);
      case RideState.findingDriver:
        return _buildFindingDriver(s, isAr, isDark);
      case RideState.driverAssigned:
        return _buildDriverAssigned(s, isAr, isDark);
    }
  }

  Widget _buildForm(AppStrings s, bool isAr, double totalFee, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeSwitcher(s, isDark),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Text(
                      _serviceType == 'delivery' ? s.customCourierDesc : s.rideServiceDesc,
                      textAlign: isAr ? TextAlign.right : TextAlign.left,
                      maxLines: _isExpanded ? 10 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Text(
                      _isExpanded ? s.readLess : s.readMore,
                      textAlign: isAr ? TextAlign.left : TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(_serviceType == 'ride' ? s.yourLocation : s.pickupLocation, isDark),
                  _buildTextField(
                    controller: _pickupController,
                    hint: _serviceType == 'ride' ? s.whereAreYou : s.wherePickUp,
                    icon: _serviceType == 'ride' ? Icons.person_pin_circle_rounded : Icons.my_location_rounded,
                    isDark: isDark,
                    validator: (v) => v == null || v.isEmpty ? s.required : null,
                  ),
                  const SizedBox(height: 24),
                  _buildLabel(_serviceType == 'ride' ? s.destination : s.dropoffLocation, isDark),
                  _buildTextField(
                    controller: _dropoffController,
                    hint: _serviceType == 'ride' ? s.whereToGo : s.wherePackageGoing,
                    icon: _serviceType == 'ride' ? Icons.flag_rounded : Icons.location_on_rounded,
                    isDark: isDark,
                    validator: (v) => v == null || v.isEmpty ? s.required : null,
                  ),
                  if (_serviceType == 'delivery') ...[
                    const SizedBox(height: 24),
                    _buildLabel(s.itemDetails, isDark),
                    _buildTextField(
                      controller: _detailsController,
                      hint: s.enterItemDetails,
                      icon: Icons.inventory_2_outlined,
                      maxLines: 3,
                      isDark: isDark,
                      validator: (v) => v == null || v.isEmpty ? s.required : null,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            _buildLabel(s.vehicleType, isDark),
            const SizedBox(height: 12),
            _buildVehicleSelector(s, isDark),
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                children: [
                  _priceRow(s.deliveryFee, '${totalFee.toStringAsFixed(0)} ${s.egp}', isDark),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.total, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                      Text('${totalFee.toStringAsFixed(0)} ${s.egp}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submitOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppColors.primary,
                elevation: 8,
                shadowColor: AppColors.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                _serviceType == 'ride' ? (isAr ? 'اطلب الآن' : 'Request Now') : s.requestCourier,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSwitcher(AppStrings s, bool isDark) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _switcherButton(s.delivery, 'delivery', isDark),
          _switcherButton(s.ride, 'ride', isDark),
        ],
      ),
    );
  }

  Widget _switcherButton(String label, String value, bool isDark) {
    final isSelected = _serviceType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _serviceType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(AppStrings s, bool isDark) {
    final platformSettings = ref.watch(platformSettingsProvider).value;

    return Row(
      children: [
        _vehicleOption(s.motorcycle, Icons.moped_rounded, 'motorcycle', isDark, platformSettings?.motorcycleIconUrl),
        const SizedBox(width: 16),
        _vehicleOption(s.car, Icons.directions_car_filled_rounded, 'car', isDark, platformSettings?.carIconUrl),
      ],
    );
  }

  Widget _vehicleOption(String label, IconData fallbackIcon, String type, bool isDark, String? customIconUrl) {
    final isSelected = _selectedVehicle == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedVehicle = type),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primary 
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100),
                shape: BoxShape.circle,
                boxShadow: isSelected 
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))] 
                    : [],
                border: Border.all(
                  color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade200),
                  width: 2,
                ),
              ),
              child: Center(
                child: customIconUrl != null && customIconUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: ImageUtils.formatImageUrl(customIconUrl),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(fallbackIcon, size: 44, color: isSelected ? Colors.white : Colors.grey),
                          errorWidget: (context, url, error) => Icon(fallbackIcon, size: 44, color: isSelected ? Colors.white : Colors.grey),
                        ),
                      )
                    : Icon(fallbackIcon, size: 52, color: isSelected ? Colors.white : Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFindingDriver(AppStrings s, bool isAr, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              child: Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_6sxyjyjj.json',
                errorBuilder: (c, e, s) => const CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              s.findingCaptain, 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)
            ),
            const SizedBox(height: 12),
            Text(
              s.pleaseWaitConnectDriver, 
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.5)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAssigned(AppStrings s, bool isAr, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          Text(
            s.requestConfirmed, 
            textAlign: TextAlign.center, 
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const CircleAvatar(radius: 32, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=driver123')),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isAr ? 'كابتن أحمد محمد' : 'Capt. Ahmed Mohamed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                SizedBox(width: 4),
                                Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _circularAction(Icons.phone, Colors.green),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Icon(
                      _selectedVehicle == 'motorcycle' ? Icons.moped_rounded : Icons.directions_car_filled_rounded,
                      color: Colors.grey,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedVehicle == 'motorcycle' ? 'Bajaj Pulsar' : 'Toyota Corolla', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(_selectedVehicle == 'motorcycle' ? 'Black' : 'White', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    _vehicleDetail(Icons.pin_rounded, 'ABC - 123', s.plateNo),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18), 
              backgroundColor: AppColors.primary, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: AppColors.primary.withOpacity(0.4),
            ),
            child: Text(s.trackRequest, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/home'),
            child: Text(s.backToHome, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _circularAction(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _vehicleDetail(IconData icon, String title, String sub) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4), 
    child: Text(text, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white70 : Colors.black87))
  );

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hint, 
    required IconData icon, 
    required bool isDark,
    int maxLines = 1, 
    String? Function(String?)? validator
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 22),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F2F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), 
          borderSide: const BorderSide(color: AppColors.primary, width: 2)
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), 
          borderSide: const BorderSide(color: Colors.red, width: 1)
        ),
      ),
    );
  }

  Widget _priceRow(String label, String amount, bool isDark) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
    children: [
      Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 15)), 
      Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87))
    ]
  );
}
