class RegistroHistorialModel {
  final String id;
  final String resultado; // 'AUTORIZADO' o 'DENEGADO'
  final String motivo;
  final String? nombreCompleto;
  final String? codigoInstitucional;
  final String? escuela;
  final String puntoAccesoNombre;
  final String puntoAccesoCodigo;
  final DateTime fechaHora;
  final String? observacion;

  const RegistroHistorialModel({
    required this.id,
    required this.resultado,
    required this.motivo,
    this.nombreCompleto,
    this.codigoInstitucional,
    this.escuela,
    required this.puntoAccesoNombre,
    required this.puntoAccesoCodigo,
    required this.fechaHora,
    this.observacion,
  });

  bool get esAutorizado => resultado == 'AUTORIZADO';

  String get motivoLegible {
    switch (motivo) {
      case 'ACCESO_AUTORIZADO':
        return 'Acceso permitido';
      case 'CREDENCIAL_YA_UTILIZADA':
        return 'Credencial QR ya utilizada';
      case 'CREDENCIAL_EXPIRADA':
        return 'Tiempo de vigencia QR expirado';
      case 'HORARIO_NO_PERMITIDO':
        return 'Fuera de franja horaria permitida';
      case 'UBICACION_INVALIDA':
      case 'FUERA_DE_ZONA':
        return 'Generado fuera del perímetro del campus';
      case 'USUARIO_BLOQUEADO':
        return 'Usuario con restricción temporal';
      default:
        return motivo.replaceAll('_', ' ');
    }
  }

  factory RegistroHistorialModel.fromJson(Map<String, dynamic> json) {
    return RegistroHistorialModel(
      id: json['id'] as String? ?? '',
      resultado: json['resultado'] as String? ?? 'DENEGADO',
      motivo: json['motivo'] as String? ?? 'SIN_MOTIVO',
      nombreCompleto: json['nombre_completo'] as String?,
      codigoInstitucional: json['codigo_institucional'] as String?,
      escuela: json['escuela'] as String?,
      puntoAccesoNombre: json['punto_acceso_nombre'] as String? ??
          'Puerta Principal - Campus Capanique',
      puntoAccesoCodigo: json['punto_acceso_codigo'] as String? ??
          'PUERTA-PRINCIPAL',
      fechaHora: json['registrado_en'] != null
          ? DateTime.tryParse(json['registrado_en'] as String) ?? DateTime.now()
          : DateTime.now(),
      observacion: json['observacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resultado': resultado,
      'motivo': motivo,
      'nombre_completo': nombreCompleto,
      'codigo_institucional': codigoInstitucional,
      'escuela': escuela,
      'punto_acceso_nombre': puntoAccesoNombre,
      'punto_acceso_codigo': puntoAccesoCodigo,
      'registrado_en': fechaHora.toIso8601String(),
      'observacion': observacion,
    };
  }

  /// Lista inicial demostrativa con registros recientes del turno operativo
  static List<RegistroHistorialModel> obtenerRegistrosIniciales() {
    final ahora = DateTime.now();
    return [
      RegistroHistorialModel(
        id: 'VAL-001',
        resultado: 'AUTORIZADO',
        motivo: 'ACCESO_AUTORIZADO',
        nombreCompleto: 'María Elena Pérez Quispe',
        codigoInstitucional: '2023071234',
        escuela: 'Ingeniería de Sistemas',
        puntoAccesoNombre: 'Puerta Principal - Campus Capanique',
        puntoAccesoCodigo: 'PUERTA-PRINCIPAL',
        fechaHora: ahora.subtract(const Duration(minutes: 4)),
        observacion: 'Acceso regular con código QR',
      ),
      RegistroHistorialModel(
        id: 'VAL-002',
        resultado: 'DENEGADO',
        motivo: 'CREDENCIAL_YA_UTILIZADA',
        nombreCompleto: null,
        codigoInstitucional: null,
        escuela: null,
        puntoAccesoNombre: 'Puerta Principal - Campus Capanique',
        puntoAccesoCodigo: 'PUERTA-PRINCIPAL',
        fechaHora: ahora.subtract(const Duration(minutes: 12)),
        observacion: 'Intento de reutilización de QR',
      ),
      RegistroHistorialModel(
        id: 'VAL-003',
        resultado: 'AUTORIZADO',
        motivo: 'ACCESO_AUTORIZADO',
        nombreCompleto: 'Jean Carlo Huanca Mamani',
        codigoInstitucional: '2021069812',
        escuela: 'Ingeniería Civil',
        puntoAccesoNombre: 'Puerta Principal - Campus Capanique',
        puntoAccesoCodigo: 'PUERTA-PRINCIPAL',
        fechaHora: ahora.subtract(const Duration(minutes: 25)),
      ),
      RegistroHistorialModel(
        id: 'VAL-004',
        resultado: 'DENEGADO',
        motivo: 'CREDENCIAL_EXPIRADA',
        nombreCompleto: null,
        codigoInstitucional: null,
        escuela: null,
        puntoAccesoNombre: 'Puerta Principal - Campus Capanique',
        puntoAccesoCodigo: 'PUERTA-PRINCIPAL',
        fechaHora: ahora.subtract(const Duration(minutes: 38)),
        observacion: 'Código generado hace más de 60 segundos',
      ),
      RegistroHistorialModel(
        id: 'VAL-005',
        resultado: 'AUTORIZADO',
        motivo: 'ACCESO_AUTORIZADO',
        nombreCompleto: 'Luciana Andrea Flores Castro',
        codigoInstitucional: '2022080045',
        escuela: 'Derecho y Ciencias Políticas',
        puntoAccesoNombre: 'Puerta Principal - Campus Capanique',
        puntoAccesoCodigo: 'PUERTA-PRINCIPAL',
        fechaHora: ahora.subtract(const Duration(hours: 1, minutes: 5)),
      ),
      RegistroHistorialModel(
        id: 'VAL-006',
        resultado: 'DENEGADO',
        motivo: 'UBICACION_INVALIDA',
        nombreCompleto: null,
        codigoInstitucional: null,
        escuela: null,
        puntoAccesoNombre: 'Puerta Principal - Campus Capanique',
        puntoAccesoCodigo: 'PUERTA-PRINCIPAL',
        fechaHora: ahora.subtract(const Duration(hours: 1, minutes: 20)),
        observacion: 'Ubicación reportada fuera del campus',
      ),
      RegistroHistorialModel(
        id: 'VAL-007',
        resultado: 'AUTORIZADO',
        motivo: 'ACCESO_AUTORIZADO',
        nombreCompleto: 'Rodrigo Sebastián Ticona Ramos',
        codigoInstitucional: '2020054321',
        escuela: 'Arquitectura y Urbanismo',
        puntoAccesoNombre: 'Puerta Principal - Campus Capanique',
        puntoAccesoCodigo: 'PUERTA-PRINCIPAL',
        fechaHora: ahora.subtract(const Duration(hours: 1, minutes: 45)),
      ),
    ];
  }
}
