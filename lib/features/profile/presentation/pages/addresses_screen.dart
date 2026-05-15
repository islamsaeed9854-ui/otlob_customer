import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../providers/profile_controller.dart';

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final s = AppStrings.of(context);
    final addresses = profileState.addresses;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myAddresses, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: addresses.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final address = addresses[index];
                return _buildAddressCard(context, ref, address);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddress(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(s.addNewAddress),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(AppStrings.of(context).noAddresses, style: TextStyle(fontSize: 18, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(AppStrings.of(context).addAddressSub, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, WidgetRef ref, Map<String, dynamic> address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(
              address['label']?.toString().toLowerCase() == 'home' ? Icons.home_rounded : Icons.work_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address['label'] ?? AppStrings.of(context).address, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(address['address'] ?? '', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade600, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              try {
                await ref.read(profileProvider.notifier).removeAddress(address['id']);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddAddress(BuildContext context, WidgetRef ref) {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)),
            const SizedBox(height: 24),
            TextField(controller: labelCtrl, decoration: InputDecoration(labelText: AppStrings.of(context).addressLabel, prefixIcon: const Icon(Icons.label))),
            const SizedBox(height: 16),
            TextField(controller: addressCtrl, decoration: InputDecoration(labelText: AppStrings.of(context).fullAddress, prefixIcon: const Icon(Icons.location_on))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (labelCtrl.text.isNotEmpty && addressCtrl.text.isNotEmpty) {
                    try {
                      await ref.read(profileProvider.notifier).addAddress({
                        'label': labelCtrl.text.trim(),
                        'address': addressCtrl.text.trim(),
                        'lat': 24.7136, // Default coordinates for Ryiadh as placeholders
                        'lng': 46.6753,
                        'isDefault': false,
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(AppStrings.of(context).addAddress),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
