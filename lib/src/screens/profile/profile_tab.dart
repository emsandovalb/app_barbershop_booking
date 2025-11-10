import 'package:flutter/material.dart';
import 'my_profile_page.dart';
// ignore: unused_import
import '../common/simple_page.dart';
import '../../navigation/app_router.dart';
import '../common/coming_soon_page.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = (auth.user?['name'] ?? 'Emmanuel Sandoval').toString();
    final email = (auth.user?['email'] ?? 'esandovalbarrantes@gmail.com')
        .toString();
    final isAdmin = (auth.user?['role']?.toString() ?? '') == 'admin';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF2A2A2A),
              child: Icon(Icons.person, color: Colors.white70),
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
          title: 'My profile',
          icon: Icons.person_outline,
          onTap: () => _go(context, const MyProfilePage()),
        ),
        _ProfileTile(
          title: 'Change password',
          icon: Icons.lock_outline,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.changePassword),
        ),
        _ProfileTile(
          title: 'Settings',
          icon: Icons.settings_outlined,
          onTap: () => _coming(context, 'Settings'),
        ),
        _ProfileTile(
          title: 'Privacy policy',
          icon: Icons.privacy_tip_outlined,
          onTap: () => _coming(context, 'Privacy policy'),
        ),
        _ProfileTile(
          title: 'Help',
          icon: Icons.help_outline,
          onTap: () => _coming(context, 'Help'),
        ),
        _ProfileTile(
          title: 'About us',
          icon: Icons.info_outline,
          onTap: () => _coming(context, 'About us'),
        ),
        _ProfileTile(
          title: 'Rate us',
          icon: Icons.star_outline,
          onTap: () => _coming(context, 'Rate us'),
        ),
        if (isAdmin)
          _ProfileTile(
            title: 'My grounds',
            icon: Icons.sports_soccer_outlined,
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.myGrounds);
            },
          ),
        const SizedBox(height: 12),
        _ProfileTile(
          title: 'Log out',
          icon: Icons.logout,
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1F1F1F),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Are you sure you want to log out?',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Log out'),
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
