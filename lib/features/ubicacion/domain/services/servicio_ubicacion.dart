import '../entities/ubicacion_usuario.dart';

/// Excepciones de dominio para el servicio de ubicación
abstract class UbicacionException implements Exception {
  final String mensaje;
  const UbicacionException(this.mensaje);

  @override
  String toString() => mensaje;
}

class UbicacionGpsApagadoException extends UbicacionException {
  const UbicacionGpsApagadoException([super.mensaje = 'GPS apagado']);
}

class UbicacionPermisoDenegadoException extends UbicacionException {
  const UbicacionPermisoDenegadoException([super.mensaje = 'Permiso denegado']);
}

class UbicacionTiempoAgotadoException extends UbicacionException {
  const UbicacionTiempoAgotadoException([super.mensaje = 'Tiempo agotado']);
}

/// Contrato abstracto para desacoplar el GPS del resto de la app
abstract class ServicioUbicacion {
  Future<UbicacionUsuario> obtenerUbicacionActual();
  Stream<UbicacionUsuario> escucharUbicacion();
  void detenerUbicacion();
  bool get tieneEscuchaActiva;
}

