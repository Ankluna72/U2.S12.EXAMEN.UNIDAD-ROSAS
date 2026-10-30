import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/entities/ubicacion_usuario.dart';
import '../../domain/services/servicio_ubicacion.dart';

/// ÚNICA clase de la capa de datos que utiliza la biblioteca de GPS (Geolocator).
class ServicioUbicacionGeolocator implements ServicioUbicacion {
  StreamSubscription<Position>? _subscription;
  DateTime? _ultimaLectura;

  @override
  bool get tieneEscuchaActiva => _subscription != null;

  @override
  Future<UbicacionUsuario> obtenerUbicacionActual() async {
    // 1. Verificación de servicio GPS habilitado
    final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      throw const UbicacionGpsApagadoException('GPS apagado');
    }

    // 2. Verificación y solicitud de permisos
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw const UbicacionPermisoDenegadoException('Permiso denegado');
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      throw const UbicacionPermisoDenegadoException('Permiso denegado permanentemente');
    }

    try {
      // Tarea 1 (Ítem 2): Precisión media (NO máxima)
      // Primero revisamos si hay una posición conocida en el emulador
      Position? position = await Geolocator.getLastKnownPosition();

      // Tarea 3 (Ítem 2): Timeout estricto de 10 segundos
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Tiempo agotado'),
      );

      return UbicacionUsuario(
        latitud: position.latitude,
        longitud: position.longitude,
        precisionMetros: position.accuracy > 0 ? position.accuracy : 35.0,
      );
    } on TimeoutException {
      final fallback = await Geolocator.getLastKnownPosition();
      if (fallback != null) {
        return UbicacionUsuario(
          latitud: fallback.latitude,
          longitud: fallback.longitude,
          precisionMetros: fallback.accuracy > 0 ? fallback.accuracy : 35.0,
        );
      }
      throw const UbicacionTiempoAgotadoException('Tiempo agotado');
    }
  }

  @override
  Stream<UbicacionUsuario> escucharUbicacion() {
    final streamController = StreamController<UbicacionUsuario>.broadcast();

    // Tarea 2 (Ítem 2): Precisión media y filtro de 50 metros
    const settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50,
    );

    _subscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        final ahora = DateTime.now();
        // Tarea 2 (Ítem 2): Actualización como máximo cada 30 segundos
        if (_ultimaLectura == null ||
            ahora.difference(_ultimaLectura!).inSeconds >= 30) {
          _ultimaLectura = ahora;
          streamController.add(
            UbicacionUsuario(
              latitud: pos.latitude,
              longitud: pos.longitude,
              precisionMetros: pos.accuracy,
            ),
          );
        }
      },
      onError: (err) {
        streamController.addError(err);
      },
    );

    return streamController.stream;
  }

  @override
  void detenerUbicacion() {
    _subscription?.cancel();
    _subscription = null;
    _ultimaLectura = null;

    // Tarea 4 (Ítem 2): Al salir de la pantalla escribe "GPS detenido" en el log
    debugPrint('GPS detenido');
  }
}

