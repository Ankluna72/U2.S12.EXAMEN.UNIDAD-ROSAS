import 'package:flutter/material.dart';
import '../../data/models/registro_historial_model.dart';

class HistorialValidacionesScreen extends StatefulWidget {
  const HistorialValidacionesScreen({super.key});

  @override
  State<HistorialValidacionesScreen> createState() =>
      _HistorialValidacionesScreenState();
}

class _HistorialValidacionesScreenState
    extends State<HistorialValidacionesScreen> {
  late List<RegistroHistorialModel> _registros;
  String _filtroResultado = 'TODOS'; // 'TODOS', 'AUTORIZADO', 'DENEGADO'
  final TextEditingController _searchController = TextEditingController();
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _registros = RegistroHistorialModel.obtenerRegistrosIniciales();
    _searchController.addListener(() {
      setState(() {
        _busqueda = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RegistroHistorialModel> get _registrosFiltrados {
    return _registros.where((reg) {
      if (_filtroResultado == 'AUTORIZADO' && !reg.esAutorizado) return false;
      if (_filtroResultado == 'DENEGADO' && reg.esAutorizado) return false;

      if (_busqueda.isNotEmpty) {
        final nombre = (reg.nombreCompleto ?? '').toLowerCase();
        final codigo = (reg.codigoInstitucional ?? '').toLowerCase();
        final motivo = reg.motivoLegible.toLowerCase();
        final obs = (reg.observacion ?? '').toLowerCase();

        return nombre.contains(_busqueda) ||
            codigo.contains(_busqueda) ||
            motivo.contains(_busqueda) ||
            obs.contains(_busqueda);
      }
      return true;
    }).toList();
  }

  int get _totalAutorizados =>
      _registros.where((r) => r.esAutorizado).length;
  int get _totalDenegados =>
      _registros.where((r) => !r.esAutorizado).length;

  void _recargarHistorial() {
    setState(() {
      _registros = RegistroHistorialModel.obtenerRegistrosIniciales();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Historial de validaciones actualizado'),
        backgroundColor: Color(0xFF0284C7),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }

  void _mostrarDetalles(RegistroHistorialModel reg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF475569),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    reg.esAutorizado
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: reg.esAutorizado
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFEF4444),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reg.esAutorizado
                              ? 'INGRESO PERMITIDO'
                              : 'INGRESO DENEGADO',
                          style: TextStyle(
                            color: reg.esAutorizado
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFF87171),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID Evento: ${reg.id}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF334155), height: 28),
              if (reg.esAutorizado && reg.nombreCompleto != null) ...[
                _buildInfoFila('Estudiante:', reg.nombreCompleto!),
                const SizedBox(height: 8),
                _buildInfoFila('Código UPT:', reg.codigoInstitucional ?? 'N/A'),
                const SizedBox(height: 8),
                _buildInfoFila('Escuela:', reg.escuela ?? 'Comunidad Universitaria'),
                const SizedBox(height: 8),
              ],
              _buildInfoFila('Motivo:', reg.motivoLegible),
              const SizedBox(height: 8),
              _buildInfoFila('Punto de Acceso:', reg.puntoAccesoNombre),
              const SizedBox(height: 8),
              _buildInfoFila('Hora de registro:', _formatearHora(reg.fechaHora)),
              if (reg.observacion != null) ...[
                const SizedBox(height: 8),
                _buildInfoFila('Observación:', reg.observacion!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar Detalle'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoFila(String label, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final registros = _registrosFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Historial de Accesos Recientes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar historial',
            onPressed: _recargarHistorial,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de punto de control activo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E293B).withValues(alpha: 0.6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Punto: Puerta Principal - Campus Capanique',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Resumen de Métricas del Turno
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTarjetaMetrica(
                    titulo: 'Total',
                    valor: '${_registros.length}',
                    color: const Color(0xFF38BDF8),
                    icono: Icons.qr_code_scanner,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTarjetaMetrica(
                    titulo: 'Permitidos',
                    valor: '$_totalAutorizados',
                    color: const Color(0xFF4ADE80),
                    icono: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTarjetaMetrica(
                    titulo: 'Denegados',
                    valor: '$_totalDenegados',
                    color: const Color(0xFFF87171),
                    icono: Icons.cancel_outlined,
                  ),
                ),
              ],
            ),
          ),

          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar por código, nombre o motivo...',
                hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
              ),
            ),
          ),

          // Filtros Rápidos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFiltroChip('TODOS', 'Todos (${_registros.length})'),
                const SizedBox(width: 8),
                _buildFiltroChip('AUTORIZADO', 'Permitidos ($_totalAutorizados)'),
                const SizedBox(width: 8),
                _buildFiltroChip('DENEGADO', 'Denegados ($_totalDenegados)'),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Lista de Registros
          Expanded(
            child: registros.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined, size: 48, color: Color(0xFF475569)),
                        SizedBox(height: 12),
                        Text(
                          'No se encontraron validaciones',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: registros.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final reg = registros[index];
                      return _buildTarjetaHistorial(reg);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaMetrica({
    required String titulo,
    required String valor,
    required Color color,
    required IconData icono,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                titulo,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String clave, String label) {
    final seleccionado = _filtroResultado == clave;
    return ChoiceChip(
      label: Text(label),
      selected: seleccionado,
      onSelected: (_) {
        setState(() {
          _filtroResultado = clave;
        });
      },
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : const Color(0xFF94A3B8),
        fontSize: 12,
        fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: const Color(0xFF0284C7),
      backgroundColor: const Color(0xFF1E293B),
      side: BorderSide(
        color: seleccionado ? const Color(0xFF0284C7) : const Color(0xFF334155),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _buildTarjetaHistorial(RegistroHistorialModel reg) {
    final esAutorizado = reg.esAutorizado;
    final color = esAutorizado
        ? const Color(0xFF16A34A)
        : const Color(0xFFEF4444);

    return InkWell(
      onTap: () => _mostrarDetalles(reg),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: esAutorizado
                ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                : const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                esAutorizado ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          esAutorizado ? 'PERMITIDO' : 'DENEGADO',
                          style: TextStyle(
                            color: esAutorizado
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFF87171),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        _formatearHora(reg.fechaHora),
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (esAutorizado && reg.nombreCompleto != null) ...[
                    Text(
                      reg.nombreCompleto!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Código: ${reg.codigoInstitucional ?? 'N/A'} · ${reg.escuela ?? ''}',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    Text(
                      reg.motivoLegible,
                      style: const TextStyle(
                        color: Color(0xFFFCA5A5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (reg.observacion != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        reg.observacion!,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
