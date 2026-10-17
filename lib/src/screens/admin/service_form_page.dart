import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/barbershop_branding.dart';
import '../../widgets/court_image.dart';
import '../../widgets/keyboard_aware_list_view.dart';
import 'admin_page_scaffold.dart';
import 'service_management_utils.dart';

class ServiceFormPage extends StatefulWidget {
  final Map<String, dynamic>? service;
  final bool createMode;

  const ServiceFormPage({super.key, this.service, this.createMode = false});

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  bool _isActive = true;
  bool _saving = false;
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  bool get _isEditing => widget.service != null;
  bool get _isCreating => widget.createMode || widget.service == null;

  @override
  void initState() {
    super.initState();
    final service = widget.service ?? const <String, dynamic>{};
    _nameCtrl = TextEditingController(
      text: _isCreating ? '' : serviceName(service),
    );
    _descriptionCtrl = TextEditingController(
      text: service['description']?.toString() ?? '',
    );
    _priceCtrl = TextEditingController(
      text: servicePrice(service) > 0
          ? servicePrice(service).round().toString()
          : '',
    );
    _durationCtrl = TextEditingController(
      text: serviceDurationMinutes(service).toString(),
    );
    _isActive = serviceIsActive(service);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final service = widget.service ?? const <String, dynamic>{};
    final existingImage = serviceImage(service);
    final previewBytes = _pickedImageBytes;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: buildAdminAppBar(
        context,
        title: _isCreating ? 'Nuevo servicio' : 'Editar servicio',
      ),
      body: BarbershopCinematicPanel(
        backgroundAsset: '',
        opacity: .18,
        blurSigma: 12,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: KeyboardAwareListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                BarbershopPremiumCard(
                  radius: 28,
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(
                    0xFF140F0C,
                  ).withValues(alpha: .96),
                  borderColor: theme.primary.withValues(alpha: .18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              width: 92,
                              height: 92,
                              child: _buildPreview(
                                previewBytes: previewBytes,
                                existingImage: existingImage,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const PremiumBadge(
                                  label: 'GESTIÓN DE SERVICIOS',
                                  compact: true,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _isCreating
                                      ? 'Nuevo servicio'
                                      : serviceName(service),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Configura nombre, descripción, precio, duración, imagen y estado.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .72),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _saving ? null : _pickImage,
                            icon: const Icon(Icons.photo_library_rounded),
                            label: Text(
                              previewBytes == null
                                  ? 'Elegir imagen'
                                  : 'Cambiar imagen',
                            ),
                          ),
                          if (previewBytes != null)
                            TextButton(
                              onPressed: _saving
                                  ? null
                                  : () {
                                      setState(() {
                                        _pickedImageBytes = null;
                                        _pickedImageName = null;
                                      });
                                    },
                              child: const Text('Quitar imagen'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: _isCreating ? 'Crear servicio' : 'Editar servicio',
                  subtitle: 'Completa la información comercial del servicio.',
                ),
                const SizedBox(height: 12),
                _PremiumField(
                  controller: _nameCtrl,
                  label: 'Nombre del servicio',
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Ingresa el nombre del servicio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _PremiumField(
                  controller: _descriptionCtrl,
                  label: 'Descripción',
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PremiumField(
                        controller: _priceCtrl,
                        label: 'Precio',
                        keyboardType: TextInputType.number,
                        prefixText: '₡',
                        validator: (value) {
                          final parsed = double.tryParse(
                            value?.replaceAll(',', '.').trim() ?? '',
                          );
                          if (parsed == null || parsed <= 0) {
                            return 'Ingresa un precio válido';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PremiumField(
                        controller: _durationCtrl,
                        label: 'Duración en minutos',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Ingresa una duración válida';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BarbershopPremiumCard(
                  radius: 22,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  backgroundColor: const Color(
                    0xFF130E0B,
                  ).withValues(alpha: .95),
                  borderColor: theme.primary.withValues(alpha: .14),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeThumbColor: theme.primary,
                    title: const Text(
                      'Servicio activo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      _isActive
                          ? 'Visible para reservas'
                          : 'Oculto para reservas',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _saving
                        ? 'Guardando...'
                        : (_isEditing ? 'Guardar cambios' : 'Crear servicio'),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Formatos admitidos: JPG, PNG y WEBP. Recomendado: foto cuadrada o vertical de hasta 1600 px y compresión automática.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview({
    required Uint8List? previewBytes,
    required String existingImage,
  }) {
    if (previewBytes != null) {
      return Image.memory(previewBytes, fit: BoxFit.cover);
    }
    if (existingImage.isNotEmpty) {
      return CourtImage(
        images: existingImage,
        height: 92,
        width: 92,
        radius: BorderRadius.circular(18),
      );
    }
    final theme = context.watch<BrandTheme>();
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF120E0B)),
      child: Center(
        child: Icon(
          Icons.content_cut_rounded,
          color: theme.primary,
          size: 30,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        _showMessage('La imagen seleccionada no es válida.');
        return;
      }

      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _showMessage('Elige una imagen JPG, PNG o WEBP válida.');
        return;
      }

      if (bytes.length > 10 * 1024 * 1024) {
        _showMessage(
          'La foto es demasiado grande. Usa una imagen más pequeña.',
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = picked.name.isNotEmpty ? picked.name : 'service.jpg';
      });
    } catch (_) {
      _showMessage('No pudimos leer la imagen seleccionada.');
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);
    final api = context.read<AuthProvider>().api;
    final price =
        double.tryParse(_priceCtrl.text.replaceAll(',', '.').trim()) ?? 0;
    final durationMinutes = int.tryParse(_durationCtrl.text.trim()) ?? 60;
    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'price_per_hour': price,
      'price': price,
      'duration_minutes': durationMinutes,
      'status': _isActive ? 'active' : 'inactive',
    };

    try {
      if (_isEditing) {
        final id = widget.service?['id'] as int?;
        if (id == null) {
          throw Exception('Servicio inválido');
        }
        await api.updateResource(
          id,
          payload,
          imageBytes: _pickedImageBytes,
          imageName: _pickedImageName,
        );
      } else {
        await api.createResource(
          payload,
          imageBytes: _pickedImageBytes,
          imageName: _pickedImageName,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        _showMessage(
          'No pudimos guardar el servicio. Revisa la imagen o intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A1512),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .68),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _PremiumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final int maxLines;
  final TextInputType keyboardType;
  final String? prefixText;
  final String? Function(String?)? validator;

  const _PremiumField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.prefixText,
    this.validator,
  }) : hintText = null;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixText: prefixText,
        prefixStyle: TextStyle(color: theme.primary),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: .82)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: .38)),
        filled: true,
        fillColor: const Color(0xFF120E0B).withValues(alpha: .96),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.primary.withValues(alpha: .14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.primary.withValues(alpha: .14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.primary.withValues(alpha: .44),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
