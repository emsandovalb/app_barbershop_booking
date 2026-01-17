import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/localization_service.dart';
import '../../data/number_categories.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  static const double _priceSliderMin = 0;
  static const double _priceSliderMax = 300;

  double priceMin = _priceSliderMin;
  double priceMax = _priceSliderMax;
  String sort = 'rating';
  String? category;
  int? duration;
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  void _reset() {
    setState(() {
      priceMin = _priceSliderMin;
      priceMax = _priceSliderMax;
      sort = 'rating';
      category = null;
      duration = null;
    });
    nameCtrl.clear();
    addressCtrl.clear();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('filter_title', fallback: 'Filter'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(loc.t('filter_ground_name', fallback: 'Ground name')),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(hintText: loc.t('filter_name_hint', fallback: 'Search by name')),
            ),
            const SizedBox(height: 12),
            Text(loc.t('filter_address_label', fallback: 'Location / Address')),
            const SizedBox(height: 6),
            TextField(
              controller: addressCtrl,
              decoration: InputDecoration(hintText: loc.t('filter_address_hint', fallback: 'City, area or address')),
            ),
            const SizedBox(height: 16),
            Text(loc.t('filter_price_range', fallback: 'Price range')),
            RangeSlider(
              values: RangeValues(priceMin, priceMax),
              onChanged: (v) => setState(() {
                priceMin = v.start;
                priceMax = v.end;
              }),
              min: _priceSliderMin,
              max: _priceSliderMax,
            ),
            const SizedBox(height: 12),
            Text(loc.t('filter_category', fallback: 'Category')),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: NumberCategories.list.map((cat) {
                final selected = category == cat.label;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(cat.asset, width: 32, height: 32, fit: BoxFit.cover),
                      const SizedBox(width: 6),
                      Text(cat.label),
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => category = cat.label),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Text(loc.t('filter_duration', fallback: 'Duration per booking')),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                  label: Text(loc.t('filter_duration_one', fallback: '1 hour')),
                  selected: duration == 1,
                  onSelected: (_) => setState(() => duration = 1)),
              ChoiceChip(
                  label: Text(loc.t('filter_duration_two', fallback: '2 hours')),
                  selected: duration == 2,
                  onSelected: (_) => setState(() => duration = 2)),
              ChoiceChip(
                  label: Text(loc.t('filter_duration_any', fallback: 'Any')),
                  selected: duration == null,
                  onSelected: (_) => setState(() => duration = null)),
            ]),
            const SizedBox(height: 12),
            Text(loc.t('filter_sort_by', fallback: 'Sort by')),
            Wrap(spacing: 8, children: [
              ChoiceChip(
                  label: Text(loc.t('filter_sort_rating', fallback: 'Rating')),
                  selected: sort == 'rating',
                  onSelected: (_) => setState(() => sort = 'rating')),
              ChoiceChip(
                  label: Text(loc.t('filter_sort_price_asc', fallback: 'Price ↑')),
                  selected: sort == 'price_asc',
                  onSelected: (_) => setState(() => sort = 'price_asc')),
              ChoiceChip(
                  label: Text(loc.t('filter_sort_price_desc', fallback: 'Price ↓')),
                  selected: sort == 'price_desc',
                  onSelected: (_) => setState(() => sort = 'price_desc')),
            ]),
            const Spacer(),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: Text(loc.t('btn_reset', fallback: 'Reset')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'q': _composeQuery(),
                    'minPrice': priceMin,
                    'maxPrice': priceMax,
                    'sort': sort,
                    'category': category,
                    'duration': duration,
                  }),
                  child: Text(loc.t('btn_apply', fallback: 'Apply')),
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }

  String? _composeQuery() {
    final parts = [nameCtrl.text.trim(), addressCtrl.text.trim()]
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }
}
