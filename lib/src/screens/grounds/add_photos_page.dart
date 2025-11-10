import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../providers/auth_provider.dart';
import '../../providers/ground_form_provider.dart';
import '../../navigation/app_router.dart';

class AddPhotosPage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const AddPhotosPage({super.key, required this.initialData});

  @override
  State<AddPhotosPage> createState() => _AddPhotosPageState();
}

class _AddPhotosPageState extends State<AddPhotosPage> {
  bool loading = false;
  final List<XFile> images = [];
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add photos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                      if (x != null) setState(() => images.add(x));
                    },
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Take New Photo')),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final list = await picker.pickMultiImage(imageQuality: 85);
                      if (list.isNotEmpty) setState(() => images.addAll(list));
                    },
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('From Photo Album')),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (images.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final file = File(images[i].path);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(file, width: 120, height: 120, fit: BoxFit.cover),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: loading ? null : _confirm,
          child: Text(loading ? 'Saving...' : 'Confirm'),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final auth = context.read<AuthProvider>();
    final form = context.read<GroundFormProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in as admin')));
      return;
    }
    // Validate required fields from previous steps
    final data = widget.initialData.isNotEmpty ? widget.initialData : form.data;
    final name = data['name']?.toString().trim() ?? '';
    final address = data['address']?.toString().trim() ?? '';
    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill name and address first')));
      return;
    }
    setState(() => loading = true);
    try {
      List<String> stored = [];
      if (images.isNotEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        for (final x in images) {
          final dest = p.join(dir.path, 'ground_${DateTime.now().millisecondsSinceEpoch}_${p.basename(x.path)}');
          await File(x.path).copy(dest);
          stored.add(dest);
        }
      }
      final payload = {
        ...data,
        'duration_hours': data['duration_hours'] ?? '1',
        if (stored.isNotEmpty) 'images': stored,
      };
      await auth.api.createGround(payload);
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.orderPlaced, arguments: {
        'title': 'Ground Created',
        'subtitle': 'Your ground has been created successfully and is now listed under My grounds.',
        'buttonText': 'Back to My grounds',
        'backRoute': AppRoutes.myGrounds,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create ground: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
