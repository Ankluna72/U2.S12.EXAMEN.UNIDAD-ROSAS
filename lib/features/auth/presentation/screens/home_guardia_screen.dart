import 'package:flutter/material.dart';

import '../../../administracion/presentation/screens/gestion_usuarios_screen.dart';
import '../../../busqueda/presentation/screens/busqueda_usuario_screen.dart';
import '../../../historial/presentation/screens/historial_validaciones_screen.dart';
import '../../../ubicacion/presentation/screens/pantalla_mapa_ubicacion.dart';
import '../../domain/role_policy.dart';
import '../controllers/auth_controller.dart';

class HomeGuardiaScreen extends StatelessWidget {
  final AuthController authController;

  const HomeGuardiaScreen({super.key, required this.authController});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Cerrar sesión?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Se revocarán las credenciales locales y deberás ingresar nuevamente tus datos.',
          style: TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar',
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authController.cerrarSesion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = authController.usuario;
    final sesion = authController.sesion;
    final esAdmin = RolePolicy.esAdministrador(usuario?.roles ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield, color: Color(0xFF38BDF8), size: 24),
            const SizedBox(width: 10),
            const Text(
              'Ingreso UPT · Seguridad',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFF87171)),
            tooltip: 'Cerrar sesión',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarjeta de perfil del guardia
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              const Color(0xFF0284C7).withValues(alpha: 0.2),
                          child: const Icon(Icons.person,
                              color: Color(0xFF38BDF8), size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                usuario?.nombreCompleto.isNotEmpty == true
                                    ? usuario!.nombreCompleto
                                    : 'Personal de Seguridad',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                usuario?.codigoInstitucional ??
                                    'Código no disponible',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFF334155), height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Roles asignados:',
                          style:
                              TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                        Wrap(
                          spacing: 8,
                          children: (usuario?.roles ?? []).map((rol) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0369A1)
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: const Color(0xFF0284C7)),
                              ),
                              child: Text(
                                rol,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    if (usuario?.correoInstitucional.isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Correo: ${usuario!.correoInstitucional}',
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                    if (sesion != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sesión activa hasta: ${sesion.tokenAccesoExpiraEn.toLocal().toString().split('.').first}',
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Módulo de Validación de Accesos (US-09)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 50,
                        color: Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Puesto de Control de Accesos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Valida credenciales QR institucionales y visualiza el resultado de acceso en tiempo real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Botón para Búsqueda Manual de Usuario
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                          foregroundColor: const Color(0xFF38BDF8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.person_search, size: 20),
                        label: const Text(
                          'Búsqueda Manual de Usuario',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BusquedaUsuarioScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botón para Historial de Accesos Recientes
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF10B981)),
                          foregroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.history_rounded, size: 20),
                        label: const Text(
                          'Historial de Accesos Recientes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HistorialValidacionesScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botón para Mapa y Ubicación GPS de Sede (Examen U2)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          foregroundColor: const Color(0xFF38BDF8),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.map_outlined, size: 20),
                        label: const Text(
                          'Mapa y Ubicación GPS de Sede',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PantallaMapaUbicacion(),
                            ),
                          );
                        },
                      ),
                    ),
                    if (esAdmin) ...[
                      const SizedBox(height: 12),
                      // Botón para Gestión de Guardias de Seguridad (Exclusivo para ADMINISTRADOR)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFA855F7)),
                            foregroundColor: const Color(0xFFA855F7),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.shield_outlined, size: 20),
                          label: const Text(
                            'Gestión de Guardias de Seguridad',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const GestionUsuariosScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón explícito de Cerrar Sesión
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, color: Color(0xFFF87171)),
                label: const Text(
                  'Cerrar Sesión Activa',
                  style: TextStyle(
                      color: Color(0xFFF87171), fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade900),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
