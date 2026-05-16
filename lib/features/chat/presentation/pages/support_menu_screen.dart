import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/support_ticket_provider.dart';

class SupportMenuScreen extends ConsumerStatefulWidget {
  const SupportMenuScreen({super.key});

  @override
  ConsumerState<SupportMenuScreen> createState() => _SupportMenuScreenState();
}

class _SupportMenuScreenState extends ConsumerState<SupportMenuScreen> {
  String? _selectedCategory;
  String? _selectedSubCategory;

  final Map<String, List<String>> _categoriesAr = {
    'مشكلة في التوصيل': [
      'تأخير في التوصيل',
      'الكابتن مش بيرد',
      'الكابتن مش لاقي المكان',
      'الطلب اتسلم لحد تاني',
      'شكوى على الكابتن'
    ],
    'مشكلة في المطعم/الأكل': [
      'الطلب ناقص أو غلط',
      'جودة الأكل سيئة',
      'المطعم قافل وهو ظاهر مفتوح',
      'السعر غلط'
    ],
    'مشكلة في الدفع': [
      'دفع InstaPay',
      'دفع فودافون كاش'
    ],
    'مشكلة في الحساب والتطبيق': [
      'مشكلة حساب/دخول'
    ],
    'طلب استرجاع/شكوى عامة': [
      'طلب استرجاع'
    ],
    'مش لاقي مشكلتي': []
  };

  final Map<String, String> _categoryEnMapping = {
    'مشكلة في التوصيل': 'Delivery Issue',
    'مشكلة في المطعم/الأكل': 'Vendor/Food Issue',
    'مشكلة في الدفع': 'Payment Issue',
    'مشكلة في الحساب والتطبيق': 'Account/App Issue',
    'طلب استرجاع/شكوى عامة': 'Return/Complaint',
    'مش لاقي مشكلتي': 'Other'
  };

  final Map<String, String> _subCategoryEnMapping = {
    'تأخير في التوصيل': 'Delayed delivery',
    'الكابتن مش بيرد': 'Courier not responding',
    'الكابتن مش لاقي المكان': 'Courier lost',
    'الطلب اتسلم لحد تاني': 'Order delivered to wrong person',
    'شكوى على الكابتن': 'Courier complaint',
    'الطلب ناقص أو غلط': 'Missing or wrong items',
    'جودة الأكل سيئة': 'Poor food quality',
    'المطعم قافل وهو ظاهر مفتوح': 'Restaurant closed but showing open',
    'السعر غلط': 'Wrong price',
    'دفع InstaPay': 'InstaPay Payment',
    'دفع فودافون كاش': 'Vodafone Cash Payment',
    'مشكلة حساب/دخول': 'Account/Login issue',
    'طلب استرجاع': 'Return request',
  };

  bool _isCheckingActiveTicket = true;

  @override
  void initState() {
    super.initState();
    _checkActiveTicket();
  }

