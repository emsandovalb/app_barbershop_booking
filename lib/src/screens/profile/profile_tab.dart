import 'package:flutter/material.dart';
import 'my_profile_page.dart';
// ignore: unused_import
import '../common/simple_page.dart';
import '../../navigation/app_router.dart';
import '../common/coming_soon_page.dart';
import '../bookings/bookings_tab.dart';
import '../../config/app_config.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/colors.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localization = context.watch<LocalizationService>();
    final config = context.watch<AppConfig>();
    final name = (auth.user?['name'] ?? 'Emmanuel Sandoval').toString();
    final email = (auth.user?['email'] ?? 'esandovalbarrantes@gmail.com').toString();
    final rawAvatar = (auth.user?['avatar_url'] ?? auth.user?['avatar'])?.toString();
    final avatar = auth.api.resolveAssetUrl(rawAvatar);
    final isAdmin = (auth.user?['role']?.toString() ?? '') == 'admin';
    final currentLang = localization.locale.languageCode;
    final languageOptions = <Map<String, String>>[
      {'code': 'es', 'label': localization.t('language_es', fallback: 'Español')},
      {'code': 'en', 'label': localization.t('language_en', fallback: 'English')},
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          localization.t('profile_title', fallback: 'Profile'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF2A2A2A),
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty ? const Icon(Icons.person, color: Colors.white70) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ProfileTile(
          title: localization.t('profile_my_profile', fallback: 'My profile'),
          icon: Icons.person_outline,
          onTap: () => _go(context, const MyProfilePage()),
        ),
        _ProfileTile(
          title: localization.t('profile_change_password', fallback: 'Change password'),
          icon: Icons.lock_outline,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.changePassword),
        ),
        _ProfileTile(
          title: localization.t('profile_settings', fallback: 'Settings'),
          icon: Icons.settings_outlined,
          onTap: () => _coming(context, localization.t('profile_settings', fallback: 'Settings')),
        ),
        _ProfileTile(
          title: localization.t('profile_privacy', fallback: 'Privacy policy'),
          icon: Icons.privacy_tip_outlined,
          onTap: () => _coming(context, localization.t('profile_privacy', fallback: 'Privacy policy')),
        ),
        _ProfileTile(
          title: localization.t('profile_help', fallback: 'Help'),
          icon: Icons.help_outline,
          onTap: () => _coming(context, localization.t('profile_help', fallback: 'Help')),
        ),
        _ProfileTile(
          title: localization.t('profile_about', fallback: 'About us'),
          icon: Icons.info_outline,
          onTap: () => _coming(context, localization.t('profile_about', fallback: 'About us')),
        ),
        _ProfileTile(
          title: 'Perfil de Barbería Tres Amigos',
          icon: Icons.storefront_outlined,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.businessProfile),
        ),
        _ProfileTile(
          title: localization.t('profile_rate_us', fallback: 'Rate us'),
          icon: Icons.star_outline,
          onTap: () => _coming(context, localization.t('profile_rate_us', fallback: 'Rate us')),
        ),
        _ProfileTile(
          title: localization.t('nav_history', fallback: 'History'),
          icon: Icons.history,
          onTap: () => _go(context, const BookingsTab(initialIndex: 1)),
        ),
        if (config.features.showTeams)
          _ProfileTile(
            title: localization.t('profile_my_teams', fallback: 'My teams'),
            icon: Icons.groups_outlined,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.myTeams),
          ),
        if (isAdmin)
          _ProfileTile(
            title: localization.t('profile_my_grounds', fallback: 'My services'),
            icon: Icons.content_cut_outlined,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.myGrounds);
            },
          ),
        const SizedBox(height: 12),
        Text(
          localization.t('profile_language_label', fallback: 'Language'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF282828),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: languageOptions.map((lang) {
              final code = lang['code']!;
              return RadioListTile<String>(
                value: code,
                groupValue: currentLang,
                onChanged: localization.isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          context.read<LocalizationService>().changeLanguage(value);
                        }
                      },
                title: Text(
                  lang['label']!,
                  style: const TextStyle(color: Colors.white),
                ),
                activeColor: AppColors.primary,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        _ProfileTile(
          title: localization.t('profile_logout', fallback: 'Log out'),
          icon: Icons.logout,
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1F1F1F),
                title: Text(
                  localization.t('profile_logout', fallback: 'Log out'),
                  style: const TextStyle(color: Colors.white),
                ),
                content: Text(
                  localization.t('profile_logout_confirm', fallback: 'Are you sure you want to log out?'),
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(localization.t('btn_cancel', fallback: 'Cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(localization.t('profile_logout', fallback: 'Log out')),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
              }
            }
          },
        ),
      ],
    );
  }

  void _go(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _coming(BuildContext context, String title) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ComingSoonPage(title: title)));
  }
}

class _ProfileTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  const _ProfileTile({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }
}
