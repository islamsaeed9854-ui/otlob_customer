import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        Future.delayed(const Duration(seconds: 3), () {
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

    return PopScope(
      canPop: _rideState == RideState.form,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(s.customDeliveryTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_handleBack()) context.pop();
            },
          ),
        ),
        body: SafeArea(
          child: _buildBodyContent(s, isAr, totalFee),
        ),
      ),
    );
  }

  Widget _buildBodyContent(AppStrings s, bool isAr, double totalFee) {
    switch (_rideState) {
      case RideState.form:
        return _buildForm(s, isAr, totalFee);
      case RideState.findingDriver:
        return _buildFindingDriver(isAr);
      case RideState.driverAssigned:
        return _buildDriverAssigned(isAr);
    }
  }

  Widget _buildForm(AppStrings s, bool isAr, double totalFee) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedVehicle == 'car' ? Icons.local_taxi_rounded : Icons.moped_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                isAr ? 'احجز سائق لتوصيل طلباتك أو للتنقل والرحلات' : 'Book a driver for package delivery or ride hailing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text(isAr ? 'توصيل طلب' : 'Delivery', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      value: 'delivery',
                      groupValue: _serviceType,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _serviceType = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text(isAr ? 'تنقل / رحلة' : 'Ride', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      value: 'ride',
                      groupValue: _serviceType,
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        setState(() {
                          _serviceType = v!;
                          _selectedVehicle = 'car';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel(isAr ? (_serviceType == 'ride' ? 'موقع الانطلاق' : s.pickupLocation) : (_serviceType == 'ride' ? 'Your Location' : s.pickupLocation)),
            _buildTextField(
              controller: _pickupController,
              hint: isAr ? (_serviceType == 'ride' ? 'أين أنت الآن؟' : s.enterPickupLocation) : (_serviceType == 'ride' ? 'Where are you now?' : s.enterPickupLocation),
              icon: _serviceType == 'ride' ? Icons.person_pin_circle_rounded : Icons.my_location,
              validator: (v) => v == null || v.isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
            ),
            const SizedBox(height: 20),
            _buildLabel(isAr ? (_serviceType == 'ride' ? 'وجهتك' : s.dropoffLocation) : (_serviceType == 'ride' ? 'Destination' : s.dropoffLocation)),
            _buildTextField(
              controller: _dropoffController,
              hint: isAr ? (_serviceType == 'ride' ? 'إلى أين تريد الذهاب؟' : s.enterDropoffLocation) : (_serviceType == 'ride' ? 'Where do you want to go?' : s.enterDropoffLocation),
              icon: _serviceType == 'ride' ? Icons.flag_rounded : Icons.location_on,
              validator: (v) => v == null || v.isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
            ),
            const SizedBox(height: 20),
            if (_serviceType == 'delivery') ...[
              _buildLabel(s.itemDetails),
              _buildTextField(
                controller: _detailsController,
                hint: s.enterItemDetails,
                icon: Icons.inventory_2_outlined,
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? (isAr ? 'مطلوب' : 'Required') : null,
              ),
              const SizedBox(height: 20),
            ],
            _buildLabel(s.vehicleType),
            Row(
              children: [
                _vehicleOption(s.motorcycle, Icons.moped_rounded, 'motorcycle'),
                const SizedBox(width: 16),
                _vehicleOption(s.car, Icons.local_taxi_rounded, 'car'),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _priceRow(s.deliveryFee, '${totalFee.toStringAsFixed(0)}${s.egp}'),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.total, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('${totalFee.toStringAsFixed(0)}${s.egp}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _serviceType == 'ride' ? (isAr ? 'طلب رحلة' : 'Request Ride') : s.requestCourier,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleOption(String label, IconData icon, String type) {
    final isSelected = _selectedVehicle == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedVehicle = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.05) : Theme.of(context).cardColor,
            border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade200, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : Colors.grey, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFindingDriver(bool isAr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 32),
          Text(isAr ? 'جاري تعيين سائق...' : 'Assigning a driver...', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(isAr ? 'يرجى الانتظار لحين قبول الكابتن لطلبك' : 'Please wait while a captain accepts your request', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildDriverAssigned(bool isAr) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(isAr ? 'تم تعيين السائق بنجاح!' : 'Driver assigned successfully!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
            ),
            child: Row(
              children: [
                const CircleAvatar(radius: 30, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=driver')),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAr ? 'أحمد محمد' : 'Ahmed Mohamed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Toyota Corolla - White', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.phone, color: Colors.green), onPressed: () {}),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(isAr ? 'العودة للرئيسية' : 'Back to Home', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _priceRow(String label, String amount) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: Colors.grey.shade600)), Text(amount, style: const TextStyle(fontWeight: FontWeight.w600))]);
}
