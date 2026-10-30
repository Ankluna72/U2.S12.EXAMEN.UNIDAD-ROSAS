import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/ubicacion_usuario.dart';
import '../../domain/services/servicio_ubicacion.dart';

enum EstadoUbicacion {
  inicial,
  cargando,
  obtenida,
  errorConEleccionManual,
}

/// ViewModel para la pantalla de mapa y ubicación.
/// NO importa ninguna biblioteca de GPS externa (recibe ServicioUbicacion desde fuera).
class UbicacionMapaViewModel extends ChangeNotifier {
  final ServicioUbicacion _servicioUbicacion;

  // Lugar de interés de la sede universitaria UPT
  static const String lugarInteresNombre = 'Puerta Principal - Campus Capanique';
  static const double lugarInteresLatitud = -18.0066;
  static const double lugarInteresLongitud = -70.2463;
  static const double lugarInteresRadioMetros = 150.0;

  EstadoUbicacion _estado = EstadoUbicacion.inicial;
  UbicacionUsuario? _ubicacion;
  String? _motivoError;
  StreamSubscription<UbicacionUsuario>? _streamSub;

  UbicacionMapaViewModel({required ServicioUbicacion servicioUbicacion})
      : _servicioUbicacion = servicioUbicacion;

  EstadoUbicacion get estado => _estado;
  UbicacionUsuario? get ubicacion => _ubicacion;
  String? get motivoError => _motivoError;
  bool get tieneUbicacion => _ubicacion != null;

  /// Distancia en metros al lugar de interés
  double? get distanciaAlLugarInteres {
    if (_ubicacion == null) return null;
    return _ubicacion!.distanciaHacia(lugarInteresLatitud, lugarInteresLongitud);
  }

  /// Evalúa si el usuario está dentro de la zona de 150 metros del lugar de interés
  bool get estaDentroDeZona {
    if (_ubicacion == null) return false;
    return _ubicacion!.estaDentroDeZona(
      lugarInteresLatitud,
      lugarInteresLongitud,
      lugarInteresRadioMetros,
    );
  }

  /// Mensaje requerido según Ítem 5 (Tarea 1):
  /// "Estás dentro de la zona de [lugar]" o "Estás fuera de la zona de [lugar]"
  String get mensajeZona {
    if (_ubicacion == null) return 'Ubicación no disponible';
    return estaDentroDeZona
        ? 'Estás dentro de la zona de $lugarInteresNombre'
        : 'Estás fuera de la zona de $lugarInteresNombre';
  }

  /// Solicita la ubicación al servicio desacoplado
  Future<void> solicitarUbicacion() async {
    _estado = EstadoUbicacion.cargando;
    _motivoError = null;
    notifyListeners();

    try {
      final resultado = await _servicioUbicacion.obtenerUbicacionActual();
      _ubicacion = resultado;
      _estado = EstadoUbicacion.obtenida;
      notifyListeners();

      _iniciarEscucha();
    } catch (e) {
      _motivoError = e.toString();
      _estado = EstadoUbicacion.errorConEleccionManual;
      notifyListeners();
    }
  }

  /// Permite al usuario elegir su ubicación tocando el mapa (Ítem 3 Tarea 3)
  void seleccionarUbicacionManual(double latitud, double longitud) {
    _ubicacion = UbicacionUsuario(
      latitud: latitud,
      longitud: longitud,
      precisionMetros: 10.0, // Precisión estimada para selección manual
      esManual: true,
    );
    _estado = EstadoUbicacion.obtenida;
    notifyListeners();
  }

  void _iniciarEscucha() {
    _streamSub?.cancel();
    _streamSub = _servicioUbicacion.escucharUbicacion().listen(
      (nuevaUbicacion) {
        _ubicacion = nuevaUbicacion;
        notifyListeners();
      },
      onError: (err) {
        _motivoError = err.toString();
        _estado = EstadoUbicacion.errorConEleccionManual;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _streamSub = null;
    // Apaga el GPS al salir de la pantalla
    _servicioUbicacion.detenerUbicacion();
    super.dispose();
  }
}
