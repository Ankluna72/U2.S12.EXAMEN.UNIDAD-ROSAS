import 'package:flutter/material.dart';

class UsuarioPersonalModel {
  final String id;
  final String nombres;
  final String apellidos;
  final String usuario;
  final String correo;
  final String rol; // 'GUARDIA'
  final String puertaAsignada;
  final String estado; // 'ACTIVO' o 'INACTIVO'

  const UsuarioPersonalModel({
    required this.id,
    required this.nombres,
    required this.apellidos,
    required this.usuario,
    required this.correo,
    this.rol = 'GUARDIA',
    required this.puertaAsignada,
    this.estado = 'ACTIVO',
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();
  bool get esActivo => estado == 'ACTIVO';

  UsuarioPersonalModel copyWith({
    String? id,
    String? nombres,
    String? apellidos,
    String? usuario,
    String? correo,
    String? rol,
    String? puertaAsignada,
    String? estado,
  }) {
    return UsuarioPersonalModel(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      usuario: usuario ?? this.usuario,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      puertaAsignada: puertaAsignada ?? this.puertaAsignada,
      estado: estado ?? this.estado,
    );
  }
}

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  final List<UsuarioPersonalModel> _usuarios = [
    const UsuarioPersonalModel(
      id: '1',
      nombres: 'Jefferson',
      apellidos: 'Rosas Chambilla',
      usuario: 'jr2021072618',
      correo: 'jr2021072618@virtual.upt.pe',
      rol: 'GUARDIA',
      puertaAsignada: 'Puerta Principal - Campus Capanique',
      estado: 'ACTIVO',
    ),
    const UsuarioPersonalModel(
      id: '2',
      nombres: 'Marcos',
      apellidos: 'Vargas Flores',
      usuario: 'guardia_pinto',
      correo: 'seguridad.pinto@virtual.upt.pe',
      rol: 'GUARDIA',
      puertaAsignada: 'Puerta 2 - Av. Pinto',
      estado: 'ACTIVO',
    ),
    const UsuarioPersonalModel(
      id: '3',
      nombres: 'Luis Alberto',
      apellidos: 'Medina Tapia',
      usuario: 'guardia_este',
      correo: 'lmedina@virtual.upt.pe',
      rol: 'GUARDIA',
      puertaAsignada: 'Puerta Peatonal Este',
      estado: 'ACTIVO',
    ),
  ];

  String _filtroEstado = 'TODOS'; // 'TODOS', 'ACTIVO', 'INACTIVO'

  void _abrirModalRegistro([UsuarioPersonalModel? usuarioAEditar]) {
    final formKey = GlobalKey<FormState>();
    final nombresCtrl =
        TextEditingController(text: usuarioAEditar?.nombres ?? '');
    final apellidosCtrl =
        TextEditingController(text: usuarioAEditar?.apellidos ?? '');
    final usuarioCtrl =
        TextEditingController(text: usuarioAEditar?.usuario ?? '');
    final correoCtrl = TextEditingController(text: usuarioAEditar?.correo ?? '');
    final claveCtrl = TextEditingController();
    String puertaSeleccionada = usuarioAEditar?.puertaAsignada ??
        'Puerta Principal - Campus Capanique';

    final puertasDisponibles = [
      'Puerta Principal - Campus Capanique',
      'Puerta 2 - Av. Pinto',
      'Puerta Peatonal Este',
      'Acceso Vehicular Norte',
      'Todas las puertas',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            usuarioAEditar == null
                                ? 'Registrar Nuevo Guardia'
                                : 'Editar Guardia',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFF94A3B8)),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Indicador de Rol fijo: Guardia de Seguridad
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 18, color: Color(0xFF38BDF8)),
                            SizedBox(width: 8),
                            Text(
                              'Rol Asignado: Guardia de Seguridad',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombres y Apellidos
                      Row(
                        children: [
                          Expanded(
                            child: _CampoTextoModal(
                              controller: nombresCtrl,
                              label: 'Nombres',
                              hint: 'Ej. Juan',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Obligatorio'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CampoTextoModal(
                              controller: apellidosCtrl,
                              label: 'Apellidos',
                              hint: 'Ej. Pérez',
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Obligatorio'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Usuario y Correo
                      _CampoTextoModal(
                        controller: usuarioCtrl,
                        label: 'Usuario / Código',
                        hint: 'Ej. 2024010203 o guardia_central',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Ingresa un usuario'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      _CampoTextoModal(
                        controller: correoCtrl,
                        label: 'Correo Institucional',
                        hint: 'usuario@virtual.upt.pe',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa un correo institucional';
                          }
                          if (!v.contains('@')) {
                            return 'Formato de correo no válido';
                          }
                          if (!v.endsWith('@virtual.upt.pe') &&
                              !v.endsWith('@upt.pe')) {
                            return 'Debe ser correo institucional (@virtual.upt.pe)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Contraseña inicial
                      if (usuarioAEditar == null) ...[
                        _CampoTextoModal(
                          controller: claveCtrl,
                          label: 'Contraseña Inicial',
                          hint: 'Mínimo 6 caracteres',
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa una contraseña';
                            }
                            if (v.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Puerta / Punto de Acceso Asignado
                      const Text(
                        'Punto de Control / Puerta Asignada:',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: puertaSeleccionada,
                            dropdownColor: const Color(0xFF1E293B),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                            isExpanded: true,
                            items: puertasDisponibles.map((p) {
                              return DropdownMenuItem<String>(
                                value: p,
                                child: Text(p),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => puertaSeleccionada = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botón Guardar
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;

                          final nuevoGuardia = UsuarioPersonalModel(
                            id: usuarioAEditar?.id ??
                                DateTime.now().millisecondsSinceEpoch.toString(),
                            nombres: nombresCtrl.text.trim(),
                            apellidos: apellidosCtrl.text.trim(),
                            usuario: usuarioCtrl.text.trim(),
                            correo: correoCtrl.text.trim(),
                            rol: 'GUARDIA',
                            puertaAsignada: puertaSeleccionada,
                            estado: usuarioAEditar?.estado ?? 'ACTIVO',
                          );

                          setState(() {
                            if (usuarioAEditar != null) {
                              final idx = _usuarios.indexWhere(
                                  (u) => u.id == usuarioAEditar.id);
                              if (idx != -1) _usuarios[idx] = nuevoGuardia;
                            } else {
                              _usuarios.insert(0, nuevoGuardia);
                            }
                          });

                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF16A34A),
                              content: Text(
                                'Guardia ${nuevoGuardia.nombreCompleto} registrado correctamente.',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          usuarioAEditar == null
                              ? 'Crear y Habilitar Guardia'
                              : 'Guardar Cambios',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _toggleEstado(UsuarioPersonalModel u) {
    final nuevoEstado = u.esActivo ? 'INACTIVO' : 'ACTIVO';
    final idx = _usuarios.indexWhere((user) => user.id == u.id);
    if (idx != -1) {
      setState(() {
        _usuarios[idx] = u.copyWith(estado: nuevoEstado);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              nuevoEstado == 'ACTIVO' ? const Color(0xFF16A34A) : Colors.orange,
          content: Text(
            'Guardia ${u.nombreCompleto} ahora está $nuevoEstado',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuariosFiltrados = _usuarios.where((u) {
      if (_filtroEstado == 'TODOS') return true;
      return u.estado == _filtroEstado;
    }).toList();

    final totalActivos = _usuarios.where((u) => u.esActivo).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Gestión de Guardias de Seguridad',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        icon: const Icon(Icons.shield_outlined, color: Colors.white),
        label: const Text(
          'Nuevo Guardia',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _abrirModalRegistro(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Resumen y Filtros
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Text(
                    'Filtrar:',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  _ChipFiltro(
                    label: 'Todos (${_usuarios.length})',
                    seleccionado: _filtroEstado == 'TODOS',
                    onTap: () => setState(() => _filtroEstado = 'TODOS'),
                  ),
                  const SizedBox(width: 8),
                  _ChipFiltro(
                    label: 'Activos ($totalActivos)',
                    seleccionado: _filtroEstado == 'ACTIVO',
                    onTap: () => setState(() => _filtroEstado = 'ACTIVO'),
                  ),
                  const SizedBox(width: 8),
                  _ChipFiltro(
                    label: 'Inactivos (${_usuarios.length - totalActivos})',
                    seleccionado: _filtroEstado == 'INACTIVO',
                    onTap: () => setState(() => _filtroEstado = 'INACTIVO'),
                  ),
                ],
              ),
            ),

            // Lista de guardias
            Expanded(
              child: usuariosFiltrados.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 48, color: Color(0xFF475569)),
                          SizedBox(height: 12),
                          Text(
                            'No se encontraron guardias registrados',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: usuariosFiltrados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final u = usuariosFiltrados[index];
                        final colorRol = const Color(0xFF38BDF8);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: u.esActivo
                                  ? const Color(0xFF334155)
                                  : Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: colorRol.withValues(alpha: 0.15),
                                child: const Icon(
                                  Icons.shield,
                                  color: Color(0xFF38BDF8),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            u.nombreCompleto,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => _toggleEstado(u),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: u.esActivo
                                                  ? const Color(0xFF16A34A)
                                                      .withValues(alpha: 0.2)
                                                  : Colors.orange
                                                      .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: u.esActivo
                                                    ? const Color(0xFF16A34A)
                                                    : Colors.orange,
                                              ),
                                            ),
                                            child: Text(
                                              u.estado,
                                              style: TextStyle(
                                                color: u.esActivo
                                                    ? const Color(0xFF4ADE80)
                                                    : Colors.orange,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Usuario: ${u.usuario} · ${u.correo}',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.door_front_door_outlined,
                                            size: 14,
                                            color: Color(0xFF64748B)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            u.puertaAsignada,
                                            style: const TextStyle(
                                              color: Color(0xFFCBD5E1),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 18,
                                              color: Color(0xFF94A3B8)),
                                          onPressed: () =>
                                              _abrirModalRegistro(u),
                                          tooltip: 'Editar guardia',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.label,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado
              ? const Color(0xFF0284C7)
              : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF0284C7)
                : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight:
                seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _CampoTextoModal extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _CampoTextoModal({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF0F172A),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF334155)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0284C7)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
