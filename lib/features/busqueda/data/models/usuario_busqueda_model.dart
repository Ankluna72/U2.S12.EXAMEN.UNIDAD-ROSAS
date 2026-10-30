class UsuarioBusquedaModel {
  final String codigoInstitucional;
  final String nombreCompleto;
  final String correoInstitucional;
  final String escuela;
  final String estadoAcceso; // 'HABILITADO', 'BLOQUEADO', 'INACTIVO'
  final List<String> roles;

  const UsuarioBusquedaModel({
    required this.codigoInstitucional,
    required this.nombreCompleto,
    required this.correoInstitucional,
    required this.escuela,
    required this.estadoAcceso,
    this.roles = const ['ESTUDIANTE'],
  });

  bool get esHabilitado => estadoAcceso.toUpperCase() == 'HABILITADO';

  factory UsuarioBusquedaModel.fromJson(Map<String, dynamic> json) {
    return UsuarioBusquedaModel(
      codigoInstitucional: json['codigo_institucional'] as String? ?? '',
      nombreCompleto: json['nombre_completo'] as String? ?? 'Usuario UPT',
      correoInstitucional: json['correo_institucional'] as String? ?? '',
      escuela: json['escuela'] as String? ?? 'Sin especificar',
      estadoAcceso: json['estado_acceso'] as String? ?? 'HABILITADO',
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['ESTUDIANTE'],
    );
  }

  Map<String, dynamic> toJson() => {
        'codigo_institucional': codigoInstitucional,
        'nombre_completo': nombreCompleto,
        'correo_institucional': correoInstitucional,
        'escuela': escuela,
        'estado_acceso': estadoAcceso,
        'roles': roles,
      };
}
