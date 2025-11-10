import 'package:flutter/material.dart';
import '../../data/categories.dart';
import '../../widgets/category_icon.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = AppCategories.list;
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: cats.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: .8),
          itemBuilder: (_, i) {
            final c = cats[i];
            return Column(
              children: [
                CategoryIcon(asset: c.asset, size: 56),
                const SizedBox(height: 6),
                Text(c.title, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center, maxLines: 2),
              ],
            );
          },
        ),
      ),
    );
  }
}

