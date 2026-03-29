import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';


import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final profileState = ref.watch(profileProvider);
    final settingsState = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, ref, s, profileState)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCard(context: context, children: [
                  _buildToggleTile(
                    icon: Icons.language_rounded,
                    title: s.language,
                    subtitle: profileState.isArabic ? 'العربية 🇪🇬' : 'English 🇬🇧',
                    value: settingsState.languageCode == 'ar',
                    onChanged: (val) {
                      ref.read(appSettingsProvider.notifier).changeLanguage(val ? 'ar' : 'en');
                      ref.read(profileProvider.notifier).toggleLanguage();
                    },
                  ),
                  const Divider(height: 1),
                  _buildToggleTile(
                    icon: Icons.notifications_active_rounded,
                    title: s.notifications,
                    subtitle: profileState.notificationsEnabled ? 'Enabled' : 'Disabled',
                    value: profileState.notificationsEnabled,
                    onChanged: (_) => ref.read(profileProvider.notifier).toggleNotifications(),
                  ),
                  const Divider(height: 1),
                  _buildToggleTile(
                    icon: Icons.dark_mode_rounded,
                    title: s.darkMode,
                    subtitle: settingsState.themeMode == ThemeMode.dark ? 'On' : 'Off',
                    value: settingsState.themeMode == ThemeMode.dark,
                    onChanged: (val) => ref.read(appSettingsProvider.notifier).changeTheme(val ? ThemeMode.dark : ThemeMode.light),
                  ),
                ]),
                const SizedBox(height: 12),
                _buildCard(context: context, children: [
                  _buildNavTile(
                    icon: Icons.edit_rounded,
                    title: s.editProfile,
                    onTap: () => _showEditProfile(context, ref, s, profileState),
                  ),
                  const Divider(height: 1),
                  _buildNavTile(
                    icon: Icons.location_on_rounded,
                    title: s.myAddresses,
                    onTap: () => context.push('/addresses'),
                  ),
                  const Divider(height: 1),
                  _buildNavTile(
                    icon: Icons.help_outline_rounded,
                    title: s.helpCenter,
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _buildNavTile(
                    icon: Icons.info_outline_rounded,
                    title: s.aboutApp,
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(s.logout),
                          content: const Text('Are you sure you want to log out?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        ref.read(authControllerProvider.notifier).logout();
                      }
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(s.logout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AppStrings s, ProfileState profileState) {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';
    final avatarUrl = profileState.avatar.isNotEmpty 
        ? (profileState.avatar.startsWith('http') ? profileState.avatar : '$baseUrl${profileState.avatar}') 
        : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 32, left: 20, right: 20),
      child: Column(children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                child: avatarUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatarUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) => const Icon(Icons.person, size: 50, color: AppColors.primary),
                        ),
                      )
                    : const Icon(Icons.person, size: 50, color: AppColors.primary),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => ref.read(profileProvider.notifier).pickAndUploadAvatar(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(profileState.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        const SizedBox(height: 4),
        Text(profileState.email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ]),
    );
  }

  Widget _buildCard({required BuildContext context, required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(children: children),
  );

  Widget _buildToggleTile({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 22)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      trailing: Switch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
    );
  }

  Widget _buildNavTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppColors.primary, size: 20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, AppStrings s, ProfileState profileState) {
    final nameCtrl = TextEditingController(text: profileState.name);
    final emailCtrl = TextEditingController(text: profileState.email);
    final phoneCtrl = TextEditingController(text: profileState.phone);

    PhoneNumber initialNumber = PhoneNumber(isoCode: 'EG');
    bool isPhoneValid = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.editProfile, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 12),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).inputDecorationTheme.enabledBorder?.borderSide.color ?? Colors.grey.shade300,
                    ),
                  ),
                  child: InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {
                      initialNumber = number;
                    },
                    onInputValidated: (bool value) {
                      setModalState(() {
                        isPhoneValid = value;
                      });
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      useEmoji: true,
                    ),
                    ignoreBlank: true,
                    autoValidateMode: AutovalidateMode.onUserInteraction,
                    selectorTextStyle: const TextStyle(color: Colors.black),
                    initialValue: PhoneNumber(phoneNumber: profileState.phone, isoCode: 'EG'),
                    textFieldController: phoneCtrl,
                    formatInput: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    inputDecoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: 'Enter phone number',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      prefixIcon: Icon(Icons.phone),
                      fillColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: !isPhoneValid ? null : () async {
                      await ref.read(profileProvider.notifier).updateProfileData(
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: initialNumber.phoneNumber ?? phoneCtrl.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }
      ),
    );
  }
}
