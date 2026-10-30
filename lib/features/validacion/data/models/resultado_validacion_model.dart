class IdentidadEstudianteModel {
  final String nombreCompleto;
  final String codigoInstitucional;
  final String? escuela;
  final String? estadoAcademico;
  final String? fotoUrl;
  final List<String> tiposUsuario;

  const IdentidadEstudianteModel({
    required this.nombreCompleto,
    required this.codigoInstitucional,
    this.escuela,
    this.estadoAcademico,
    this.fotoUrl,
    this.tiposUsuario = const ['ESTUDIANTE'],
  });

  factory IdentidadEstudianteModel.fromJson(Map<String, dynamic> json) {
    return IdentidadEstudianteModel(
      nombreCompleto: json['nombre_completo'] as String? ?? 'Estudiante UPT',
      codigoInstitucional: json['codigo_institucional'] as String? ?? '',
      escuela: json['escuela'] as String?,
      estadoAcademico: json['estado_academico'] as String?,
      fotoUrl: json['foto_url'] as String?,
      tiposUsuario: (json['tipo_usuario'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['ESTUDIANTE'],
    );
  }

  Map<String, dynamic> toJson() => {
        'nombre_completo': nombreCompleto,
        'codigo_institucional': codigoInstitucional,
        'escuela': escuela,
        'estado_academico': estadoAcademico,
        'foto_url': fotoUrl,
        'tipo_usuario': tiposUsuario,
      };
}

class ResultadoValidacionModel {
  final String resultado; // 'AUTORIZADO' | 'DENEGADO'
  final String motivo; // 'ACCESO_AUTORIZADO', 'CREDENCIAL_YA_UTILIZADA', etc.
  final String mensaje;
  final DateTime registradoEn;
  final String puntoAccesoCodigo;
  final String puntoAccesoNombre;
  final IdentidadEstudianteModel? identidad;

  const ResultadoValidacionModel({
    required this.resultado,
    required this.motivo,
    required this.mensaje,
    required this.registradoEn,
    required this.puntoAccesoCodigo,
    required this.puntoAccesoNombre,
    this.identidad,
  });

  bool get esAutorizado => resultado.toUpperCase() == 'AUTORIZADO';

  factory ResultadoValidacionModel.fromJson(Map<String, dynamic> json) {
    final datos = json['datos'] as Map<String, dynamic>? ?? json;
    final punto = datos['punto_acceso'] as Map<String, dynamic>? ?? {};
    final idMap = datos['identidad'] as Map<String, dynamic>?;

    return ResultadoValidacionModel(
      resultado: datos['resultado'] as String? ?? 'DENEGADO',
      motivo: datos['motivo'] as String? ?? 'SIN_MOTIVO',
      mensaje: datos['mensaje'] as String? ?? 'Validación procesada.',
      registradoEn: datos['registrado_en'] != null
          ? DateTime.tryParse(datos['registrado_en'] as String) ?? DateTime.now()
          : DateTime.now(),
      puntoAccesoCodigo: punto['codigo'] as String? ?? 'PUERTA-01',
      puntoAccesoNombre: punto['nombre'] as String? ?? 'Puerta Principal',
      identidad: idMap != null ? IdentidadEstudianteModel.fromJson(idMap) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'resultado': resultado,
        'motivo': motivo,
        'mensaje': mensaje,
        'registrado_en': registradoEn.toIso8601String(),
        'punto_acceso': {
          'codigo': puntoAccesoCodigo,
          'nombre': puntoAccesoNombre,
        },
        if (identidad != null) 'identidad': identidad!.toJson(),
      };
}
