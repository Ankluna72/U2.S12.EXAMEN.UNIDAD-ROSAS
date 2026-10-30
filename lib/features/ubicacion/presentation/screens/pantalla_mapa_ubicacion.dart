import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/servicio_ubicacion_geolocator.dart';
import '../viewmodels/ubicacion_mapa_view_model.dart';

class PantallaMapaUbicacion extends StatefulWidget {
  final UbicacionMapaViewModel? viewModel;

  const PantallaMapaUbicacion({super.key, this.viewModel});

  @override
  State<PantallaMapaUbicacion> createState() => _PantallaMapaUbicacionState();
}

class _PantallaMapaUbicacionState extends State<PantallaMapaUbicacion> {
  late final UbicacionMapaViewModel _vm;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _vm = widget.viewModel ??
        UbicacionMapaViewModel(
          servicioUbicacion: ServicioUbicacionGeolocator(),
        );

    _vm.addListener(_onViewModelUpdate);

    // Solicitar ubicación al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.solicitarUbicacion();
    });
  }

  void _onViewModelUpdate() {
    if (mounted) {
      setState(() {});
      if (_vm.ubicacion != null) {
        _mapController.move(
          LatLng(_vm.ubicacion!.latitud, _vm.ubicacion!.longitud),
          16.5,
        );
      }
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onViewModelUpdate);
    // Si el VM fue creado internamente, se llama a dispose (escribe "GPS detenido" en log)
    if (widget.viewModel == null) {
      _vm.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ubicacion = _vm.ubicacion;
    final centroDefecto = LatLng(
      UbicacionMapaViewModel.lugarInteresLatitud,
      UbicacionMapaViewModel.lugarInteresLongitud,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Mapa de Control y Sede UPT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Actualizar GPS',
            onPressed: () => _vm.solicitarUbicacion(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de estado y advertencias / motivo de error
          if (_vm.motivoError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFEF4444).withValues(alpha: 0.9),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_vm.motivoError}. Toca el mapa para fijar tu ubicación manualmente.',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Mapa OpenStreetMap interactivo
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: centroDefecto,
                    initialZoom: 16.0,
                    onTap: (tapPosition, point) {
                      _vm.seleccionarUbicacionManual(point.latitude, point.longitude);
                    },
                  ),
                  children: [
                    // Tarea 1 (Ítem 3): Capa base de OpenStreetMap
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'pe.upt.aplicacion_seguridad',
                    ),

                    // Círculos geográficos: Zona de interés y Precisión del usuario
                    CircleLayer(
                      circles: [
                        // Tarea 1 (Ítem 5): Zona de 150m del lugar de interés
                        CircleMarker(
                          point: centroDefecto,
                          radius: UbicacionMapaViewModel.lugarInteresRadioMetros,
                          useRadiusInMeter: true,
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
                          borderColor: const Color(0xFFD97706),
                          borderStrokeWidth: 2,
                        ),

                        // Tarea 2 (Ítem 3): Círculo de posición con radio = precisión en metros
                        if (ubicacion != null)
                          CircleMarker(
                            point: LatLng(ubicacion.latitud, ubicacion.longitud),
                            radius: ubicacion.precisionMetros,
                            useRadiusInMeter: true,
                            color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                            borderColor: const Color(0xFF0284C7),
                            borderStrokeWidth: 2,
                          ),
                      ],
                    ),

                    // Marcadores de puntos en el mapa
                    MarkerLayer(
                      markers: [
                        // Marcador de la Sede Universitaria
                        Marker(
                          point: centroDefecto,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_city_rounded,
                            color: Color(0xFFB45309),
                            size: 34,
                          ),
                        ),

                        // Marcador del Usuario
                        if (ubicacion != null)
                          Marker(
                            point: LatLng(ubicacion.latitud, ubicacion.longitud),
                            width: 36,
                            height: 36,
                            child: const Icon(
                              Icons.person_pin_circle_rounded,
                              color: Color(0xFF0284C7),
                              size: 36,
                            ),
                          ),
                      ],
                    ),

                    // Atribución obligatoria de OpenStreetMap visible
                    const SimpleAttributionWidget(
                      source: Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 10, color: Colors.black87),
                      ),
                    ),
                  ],
                ),

                if (_vm.estado == EstadoUbicacion.cargando)
                  Container(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                    ),
                  ),
              ],
            ),
          ),

          // Panel inferior de telemetría y geocerca
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(top: BorderSide(color: Color(0xFF334155))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tarea 3 (Ítem 1): Muestra latitud y longitud obtenidas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Latitud:',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          Text(
                            ubicacion != null
                                ? ubicacion.latitud.toStringAsFixed(6)
                                : 'Obteniendo...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Longitud:',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          Text(
                            ubicacion != null
                                ? ubicacion.longitud.toStringAsFixed(6)
                                : 'Obteniendo...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tarea 2 (Ítem 3): Texto "Precisión ± N m"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 16, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 8),
                      Text(
                        ubicacion != null
                            ? 'Precisión ± ${ubicacion.precisionMetros.toStringAsFixed(0)} m'
                            : 'Precisión no disponible',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (ubicacion?.esManual == true) ...[
                        const Spacer(),
                        const Text(
                          '(Ubicación en mapa)',
                          style: TextStyle(color: Color(0xFFFBBF24), fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Tarea 1 (Ítem 5): Texto «Estás dentro de la zona de <lugar>» o «Estás fuera de la zona de <lugar>»
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _vm.estaDentroDeZona
                        ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _vm.estaDentroDeZona
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _vm.estaDentroDeZona
                            ? Icons.check_circle_outline
                            : Icons.highlight_off_rounded,
                        color: _vm.estaDentroDeZona
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFF87171),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _vm.mensajeZona,
                          style: TextStyle(
                            color: _vm.estaDentroDeZona
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFFF87171),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
