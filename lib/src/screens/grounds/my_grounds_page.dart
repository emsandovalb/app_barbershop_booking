import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/court_image.dart';
import '../../services/localization_service.dart';

class MyGroundsPage extends StatefulWidget {
  const MyGroundsPage({super.key});

  @override
  State<MyGroundsPage> createState() => _MyGroundsPageState();
}

class _MyGroundsPageState extends State<MyGroundsPage> {
  Future<Map<String, dynamic>>? _future;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final loc = context.watch<LocalizationService>();
    final isAdmin = (auth.user?['role']?.toString() ?? '') == 'admin';
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: Text(loc.t('grounds_my_title', fallback: 'My grounds'))),
        body: Center(child: Text(loc.t('grounds_admin_only', fallback: 'Only administrators can access this section'))),
      );
    }
    _future ??= auth.api.getMyGrounds();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(loc.t('grounds_my_title', fallback: 'My grounds')),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data?['data'] as List?) ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      Center(child: Text(loc.t('grounds_empty', fallback: 'No grounds yet'))),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final c = items[i] as Map<String, dynamic>;
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF282828),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: CourtImage(
                                  images: c['images'],
                                  height: 72,
                                  width: 72,
                                  radius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['name']?.toString() ?? 'Ground',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${c['duration_hours'] ?? 1} ${loc.t('grounds_hour', fallback: 'Hour')}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.of(context).pushNamed(AppRoutes.addGround);
            if (mounted) _refresh();
          },
          child: Text(loc.t('btn_add', fallback: 'Add')),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _future = auth.api.getMyGrounds();
    });
    await _future;
  }
}
