import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String asset;
  final double size;
  const CategoryIcon({super.key, required this.asset, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFF2A2A2A),
      child: Image.asset(
        asset,
        width: size * .8,
        height: size * .8,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, color: Colors.white),
      ),
    );
  }
}
