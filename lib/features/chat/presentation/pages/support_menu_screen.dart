import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/network/network_providers.dart';
import '../providers/support_ticket_provider.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../providers/chat_provider.dart';

class SupportMenuScreen extends ConsumerStatefulWidget {
  const SupportMenuScreen({super.key});

  @override
  ConsumerState<SupportMenuScreen> createState() => _SupportMenuScreenState();
}

enum _SupportStep { category, orderPicker, subCategory }

class _SupportMenuScreenState extends ConsumerState<SupportMenuScreen> {
  _SupportStep _step = _SupportStep.category;

  String? _selectedCategory;       // Arabic category key
  String? _selectedSubCategory;    // Arabic sub-category key
  Map<String, dynamic>? _selectedOrder; // Full order map selected by user

  List<Map<String, dynamic>> _orders = [];
  bool _loadingOrders = false;
  bool _isCheckingActiveTicket = true;

  // ───────── Category / SubCategory data ─────────

  final Map<String, List<String>> _categoriesAr = {
    'مشكلة في التوصيل': [
      'تأخير في التوصيل',
      'الكابتن مش بيرد',
      'الكابتن مش لاقي المكان',
      'الطلب اتسلم لحد تاني',
      'شكوى على الكابتن',
    ],
    'مشكلة في متجر / محتويات الطلب': [
      'الطلب ناقص أو غلط',
      'جودة المنتجات سيئة',
      'المتجر مغلق وهو ظاهر مفتوح',
      'السعر غلط',
    ],
    'مشكلة في الدفع': [
      'دفع InstaPay',
      'دفع فودافون كاش',
    ],
    'مشكلة في الحساب والتطبيق': [
      'مشكلة حساب/دخول',
    ],
    'طلب استرجاع/شكوى عامة': [
      'طلب استرجاع',
    ],
    'مش لاقي مشكلتي': [],
  };

  final Map<String, String> _categoryEnMapping = {
    'مشكلة في التوصيل':         'Delivery Issue',
    'مشكلة في متجر / محتويات الطلب':    'Vendor/Order Contents Issue',
    'مشكلة في الدفع':           'Payment Issue',
    'مشكلة في الحساب والتطبيق': 'Account/App Issue',
    'طلب استرجاع/شكوى عامة':    'Return/Complaint',
    'مش لاقي مشكلتي':           'Other',
  };

  final Map<String, String> _subCategoryEnMapping = {
    'تأخير في التوصيل':          'Delayed delivery',
    'الكابتن مش بيرد':           'Courier not responding',
    'الكابتن مش لاقي المكان':    'Courier lost',
    'الطلب اتسلم لحد تاني':      'Order delivered to wrong person',
    'شكوى على الكابتن':          'Courier complaint',
    'الطلب ناقص أو غلط':        'Missing or wrong items',
    'جودة المنتجات سيئة':          'Poor product quality',
    'المتجر مغلق وهو ظاهر مفتوح': 'Store closed but showing open',
    'السعر غلط':                 'Wrong price',
    'دفع InstaPay':              'InstaPay Payment',
    'دفع فودافون كاش':           'Vodafone Cash Payment',
    'مشكلة حساب/دخول':          'Account/Login issue',
    'طلب استرجاع':               'Return request',
  };

  // Categories that require an order to be selected
  final Set<String> _orderRequiredCategories = {
    'مشكلة في التوصيل',
    'مشكلة في متجر / محتويات الطلب',
    'طلب استرجاع/شكوى عامة',
  };

  // ───────── Lifecycle ─────────

  @override
  void initState() {
    super.initState();
    _checkActiveTicket();
  }

