import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../navigation/app_router.dart';

class ComingSoonPage extends StatelessWidget {
  final String? title;
  const ComingSoonPage({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final t = title ?? 'Próximamente';
    return Scaffold(
      appBar: AppBar(title: Text(t)),
      body: Stack(
        children: [
          // Background illustration aligned to bottom-right
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: FractionallySizedBox(
                  heightFactor: 0.9,
                  child: Image.asset(
                    'assets/images/proximamente.png',
                    fit: BoxFit.fitHeight,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

          // Content overlay: pill flush to left with only-right radius and larger size
          Positioned(
            left: 0,
            top: 12,
            child: InkWell(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                }
              },
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.logout, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Próximamente',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
