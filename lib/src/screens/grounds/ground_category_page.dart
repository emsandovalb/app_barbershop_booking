import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../../providers/ground_form_provider.dart';
import '../../data/categories.dart';
import '../../widgets/category_icon.dart';

class GroundCategoryPage extends StatefulWidget {
  const GroundCategoryPage({super.key});

  @override
  State<GroundCategoryPage> createState() => _GroundCategoryPageState();
}

class _GroundCategoryPageState extends State<GroundCategoryPage> {
  String category = 'Football';

  @override
  Widget build(BuildContext context) {
    final form = context.read<GroundFormProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ground category')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final cat in AppCategories.list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CategoryIcon(asset: cat.asset),
              title: Text(cat.title, style: const TextStyle(color: Colors.white)),
              trailing: Radio<String>(value: cat.title, groupValue: category, onChanged: (v) => setState(() => category = v!)),
              onTap: () => setState(() => category = cat.title),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            form.merge({'category': category});
            Navigator.of(context).pushNamed(AppRoutes.addPhotos);
          },
          child: const Text('Continue'),
        ),
      ),
    );
  }
}
