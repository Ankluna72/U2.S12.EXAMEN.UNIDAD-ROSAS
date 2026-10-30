class UsuarioModel {
  final int id;
  final String codigoInstitucional;
  final String correoInstitucional;
  final String nombres;
  final String apellidos;
  final List<String> roles;

  const UsuarioModel({
    required this.id,
    required this.codigoInstitucional,
    required this.correoInstitucional,
    required this.nombres,
    required this.apellidos,
    required this.roles,
  });

  String get nombreCompleto => '$nombres $apellidos'.trim();

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as int,
      codigoInstitucional: json['codigo_institucional'] as String? ?? '',
      correoInstitucional: json['correo_institucional'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString().toUpperCase())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo_institucional': codigoInstitucional,
      'correo_institucional': correoInstitucional,
      'nombres': nombres,
      'apellidos': apellidos,
      'roles': roles,
    };
  }
}
