class RolePolicy {
  static const String rolSeguridad = 'SEGURIDAD';
  static const String rolAdministrador = 'ADMINISTRADOR';

  static const List<String> rolesPermitidos = [
    rolSeguridad,
    rolAdministrador,
  ];

  /// Valida si el usuario posee al menos uno de los roles permitidos en la app.
  static bool tieneRolPermitido(List<String> roles) {
    final upperRoles = roles.map((r) => r.toUpperCase()).toSet();
    return upperRoles.any(rolesPermitidos.contains);
  }

  /// Verifica si el usuario es específicamente guardia de seguridad.
  static bool esSeguridad(List<String> roles) {
    return roles.map((r) => r.toUpperCase()).contains(rolSeguridad);
  }

  /// Verifica si el usuario es administrador.
  static bool esAdministrador(List<String> roles) {
    return roles.map((r) => r.toUpperCase()).contains(rolAdministrador);
  }
}