  Future<void> _checkActiveTicket() async {
    try {
      final result = await ref.read(supportTicketProvider.notifier).getTickets();
      final List<dynamic> tickets = result is List ? result : [];
      for (var t in tickets) {
        if (t is Map<String, dynamic>) {
          final status = t['status']?.toString().toUpperCase();
          if (status != 'CLOSED' && status != null) {
            if (mounted) {
              context.pushReplacement(
                '/chat/direct/${t['conversationId']}',
                extra: {'title': t['subject']},
              );
            }
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isCheckingActiveTicket = false);
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/orders/my');
      final raw = response.data['data'];
      final list = (raw is Map ? raw['orders'] : raw) as List? ?? [];
      setState(() {
        _orders = list
            .whereType<Map<String, dynamic>>()
            .where((o) => o['type'] != 'custom_delivery')
            .toList();
      });
    } catch (_) {
      setState(() => _orders = []);
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  // ───────── Navigation helpers ─────────

  void _onCategoryTapped(String categoryAr) {
    setState(() => _selectedCategory = categoryAr);

    final subList = _categoriesAr[categoryAr] ?? [];

    if (_orderRequiredCategories.contains(categoryAr)) {
      // Go to order picker first
      setState(() => _step = _SupportStep.orderPicker);
      _loadOrders();
    } else if (subList.isEmpty) {
      // No sub-categories and no order needed → create directly
      _createTicket(categoryAr, null);
    } else {
      setState(() => _step = _SupportStep.subCategory);
    }
  }

  void _onOrderSelected(Map<String, dynamic> order) {
    setState(() {
      _selectedOrder = order;
      final subList = _categoriesAr[_selectedCategory!] ?? [];
      if (subList.isEmpty) {
        // No sub-categories → create immediately
      } else {
        _step = _SupportStep.subCategory;
      }
    });

    final subList = _categoriesAr[_selectedCategory!] ?? [];
    if (subList.isEmpty) {
      _createTicket(_selectedCategory!, null);
    }
  }

  void _onSubCategoryTapped(String subAr) {
    _createTicket(_selectedCategory!, subAr);
  }

  void _goBack() {
    setState(() {
      if (_step == _SupportStep.subCategory) {
        if (_orderRequiredCategories.contains(_selectedCategory)) {
          _step = _SupportStep.orderPicker;
        } else {
          _step = _SupportStep.category;
          _selectedCategory = null;
        }
      } else if (_step == _SupportStep.orderPicker) {
        _step = _SupportStep.category;
        _selectedCategory = null;
        _selectedOrder = null;
      }
    });
  }

  // ───────── Ticket creation ─────────

  Future<void> _createTicket(String categoryAr, String? subAr) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    String categoryEnum;
    switch (categoryAr) {
      case 'مشكلة في التوصيل':          categoryEnum = 'DELIVERY'; break;
      case 'مشكلة في متجر / محتويات الطلب':     categoryEnum = 'VENDOR';   break;
      case 'مشكلة في الدفع':            categoryEnum = 'PAYMENT';  break;
      case 'مشكلة في الحساب والتطبيق':  categoryEnum = 'ACCOUNT';  break;
      case 'طلب استرجاع/شكوى عامة':     categoryEnum = 'VENDOR';   break;
      default:                           categoryEnum = 'OTHER';
    }

    final subCategory = subAr != null ? (_subCategoryEnMapping[subAr] ?? subAr) : null;
    final subject = isAr
        ? (subAr ?? categoryAr)
        : (subCategory ?? _categoryEnMapping[categoryAr] ?? categoryAr);

    // Extract orderId & vendorId from the selected order
    final orderId  = _selectedOrder?['id']?.toString();
    final vendorId = _selectedOrder?['vendorId']?.toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final tickets = await ref.read(supportTicketProvider.notifier).getTickets();
      final activeTicket = tickets.firstWhere(
        (t) => t['status'] != 'CLOSED' && t['status'] != 'RESOLVED',
        orElse: () => null,
      );

      if (activeTicket != null) {
        if (mounted) {
          Navigator.pop(context);
          context.pushReplacement(
            '/chat/direct/${activeTicket['conversationId']}',
            extra: {'title': activeTicket['subject']},
          );
        }
        return;
      }

      final ticket = await ref.read(supportTicketProvider.notifier).createTicket(
        subject: subject,
        category: categoryEnum,
        subCategory: subAr ?? subCategory,
        orderId: orderId,
        vendorId: vendorId,
      );


      if (mounted) {
        Navigator.pop(context);
        context.pushReplacement(
          '/chat/direct/${ticket['conversationId']}',
          extra: {'title': subject},
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ───────── Build ─────────

  @override
  Widget build(BuildContext context) {
    if (_isCheckingActiveTicket) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: _step != _SupportStep.category
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _goBack,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop(),
              ),
        title: Text(
          _stepTitle(isAr),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildStepProgress(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _buildStep(isAr, isDark),
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(bool isAr) {
    switch (_step) {
      case _SupportStep.category:
        return isAr ? 'الدعم الفني' : 'Technical Support';
      case _SupportStep.orderPicker:
        return isAr ? 'اختار الطلب' : 'Select Order';
      case _SupportStep.subCategory:
        return isAr ? 'تفاصيل المشكلة' : 'Issue Details';
    }
  }

  Widget _buildStepProgress() {
    // Decide if we show 3 steps or 2 steps
    final bool needsOrder = _selectedCategory == null || _orderRequiredCategories.contains(_selectedCategory);
    final int totalSteps = needsOrder ? 3 : 2;

    // Map the current _SupportStep enum to a 0-based index
    final int currentIdx;
    switch (_step) {
      case _SupportStep.category:
        currentIdx = 0;
        break;
      case _SupportStep.orderPicker:
        currentIdx = 1;
        break;
      case _SupportStep.subCategory:
        currentIdx = needsOrder ? 2 : 1;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Line segment between dots
            final segIdx = i ~/ 2;
            final segDone = segIdx < currentIdx;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                color: segDone ? AppColors.primary : Colors.grey.withOpacity(0.3),
              ),
            );
          }

          final dotIdx = i ~/ 2;
          final isDoneOrCurrent = dotIdx <= currentIdx; // Completed or active step

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDoneOrCurrent
                  ? AppColors.primary                      // Active/Done → filled primary
                  : Colors.transparent,                 // Upcoming → empty
              border: Border.all(
                color: isDoneOrCurrent
                    ? AppColors.primary
                    : Colors.grey.withOpacity(0.35),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: isDoneOrCurrent
                ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                : null,
          );
        }),
      ),
    );
  }



  Widget _buildStep(bool isAr, bool isDark) {
    switch (_step) {
      case _SupportStep.category:
        return _buildCategoryStep(isAr, isDark);
      case _SupportStep.orderPicker:
        return _buildOrderPickerStep(isAr, isDark);
      case _SupportStep.subCategory:
        return _buildSubCategoryStep(isAr, isDark);
    }
  }

  // ── Step 1: Category ──

  Widget _buildCategoryStep(bool isAr, bool isDark) {
    return ListView(
      key: const ValueKey('category'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _buildStepHeader(
          icon: LucideIcons.helpCircle,
          title: isAr ? 'أهلاً! كيف يمكننا مساعدتك؟' : 'Hello! How can we help you?',
          subtitle: isAr ? 'اختار نوع المشكلة للمتابعة' : 'Select your issue type to continue',
        ),
        ..._categoriesAr.keys.map((catAr) {
          final catEn = _categoryEnMapping[catAr] ?? catAr;
          return _buildTile(
            title: isAr ? catAr : catEn,
            icon: _getCategoryIcon(catAr),
            onTap: () => _onCategoryTapped(catAr),
            trailing: _orderRequiredCategories.contains(catAr)
                ? _buildBadge(isAr ? 'يحتاج طلب' : 'Needs order', AppColors.primary)
                : null,
          );
        }),
      ],
    );
  }

  // ── Step 2: Order picker ──

  Widget _buildOrderPickerStep(bool isAr, bool isDark) {
    if (_loadingOrders) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        key: const ValueKey('no-orders'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.shoppingBag, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isAr ? 'لا توجد طلبات سابقة' : 'No previous orders found',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'يجب أن تكون لديك طلبات سابقة لفتح تذكرة دعم'
                  : 'You need previous orders to open a support ticket',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView(
      key: const ValueKey('order-picker'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _buildStepHeader(
          icon: LucideIcons.receipt,
          title: isAr ? 'اختار الطلب المتعلق بالمشكلة' : 'Select the related order',
          subtitle: isAr
              ? 'سيتم إرسال التذكرة مع تفاصيل طلبك'
              : 'The ticket will be sent with your order details',
        ),
        ..._orders.map((order) => _buildOrderTile(order, isAr, isDark)),
      ],
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order, bool isAr, bool isDark) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final vendorName = order['vendorName']?.toString()
        ?? order['vendor']?['storeName']?.toString()
        ?? (isAr ? 'متجر' : 'Store');
    final status = order['status']?.toString() ?? '';
    final orderId = order['id']?.toString() ?? '';
    final shortId = orderId.split('-').last.toUpperCase();

    final isSelected = _selectedOrder?['id'] == order['id'];

    return GestureDetector(
      onTap: () => _onOrderSelected(order),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 12)]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.shoppingBag,
                size: 20,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendorName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${isAr ? 'طلب' : 'Order'} #$shortId • ${items.length} ${isAr ? 'عناصر' : 'items'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _statusColor(status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Sub-category ──

  Widget _buildSubCategoryStep(bool isAr, bool isDark) {
    final subList = _categoriesAr[_selectedCategory!] ?? [];
    final catEn = _categoryEnMapping[_selectedCategory!] ?? '';

    return ListView(
      key: const ValueKey('sub-category'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        if (_selectedOrder != null) _buildSelectedOrderSummary(_selectedOrder!, isAr, isDark),
        _buildStepHeader(
          icon: LucideIcons.listChecks,
          title: isAr ? 'ما هي المشكلة تحديداً؟' : 'What is the specific issue?',
          subtitle: isAr ? _selectedCategory! : catEn,
        ),
        ...subList.map((subAr) {
          final subEn = _subCategoryEnMapping[subAr] ?? subAr;
          return _buildTile(
            title: isAr ? subAr : subEn,
            icon: Icons.chevron_right_rounded,
            onTap: () => _onSubCategoryTapped(subAr),
          );
        }),
      ],
    );
  }

  Widget _buildSelectedOrderSummary(Map<String, dynamic> order, bool isAr, bool isDark) {
    final vendorName = order['vendorName']?.toString()
        ?? order['vendor']?['storeName']?.toString()
        ?? (isAr ? 'متجر' : 'Store');
    final orderId = order['id']?.toString() ?? '';
    final shortId = orderId.split('-').last.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.receipt, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${isAr ? 'الطلب المختار' : 'Selected Order'}: $vendorName – #$shortId',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── Reusable widgets ─────────

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryAr) {
    switch (categoryAr) {
      case 'مشكلة في التوصيل':          return LucideIcons.truck;
      case 'مشكلة في متجر / محتويات الطلب':     return LucideIcons.store;
      case 'مشكلة في الدفع':            return LucideIcons.creditCard;
      case 'مشكلة في الحساب والتطبيق':  return LucideIcons.user;
      case 'طلب استرجاع/شكوى عامة':     return LucideIcons.messageSquare;
      default:                           return LucideIcons.helpCircle;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':  return Colors.green;
      case 'CANCELLED':  return Colors.red;
      case 'PENDING':    return Colors.orange;
      case 'PREPARING':  return Colors.blue;
      default:           return AppColors.primary;
    }
  }
}
