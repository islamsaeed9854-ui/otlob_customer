import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/app_settings_provider.dart';
import '../../../../core/services/token_service.dart';
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
                  _buildToggleTile(
                    icon: Icons.notifications_active_rounded,
                    title: s.notifications,
                    subtitle: profileState.notificationsEnabled ? 'Enabled' : 'Disabled',
                    value: profileState.notificationsEnabled,
                    onChanged: (_) => ref.read(profileProvider.notifier).toggleNotifications(),
                  ),
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
                  _buildNavTile(
                    icon: Icons.location_on_rounded,
                    title: s.myAddresses,
                    onTap: () => context.push('/addresses'),
                  ),
                  _buildNavTile(
                    icon: Icons.help_outline_rounded,
                    title: s.helpCenter,
                    onTap: () {},
                  ),
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
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: Text(s.logout, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      elevation: 0,
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
    final tokenAsync = ref.watch(accessTokenProvider);
    final token = tokenAsync.maybeWhen(data: (t) => t, orElse: () => null);

    String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    final avatarUrl = profileState.avatar.isNotEmpty 
        ? (profileState.avatar.startsWith('http') 
            ? profileState.avatar 
            : '$baseUrl${profileState.avatar.startsWith('/') ? '' : '/'}${profileState.avatar}') 
        : null;


    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryVariant.withOpacity(0.9),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.person_pin_circle_rounded,
              size: 150,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 40,
              left: 24,
              right: 24,
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Hero(
                        tag: 'profile_avatar',
                        child: CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.white24,
                          child: avatarUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    key: ValueKey(avatarUrl),
                                    imageUrl: avatarUrl,
                                    httpHeaders: token != null ? {'Authorization': 'Bearer $token'} : null,
                                    width: 108,
                                    height: 108,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    errorWidget: (context, url, error) => const Icon(Icons.person, size: 54, color: Colors.white),
                                  ),
                                )
                              : const Icon(Icons.person, size: 54, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => ref.read(profileProvider.notifier).pickAndUploadAvatar(),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 20, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  profileState.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profileState.email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required BuildContext context, required List<Widget> children}) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: children),
    ),
  );

  Widget _buildToggleTile({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w400),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNavTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      ),
      onTap: onTap,
    );
  }

  void _showEditProfile(BuildContext context, WidgetRef ref, AppStrings s, ProfileState profileState) {
    final nameCtrl = TextEditingController(text: profileState.name);
    final emailCtrl = TextEditingController(text: profileState.email);
    final phoneCtrl = TextEditingController(text: profileState.phone);


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
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(s.editProfile, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(profileProvider.notifier).updateProfileData(
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        }
      ),
    );
  }
}
