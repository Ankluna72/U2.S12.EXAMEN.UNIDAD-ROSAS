import 'dart:math' as math;

/// Entidad pura de dominio que representa la ubicación del usuario
/// sin depender de bibliotecas externas de GPS.
class UbicacionUsuario {
  final double latitud;
  final double longitud;
  final double precisionMetros;
  final bool esManual;
  final DateTime? fechaHora;

  const UbicacionUsuario({
    required this.latitud,
    required this.longitud,
    required this.precisionMetros,
    this.esManual = false,
    this.fechaHora,
  });

  /// Calcula la distancia geodésica en metros hacia otro punto (Fórmula de Haversine)
  double distanciaHacia(double otraLat, double otraLon) {
    const double radioTierraMetros = 6371000.0;
    final double dLat = (otraLat - latitud) * (math.pi / 180.0);
    final double dLon = (otraLon - longitud) * (math.pi / 180.0);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(latitud * (math.pi / 180.0)) *
            math.cos(otraLat * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radioTierraMetros * c;
  }

  /// Evalúa si la posición actual está dentro de un radio geográfico en metros
  bool estaDentroDeZona(double centroLat, double centroLon, double radioMetros) {
    return distanciaHacia(centroLat, centroLon) <= radioMetros;
  }

  @override
  String toString() {
    return 'UbicacionUsuario(lat: $latitud, lon: $longitud, precision: $precisionMetros m, manual: $esManual)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UbicacionUsuario &&
        other.latitud == latitud &&
        other.longitud == longitud &&
        other.precisionMetros == precisionMetros &&
        other.esManual == esManual;
  }

  @override
  int get hashCode => Object.hash(latitud, longitud, precisionMetros, esManual);
}
