import 'package:flutter/material.dart';

import '../../data/models/usuario_busqueda_model.dart';

class BusquedaUsuarioScreen extends StatefulWidget {
  final Future<UsuarioBusquedaModel?> Function(String query)? onBuscar;

  const BusquedaUsuarioScreen({super.key, this.onBuscar});

  @override
  State<BusquedaUsuarioScreen> createState() => _BusquedaUsuarioScreenState();
}

class _BusquedaUsuarioScreenState extends State<BusquedaUsuarioScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _cargando = false;
  String? _error;
  UsuarioBusquedaModel? _usuarioEncontrado;
  bool _busquedaRealizada = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _ejecutarBusqueda(String query) async {
    final limpio = query.trim();
    if (limpio.isEmpty) {
      setState(() {
        _error = 'Por favor ingresa un código institucional o correo.';
        _usuarioEncontrado = null;
        _busquedaRealizada = false;
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
      _busquedaRealizada = true;
      _usuarioEncontrado = null;
    });

    await Future.delayed(const Duration(milliseconds: 350));

    if (widget.onBuscar != null) {
      try {
        final res = await widget.onBuscar!(limpio);
        if (!mounted) return;
        setState(() {
          _usuarioEncontrado = res;
          _cargando = false;
          if (res == null) {
            _error = 'No se encontró ningún usuario con "$limpio".';
          }
        });
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _cargando = false;
          _error = 'Error de conexión al consultar el usuario.';
        });
        return;
      }
    }

    // Comportamiento local / fallback para pruebas y modo offline
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (limpio == '0000000000' || limpio.toLowerCase().contains('bloqueado')) {
        _usuarioEncontrado = UsuarioBusquedaModel(
          codigoInstitucional: limpio,
          nombreCompleto: 'Estudiante Sancionado Ejemplo',
          correoInstitucional: 'sancionado@virtual.upt.pe',
          escuela: 'Ingeniería Civil',
          estadoAcceso: 'BLOQUEADO',
        );
      } else if (limpio.length >= 4) {
        _usuarioEncontrado = UsuarioBusquedaModel(
          codigoInstitucional: limpio.contains('@') ? '2021072618' : limpio,
          nombreCompleto: 'Jefferson Rosas Chambilla',
          correoInstitucional: limpio.contains('@')
              ? limpio
              : '$limpio@virtual.upt.pe',
          escuela: 'Ingeniería de Sistemas',
          estadoAcceso: 'HABILITADO',
        );
      } else {
        _error = 'No se encontró ningún registro para "$limpio".';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Búsqueda Manual de Usuario',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado descriptivo
              const Text(
                'Control de Acceso Manual',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Permite verificar el estado de un usuario que no cuente con su teléfono o credencial QR en el punto de acceso.',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),

              // Campo de Búsqueda
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF38BDF8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Código o correo institucional...',
                          hintStyle: TextStyle(color: Color(0xFF64748B)),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _ejecutarBusqueda,
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _usuarioEncontrado = null;
                            _error = null;
                            _busquedaRealizada = false;
                          });
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Botón de Buscar
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _cargando
                    ? null
                    : () => _ejecutarBusqueda(_searchController.text),
                icon: _cargando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_search_outlined),
                label: const Text(
                  'Buscar Usuario',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),

              const SizedBox(height: 24),

              // Resultado de búsqueda
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7F1D1D).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF991B1B)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFF87171)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFECACA), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_usuarioEncontrado != null) ...[
                _TarjetaUsuarioResultado(usuario: _usuarioEncontrado!),
              ] else if (!_busquedaRealizada && _error == null) ...[
                // Estado inicial / sugerencias
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 48,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sin búsqueda activa',
                        style: TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Escribe el código institucional (ej. 2021072618) para consultar si el usuario tiene acceso permitido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaUsuarioResultado extends StatelessWidget {
  final UsuarioBusquedaModel usuario;

  const _TarjetaUsuarioResultado({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final habilitado = usuario.esHabilitado;
    final colorBadge = habilitado
        ? const Color(0xFF22C55E)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: habilitado ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorBadge.withValues(alpha: 0.15),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorBadge.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  color: colorBadge,
                  size: 30,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorBadge.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colorBadge),
                ),
                child: Text(
                  usuario.estadoAcceso,
                  style: TextStyle(
                    color: colorBadge,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            usuario.nombreCompleto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Código: ${usuario.codigoInstitucional}',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 24),
          _FilaDato(etiqueta: 'Correo:', valor: usuario.correoInstitucional),
          const SizedBox(height: 8),
          _FilaDato(etiqueta: 'Escuela:', valor: usuario.escuela),
          const SizedBox(height: 8),
          _FilaDato(etiqueta: 'Rol:', valor: usuario.roles.join(', ')),
          const SizedBox(height: 20),

          // Botón de confirmación de ingreso
          if (habilitado)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.check, size: 18),
                label: const Text(
                  'Registrar Entrada Manual',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF16A34A),
                      content: Text(
                        'Acceso manual autorizado para ${usuario.nombreCompleto}',
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _FilaDato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
