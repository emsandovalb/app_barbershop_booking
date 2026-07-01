import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/barbershop_branding.dart';
import '../../widgets/court_image.dart';
import 'service_management_utils.dart';
import 'admin_page_scaffold.dart';

class ServiceFormPage extends StatefulWidget {
  final Map<String, dynamic>? service;

  const ServiceFormPage({super.key, this.service});

  @override
  State<ServiceFormPage> createState() => _ServiceFormPageState();
}

class _ServiceFormPageState extends State<ServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _imageCtrl;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service ?? const <String, dynamic>{};
    _nameCtrl = TextEditingController(text: serviceName(service));
    _descriptionCtrl = TextEditingController(
      text: service['description']?.toString() ?? '',
    );
    _priceCtrl = TextEditingController(
      text: servicePrice(service) > 0 ? servicePrice(service).round().toString() : '',
    );
    _durationCtrl = TextEditingController(
      text: serviceDurationMinutes(service).toString(),
    );
    _categoryCtrl = TextEditingController(text: serviceCategory(service));
    _imageCtrl = TextEditingController(text: serviceImage(service));
    _isActive = serviceIsActive(service);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _categoryCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service ?? const <String, dynamic>{};
    final previewImage = _imageCtrl.text.trim().isNotEmpty
        ? _imageCtrl.text.trim()
        : serviceImage(service);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: buildAdminAppBar(
        context,
        title: _isEditing ? 'Editar servicio' : 'Nuevo servicio',
      ),
      body: BarbershopCinematicPanel(
        backgroundAsset: 'assets/branding/barbershop_hero_bg.png',
        opacity: .18,
        blurSigma: 12,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                BarbershopPremiumCard(
                  radius: 28,
                  padding: const EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF140F0C).withValues(alpha: .96),
                  borderColor: AppColors.primary.withValues(alpha: .18),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          width: 92,
                          height: 92,
                          child: previewImage.isNotEmpty
                              ? CourtImage(
                                  images: previewImage,
                                  height: 92,
                                  width: 92,
                                  radius: BorderRadius.circular(18),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.content_cut_rounded,
                                    color: AppColors.primary,
                                    size: 30,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PremiumBadge(
                              label: 'GESTIÓN PREMIUM',
                              compact: true,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isEditing ? serviceName(service) : 'Nuevo servicio',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Configura precio, duración, imagen y estado del servicio.',
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
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: _isEditing ? 'Editar servicio' : 'Crear servicio',
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
                          final parsed = double.tryParse(value?.replaceAll(',', '.').trim() ?? '');
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
                _PremiumField(
                  controller: _categoryCtrl,
                  label: 'Categoría',
                ),
                const SizedBox(height: 12),
                _PremiumField(
                  controller: _imageCtrl,
                  label: 'Imagen URL/path',
                  hintText: 'Pega una URL, ruta local o asset',
                ),
                const SizedBox(height: 12),
                BarbershopPremiumCard(
                  radius: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  backgroundColor: const Color(0xFF130E0B).withValues(alpha: .95),
                  borderColor: AppColors.primary.withValues(alpha: .14),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeThumbColor: AppColors.primary,
                    title: const Text(
                      'Servicio activo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      _isActive ? 'Visible para reservas' : 'Oculto para reservas',
                      style: TextStyle(color: Colors.white.withValues(alpha: .68)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                  'La imagen se normaliza antes de enviarse al backend para mantener compatibilidad.',
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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _saving = true);
    final api = context.read<AuthProvider>().api;
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.').trim()) ?? 0;
    final durationMinutes = int.tryParse(_durationCtrl.text.trim()) ?? 60;
    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'price_per_hour': price,
      'price': price,
      'duration_minutes': durationMinutes,
      'duration_hours': math.max(1, (durationMinutes / 60).ceil()),
      'category': _categoryCtrl.text.trim(),
      'status': _isActive ? 'active' : 'inactive',
    };
    final image = _imageCtrl.text.trim();
    if (image.isNotEmpty) {
      payload['images'] = [image];
    }

    try {
      if (_isEditing) {
        final id = widget.service?['id'] as int?;
        if (id == null) {
          throw Exception('Servicio inválido');
        }
        await api.updateResource(id, payload);
      } else {
        await api.createResource(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar el servicio: $e'),
            backgroundColor: const Color(0xFF1A1512),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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
    this.hintText,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.prefixText,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
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
        prefixStyle: const TextStyle(color: AppColors.primary),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: .82)),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: .38)),
        filled: true,
        fillColor: const Color(0xFF120E0B).withValues(alpha: .96),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: .14)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: .14)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: .44)),
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
