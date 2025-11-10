import 'package:flutter/material.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  double min = 0;
  double max = 200;
  String sort = 'rating';
  String? category;
  int? duration;
  final nameCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Ground name'),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(hintText: 'Search by name'),
            ),
            const SizedBox(height: 12),
            const Text('Location / Address'),
            const SizedBox(height: 6),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(hintText: 'City, area or address'),
            ),
            const SizedBox(height: 16),
            const Text('Price range'),
            RangeSlider(
              values: RangeValues(min, max),
              onChanged: (v) => setState(() { min = v.start; max = v.end; }),
              min: 0, max: 300,
            ),
            const SizedBox(height: 12),
            const Text('Category'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in const ['Football','Basketball','Tennis','Volleyball'])
                ChoiceChip(
                  label: Text(c),
                  selected: category == c,
                  onSelected: (_) => setState(() => category = c),
                ),
            ]),
            const SizedBox(height: 12),
            const Text('Duration per booking'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('1 hour'), selected: duration == 1, onSelected: (_) => setState(() => duration = 1)),
              ChoiceChip(label: const Text('2 hours'), selected: duration == 2, onSelected: (_) => setState(() => duration = 2)),
              ChoiceChip(label: const Text('Any'), selected: duration == null, onSelected: (_) => setState(() => duration = null)),
            ]),
            const SizedBox(height: 12),
            const Text('Sort by'),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('Rating'), selected: sort=='rating', onSelected: (_) => setState(() => sort='rating')),
              ChoiceChip(label: const Text('Price ↑'), selected: sort=='price_asc', onSelected: (_) => setState(() => sort='price_asc')),
              ChoiceChip(label: const Text('Price ↓'), selected: sort=='price_desc', onSelected: (_) => setState(() => sort='price_desc')),
            ]),
            const Spacer(),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'q': _composeQuery(),
                    'minPrice': min,
                    'maxPrice': max,
                    'sort': sort,
                    'category': category,
                    'duration': duration,
                  }),
                  child: const Text('Apply'),
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
