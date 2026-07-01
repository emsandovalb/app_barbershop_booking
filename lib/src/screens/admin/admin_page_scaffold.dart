import 'package:flutter/material.dart';

import '../../navigation/app_router.dart';

void navigateToAdminDashboard(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  navigator.pushNamedAndRemoveUntil(AppRoutes.adminDashboard, (route) => false);
}

PreferredSizeWidget buildAdminAppBar(
  BuildContext context, {
  required String title,
  String? subtitle,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    foregroundColor: Colors.white,
    titleSpacing: 0,
    leading: IconButton(
      tooltip: 'Volver',
      onPressed: () => navigateToAdminDashboard(context),
      icon: const Icon(Icons.arrow_back_rounded),
    ),
    title: subtitle == null
        ? Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: .68),
                ),
              ),
            ],
          ),
    actions: [
      IconButton(
        tooltip: 'Centro administrativo',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.adminDashboard),
        icon: const Icon(Icons.dashboard_outlined),
      ),
      if (actions != null) ...actions,
    ],
  );
}
