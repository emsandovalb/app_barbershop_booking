import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ground_form_provider.dart';
import '../../navigation/app_router.dart';
import '../../services/localization_service.dart';

class AddPhotosPage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const AddPhotosPage({super.key, required this.initialData});

  @override
  State<AddPhotosPage> createState() => _AddPhotosPageState();
}

class _AddPhotosPageState extends State<AddPhotosPage> {
  bool loading = false;
  bool submitted = false;
  final List<XFile> images = [];
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('grounds_add_photos_title', fallback: 'Add photos'))),
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
                      child: Center(child: Text(loc.t('grounds_take_new_photo', fallback: 'Take New Photo'))),
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
                      child: Center(child: Text(loc.t('grounds_from_album', fallback: 'From Photo Album'))),
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
          onPressed: loading || submitted ? null : _confirm,
          child: Text(
            submitted
                ? loc.t('grounds_created_title', fallback: 'Service Created')
                : loading
                    ? loc.t('btn_saving', fallback: 'Saving...')
                    : loc.t('btn_confirm', fallback: 'Confirm'),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (submitted || loading) return;
    final loc = context.read<LocalizationService>();
    final auth = context.read<AuthProvider>();
    final form = context.read<GroundFormProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.t('grounds_admin_required', fallback: 'Please log in as admin'))));
      return;
    }
    // The payload still includes legacy sports field names until the backend generic contract is introduced.
    // Validate required fields from previous steps
    final data = widget.initialData.isNotEmpty ? widget.initialData : form.data;
    final name = data['name']?.toString().trim() ?? '';
    final address = data['address']?.toString().trim() ?? '';
    if (name.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.t('grounds_name_required', fallback: 'Please fill name and address first'))));
      return;
    }
    setState(() => loading = true);
    try {
      List<String> stored = [];
      if (images.isNotEmpty) {
        for (final x in images) {
          final encoded = await _compressAndEncodeImage(x);
          if (encoded != null) stored.add(encoded);
        }
      }
      final payload = {
        ...data,
        'duration_hours': data['duration_hours'] ?? '1',
        if (stored.isNotEmpty) 'images': stored,
      };
      await auth.api.createResource(payload);
      if (!mounted) return;
      setState(() => submitted = true);
      Navigator.of(context).pushNamed(AppRoutes.orderPlaced, arguments: {
        'title': loc.t('grounds_created_title', fallback: 'Service created'),
        'subtitle': loc.t(
          'grounds_created_subtitle',
          fallback: 'Your service has been created successfully and is now listed under My services.',
        ),
        'buttonText': loc.t('grounds_back_to_list', fallback: 'Back to My services'),
        'backRoute': AppRoutes.myGrounds,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.t('grounds_create_failed', fallback: 'Failed to create service')}: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

Future<String?> _compressAndEncodeImage(XFile x) async {
  final file = File(x.path);
  if (!await file.exists()) return null;
  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  const maxDimension = 1280;
  img.Image processed = decoded;
  if (decoded.width > maxDimension || decoded.height > maxDimension) {
    final scale = (decoded.width > decoded.height ? decoded.width : decoded.height) / maxDimension;
    final targetWidth = (decoded.width / scale).round();
    final targetHeight = (decoded.height / scale).round();
    processed = img.copyResize(decoded, width: targetWidth, height: targetHeight);
  }
  final compressedBytes = img.encodeJpg(processed, quality: 80);
  final encoded = base64Encode(compressedBytes);
  return 'data:image/jpeg;base64,$encoded';
}
