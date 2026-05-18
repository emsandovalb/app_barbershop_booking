import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../../providers/ground_form_provider.dart';
import '../../services/localization_service.dart';
import '../../data/number_categories.dart';

class GroundCategoryPage extends StatefulWidget {
  const GroundCategoryPage({super.key});

  @override
  State<GroundCategoryPage> createState() => _GroundCategoryPageState();
}

class _GroundCategoryPageState extends State<GroundCategoryPage> {
  String category = NumberCategories.list.first.label;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final form = context.read<GroundFormProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('grounds_category_title', fallback: 'Service type'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final cat in NumberCategories.list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(cat.asset, width: 40, height: 40, fit: BoxFit.cover),
              ),
              title: Text(cat.label, style: const TextStyle(color: Colors.white)),
              trailing: Radio<String>(value: cat.label, groupValue: category, onChanged: (v) => setState(() => category = v!)),
              onTap: () => setState(() => category = cat.label),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            // Legacy category payload remains until the generic backend alias is available.
            form.merge({'category': category});
            Navigator.of(context).pushNamed(AppRoutes.addPhotos);
          },
          child: Text(loc.t('btn_continue', fallback: 'Continue')),
        ),
      ),
    );
  }
}
