import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/white_label_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../bookings/bookings_tab.dart';
import 'my_profile_page.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final localization = context.watch<LocalizationService>();
    final config = context.watch<AppConfig>();
    final whiteLabel = context.watch<WhiteLabelConfig>();
    final name = (auth.user?['name'] ?? '').toString();
    final email = (auth.user?['email'] ?? '').toString();
    final rawAvatar = (auth.user?['avatar_url'] ?? auth.user?['avatar'])
        ?.toString();
    final avatar = auth.api.resolveAssetUrl(rawAvatar);
    // Business owners/admins are regular users with a managing membership;
    // the global 'admin' role alone misses them. Same check the admin
    // screens themselves enforce.
    final isAdmin = auth.canManageBusiness;
    final currentLang = localization.locale.languageCode;
    final languageOptions = <Map<String, String>>[
      {'code': 'es', 'label': localization.t('language_es')},
      {'code': 'en', 'label': localization.t('language_en')},
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          localization.t('profile_title'),
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
              child: avatar.isEmpty
                  ? const Icon(Icons.person, color: Colors.white70)
                  : null,
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
          title: localization.t('profile_my_profile'),
          icon: Icons.person_outline,
          onTap: () => _go(context, const MyProfilePage()),
        ),
        _ProfileTile(
          title: localization.t('profile_change_password'),
          icon: Icons.lock_outline,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.changePassword),
        ),
        if (whiteLabel.features.showBusinessProfile)
          _ProfileTile(
            title: whiteLabel.businessProfileLabel,
            icon: Icons.storefront_outlined,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.businessProfile),
          ),
        if (isAdmin && whiteLabel.features.showAdminDashboard)
          _ProfileTile(
            title: localization.t('admin_center'),
            icon: Icons.dashboard_outlined,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.adminDashboard),
          ),
        _ProfileTile(
          title: localization.t('nav_history'),
          icon: Icons.history,
          onTap: () => _go(context, const BookingsTab(initialIndex: 1)),
        ),
        if (config.features.showTeams)
          _ProfileTile(
            title: localization.t('profile_my_teams'),
            icon: Icons.groups_outlined,
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.myTeams),
          ),
        if (isAdmin)
          _ProfileTile(
            title: localization.t('profile_my_grounds'),
            icon: Icons.content_cut_outlined,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.myGrounds);
            },
          ),
        const SizedBox(height: 12),
        Text(
          localization.t('profile_language_label'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        // Material (not a decorated Container) so the radio tiles' ink
        // splashes stay visible, same as _ProfileTile below.
        Material(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: RadioGroup<String>(
            groupValue: currentLang,
            onChanged: (value) {
              if (value != null && !localization.isLoading) {
                context.read<LocalizationService>().changeLanguage(value);
              }
            },
            child: Column(
              children: languageOptions.map((lang) {
                final code = lang['code']!;
                return RadioListTile<String>(
                  value: code,
                  enabled: !localization.isLoading,
                  title: Text(
                    lang['label']!,
                    style: const TextStyle(color: Colors.white),
                  ),
                  activeColor: whiteLabel.primaryGold,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ProfileTile(
          title: localization.t('profile_logout'),
          icon: Icons.logout,
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1F1F1F),
                title: Text(
                  localization.t('profile_logout'),
                  style: const TextStyle(color: Colors.white),
                ),
                content: Text(
                  localization.t('profile_logout_confirm'),
                  style: const TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(localization.t('btn_cancel')),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(localization.t('profile_logout')),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
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
      // Material, not a decorated Container, wraps the ListTile: ListTile
      // paints its background/ink splashes on the nearest Material
      // ancestor, so a plain Container+BoxDecoration in between hides
      // them (Flutter's own debug assertion now catches this).
      child: Material(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
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
      ),
    );
  }
}
