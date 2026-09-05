import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text_field.dart';
import '../../domain/models/service_category_entity.dart';
import '../controllers/reservations_controller.dart';

class CreateReservationScreen extends ConsumerStatefulWidget {
  final int? initialServiceId;

  const CreateReservationScreen({
    super.key,
    this.initialServiceId,
  });

  @override
  ConsumerState<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState
    extends ConsumerState<CreateReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _detalleCtrl = TextEditingController();

  int? _selectedServiceId;
  String? _selectedSubService;
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedServiceId = widget.initialServiceId ?? 1;
    final cat = ServiceCategoryEntity.allServices
        .firstWhere((s) => s.id == _selectedServiceId, orElse: () => ServiceCategoryEntity.allServices.first);
    if (cat.subServicios.isNotEmpty) {
      _selectedSubService = cat.subServicios.first;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _detalleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedDateTime != null
          ? TimeOfDay.fromDateTime(_selectedDateTime!)
          : const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedServiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un tipo de servicio.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la fecha y hora de la cita.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final desc = [
      ?_selectedSubService,
      if (_detalleCtrl.text.trim().isNotEmpty) _detalleCtrl.text.trim(),
      if (_telefonoCtrl.text.trim().isNotEmpty) 'Tel: ${_telefonoCtrl.text.trim()}',
    ].join(' • ');

    final success = await ref.read(reservationsListProvider.notifier).create(
          idServicio: _selectedServiceId!,
          direccion: _direccionCtrl.text.trim(),
          descripcion: desc,
          fechaAgenda: _selectedDateTime!,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Cita agendada correctamente en ServiYa.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar la cita. Inténtalo nuevamente.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCat = ServiceCategoryEntity.allServices
        .firstWhere((s) => s.id == _selectedServiceId, orElse: () => ServiceCategoryEntity.allServices.first);

    String formattedDateTime = 'Seleccionar fecha y hora';
    if (_selectedDateTime != null) {
      final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDateTime!);
      final timeStr = DateFormat('hh:mm a').format(_selectedDateTime!);
      formattedDateTime = '$dateStr • $timeStr';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agendar Cita',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner superior
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('🗓️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Nueva Solicitud de Servicio',
                              style: TextStyle(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Completa los datos para agendar tu servicio con los mejores profesionales.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Campo Nombre
                CustomTextField(
                  label: 'Nombre Completo',
                  hint: 'Ej. Carlos Mendoza',
                  controller: _nombreCtrl,
                  prefixIcon: const Icon(Icons.person_outline,
                      color: AppColors.textMuted, size: 20),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Teléfono
                CustomTextField(
                  label: 'Teléfono de Contacto',
                  hint: 'Ej. 310 123 4567',
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.textMuted, size: 20),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresa un teléfono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Campo Dirección
                CustomTextField(
                  label: 'Dirección del Servicio',
                  hint: 'Ej. Calle 45 # 12-34, Apto 502',
                  controller: _direccionCtrl,
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: AppColors.textMuted, size: 20),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'La dirección es obligatoria';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selector de Fecha y Hora
                const Text(
                  'Fecha y Hora Programada',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _selectedDateTime != null
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: _selectedDateTime != null
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            formattedDateTime,
                            style: TextStyle(
                              color: _selectedDateTime != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: _selectedDateTime != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Selección de Categoría de Servicio
                const Text(
                  'Tipo de Servicio',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: ServiceCategoryEntity.allServices.length,
                  itemBuilder: (context, index) {
                    final s = ServiceCategoryEntity.allServices[index];
                    final isSelected = _selectedServiceId == s.id;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedServiceId = s.id;
                          _selectedSubService =
                              s.subServicios.isNotEmpty ? s.subServicios.first : null;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(s.icono, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.nombre,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Selector de Sub-Servicio
                if (currentCat.subServicios.isNotEmpty) ...[
                  Text(
                    'Opción específica (${currentCat.nombre})',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubService,
                        isExpanded: true,
                        dropdownColor: AppColors.card,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary),
                        items: currentCat.subServicios.map((op) {
                          return DropdownMenuItem(
                            value: op,
                            child: Text(
                              op,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSubService = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Campo Detalle Adicional
                CustomTextField(
                  label: 'Detalle o Instrucciones Adicionales (Opcional)',
                  hint: 'Ej. Llevar escalera o herramientas especiales...',
                  controller: _detalleCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 28),

                // Botón Guardar Cita
                CustomButton(
                  text: 'Guardar Cita →',
                  isLoading: _isLoading,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}