  Future<void> _checkActiveTicket() async {
    try {
      debugPrint('🔍 Checking for active support tickets...');
      final result = await ref.read(supportTicketProvider.notifier).getTickets();
      final List<dynamic> tickets = result is List ? result : [];
      debugPrint('🎫 Found ${tickets.length} tickets total');
      
      Map<String, dynamic>? activeTicket;
      for (var t in tickets) {
        if (t is Map<String, dynamic>) {
          final status = t['status']?.toString().toUpperCase();
          // Redirect if there's any ticket that isn't closed
          if (status != 'CLOSED' && status != null) {
            activeTicket = t;
            break;
          }
        }
      }

      if (activeTicket != null) {
        debugPrint('✅ Active ticket found: ${activeTicket['id']}, redirecting to chat...');
        if (mounted) {
          context.pushReplacement('/chat/direct/${activeTicket['conversationId']}', extra: {'title': activeTicket['subject']});
          return;
        }
      } else {
        debugPrint('❌ No active tickets found.');
      }
    } catch (e) {
      debugPrint('⚠️ Error checking active tickets: $e');
    }
    if (mounted) {
      setState(() => _isCheckingActiveTicket = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingActiveTicket) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الدعم الفني' : 'Technical Support', style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr ? 'أهلاً بيك في دعم تطبيق اطلب 👋' : 'Welcome to Otlob Support 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isAr ? 'اختار مشكلتك وهنتابعها معاك لحظياً:' : 'Select your issue and we will follow up with you instantly:',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _selectedCategory == null
                  ? _buildCategoryList(isAr)
                  : _buildSubCategoryList(isAr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(bool isAr) {
    return ListView.builder(
      itemCount: _categoriesAr.keys.length,
      itemBuilder: (context, index) {
        final categoryAr = _categoriesAr.keys.elementAt(index);
        final categoryEn = _categoryEnMapping[categoryAr] ?? categoryAr;
        final title = isAr ? categoryAr : categoryEn;

        return _buildSupportTile(
          title: title,
          icon: _getCategoryIcon(categoryAr),
          onTap: () {
            if (_categoriesAr[categoryAr]!.isEmpty) {
              _createTicket(categoryAr, null);
            } else {
              setState(() {
                _selectedCategory = categoryAr;
              });
            }
          },
        );
      },
    );
  }

  Widget _buildSubCategoryList(bool isAr) {
    final subCategoriesAr = _categoriesAr[_selectedCategory!]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _selectedCategory = null),
          icon: const Icon(Icons.arrow_back_ios, size: 14),
          label: Text(isAr ? 'رجوع للقائمة الرئيسية' : 'Back to main menu'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: subCategoriesAr.length,
            itemBuilder: (context, index) {
              final subAr = subCategoriesAr[index];
              final subEn = _subCategoryEnMapping[subAr] ?? subAr;
              return _buildSupportTile(
                title: isAr ? subAr : subEn,
                icon: Icons.chevron_right,
                onTap: () => _createTicket(_selectedCategory!, subAr),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupportTile({required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }

  IconData _getCategoryIcon(String categoryAr) {
    switch (categoryAr) {
      case 'مشكلة في التوصيل': return LucideIcons.truck;
      case 'مشكلة في المطعم/الأكل': return LucideIcons.utensils;
      case 'مشكلة في الدفع': return LucideIcons.creditCard;
      case 'مشكلة في الحساب والتطبيق': return LucideIcons.user;
      case 'طلب استرجاع/شكوى عامة': return LucideIcons.messageSquare;
      default: return LucideIcons.helpCircle;
    }
  }

  Future<void> _createTicket(String categoryAr, String? subAr) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    // Map Arabic categories to Enum strings for Backend
    String categoryEnum;
    switch (categoryAr) {
      case 'مشكلة في التوصيل': categoryEnum = 'DELIVERY'; break;
      case 'مشكلة في المطعم/الأكل': categoryEnum = 'VENDOR'; break;
      case 'مشكلة في الدفع': categoryEnum = 'PAYMENT'; break;
      case 'مشكلة في الحساب والتطبيق': categoryEnum = 'ACCOUNT'; break;
      case 'طلب استرجاع/شكوى عامة': categoryEnum = 'RETURN_COMPLAINT'; break;
      default: categoryEnum = 'OTHER';
    }

    final subCategory = subAr != null ? (_subCategoryEnMapping[subAr] ?? subAr) : null;
    final subject = isAr ? (subAr ?? categoryAr) : (subCategory ?? _categoryEnMapping[categoryAr] ?? categoryAr);

    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final tickets = await ref.read(supportTicketProvider.notifier).getTickets();
      final activeTicket = tickets.firstWhere(
        (t) => t['status'] != 'CLOSED' && t['status'] != 'RESOLVED',
        orElse: () => null,
      );

      if (activeTicket != null) {
        if (mounted) {
          Navigator.pop(context); // Pop loading
          context.pushReplacement('/chat/direct/${activeTicket['conversationId']}', extra: {'title': activeTicket['subject']});
        }
        return;
      }

      final ticket = await ref.read(supportTicketProvider.notifier).createTicket(
        subject: subject,
        category: categoryEnum,
        subCategory: subAr ?? subCategory,
      );
      
      if (mounted) {
        Navigator.pop(context); // Pop loading
        context.pushReplacement('/chat/direct/${ticket['conversationId']}', extra: {'title': subject});
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
