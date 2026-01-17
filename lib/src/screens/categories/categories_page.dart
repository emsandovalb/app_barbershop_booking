import 'package:flutter/material.dart';
import '../../services/localization_service.dart';
import 'package:provider/provider.dart';
import '../../data/number_categories.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final cats = NumberCategories.list;
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('categories_title', fallback: 'Categories'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: cats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: .9,
          ),
          itemBuilder: (_, i) {
            final c = cats[i];
            return Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(c.asset, width: 80, height: 80, fit: BoxFit.cover),
                ),
                const SizedBox(height: 6),
                Text(c.label, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              ],
            );
          },
        ),
      ),
    );
  }
}
